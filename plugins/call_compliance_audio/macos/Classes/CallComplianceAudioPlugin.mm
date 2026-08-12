#import "CallComplianceAudioPlugin.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import <flutter_webrtc/AudioManager.h>
#import <flutter_webrtc/AudioProcessingAdapter.h>
#import <os/lock.h>

typedef NS_ENUM(NSInteger, AlmaComplianceAudioRole) {
  AlmaComplianceAudioRoleLocal,
  AlmaComplianceAudioRoleRemote,
};

@class AlmaComplianceSession;

@interface AlmaComplianceProcessor : NSObject <ExternalAudioProcessingDelegate>
- (instancetype)initWithSession:(AlmaComplianceSession *)session
                            role:(AlmaComplianceAudioRole)role;
@end

@interface AlmaComplianceSession : NSObject
- (void)armGate;
- (void)beginRecording:(BOOL)record
       announcementPath:(NSString *)announcementPath
                  volume:(double)volume
              completion:(FlutterResult)completion;
- (void)stopWithCompletion:(FlutterResult)completion;
- (void)cancel;
- (void)processBuffer:(RTC_OBJC_TYPE(RTCAudioBuffer) *)buffer
                  role:(AlmaComplianceAudioRole)role;
@end

@implementation AlmaComplianceProcessor {
  __weak AlmaComplianceSession *_session;
  AlmaComplianceAudioRole _role;
}

- (instancetype)initWithSession:(AlmaComplianceSession *)session
                            role:(AlmaComplianceAudioRole)role {
  self = [super init];
  if (self) {
    _session = session;
    _role = role;
  }
  return self;
}

- (void)audioProcessingInitializeWithSampleRate:(size_t)sampleRateHz
                                        channels:(size_t)channels {
}

- (void)audioProcessingProcess:(RTC_OBJC_TYPE(RTCAudioBuffer) *)audioBuffer {
  [_session processBuffer:audioBuffer role:_role];
}

- (void)audioProcessingRelease {
}

@end

@implementation AlmaComplianceSession {
  os_unfair_lock _lock;
  BOOL _gateArmed;
  BOOL _recording;
  BOOL _stopping;
  double _sessionStartedAt;
  double _announcementVolume;
  NSData *_announcementSource;
  double _announcementSourceRate;
  NSData *_announcementTarget;
  double _announcementTargetRate;
  NSUInteger _announcementPosition;

  dispatch_queue_t _writerQueue;
  AVAudioFile *_localFile;
  AVAudioFile *_remoteFile;
  NSString *_localPath;
  NSString *_remotePath;
  NSString *_outputPath;
  double _localFirstOffset;
  double _remoteFirstOffset;
  BOOL _hasLocalOffset;
  BOOL _hasRemoteOffset;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _lock = OS_UNFAIR_LOCK_INIT;
    _writerQueue = dispatch_queue_create("com.almacrm.call-compliance.writer", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)armGate {
  os_unfair_lock_lock(&_lock);
  _gateArmed = YES;
  os_unfair_lock_unlock(&_lock);
}

- (BOOL)loadAnnouncement:(NSString *)path error:(NSError **)error {
  if (path.length == 0) {
    _announcementSource = nil;
    _announcementSourceRate = 0;
    return YES;
  }

  AVAudioFile *file = [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath:path] error:error];
  if (!file) return NO;
  AVAudioFormat *format = file.processingFormat;
  AVAudioFrameCount capacity = (AVAudioFrameCount)MAX((AVAudioFramePosition)1, file.length);
  AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:capacity];
  if (![file readIntoBuffer:buffer error:error]) return NO;

  AVAudioPCMBuffer *floatBuffer = buffer;
  if (!buffer.floatChannelData) {
    AVAudioFormat *floatFormat = [[AVAudioFormat alloc]
        initWithCommonFormat:AVAudioPCMFormatFloat32
                  sampleRate:format.sampleRate
                    channels:format.channelCount
                 interleaved:NO];
    AVAudioConverter *converter = [[AVAudioConverter alloc] initFromFormat:format toFormat:floatFormat];
    floatBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:floatFormat
                                               frameCapacity:buffer.frameCapacity];
    __block BOOL supplied = NO;
    AVAudioConverterInputBlock input = ^AVAudioBuffer * _Nullable(
        AVAudioPacketCount packetCount, AVAudioConverterInputStatus *outStatus) {
      if (supplied) {
        *outStatus = AVAudioConverterInputStatus_EndOfStream;
        return nil;
      }
      supplied = YES;
      *outStatus = AVAudioConverterInputStatus_HaveData;
      return buffer;
    };
    if ([converter convertToBuffer:floatBuffer error:error withInputFromBlock:input] ==
        AVAudioConverterOutputStatus_Error) {
      return NO;
    }
  }

  NSUInteger frames = floatBuffer.frameLength;
  if (frames == 0) {
    if (error) {
      *error = [NSError errorWithDomain:@"com.almacrm.call-compliance"
                                   code:2
                               userInfo:@{NSLocalizedDescriptionKey: @"Announcement audio contains no samples"}];
    }
    return NO;
  }
  NSUInteger channels = MAX((NSUInteger)1, floatBuffer.format.channelCount);
  NSMutableData *mono = [NSMutableData dataWithLength:frames * sizeof(float)];
  float *destination = (float *)mono.mutableBytes;
  for (NSUInteger frame = 0; frame < frames; frame++) {
    double sample = 0;
    for (NSUInteger channel = 0; channel < channels; channel++) {
      sample += floatBuffer.floatChannelData[channel][frame];
    }
    destination[frame] = (float)(sample / channels);
  }
  _announcementSource = mono;
  _announcementSourceRate = floatBuffer.format.sampleRate;
  return YES;
}

- (void)prepareAnnouncementForRateLocked:(double)targetRate {
  if (!_announcementSource || _announcementSourceRate <= 0 || targetRate <= 0) return;
  if (_announcementTarget && fabs(_announcementTargetRate - targetRate) < 1) return;

  const float *source = (const float *)_announcementSource.bytes;
  NSUInteger sourceCount = _announcementSource.length / sizeof(float);
  NSUInteger targetCount = (NSUInteger)ceil(sourceCount * targetRate / _announcementSourceRate);
  NSMutableData *target = [NSMutableData dataWithLength:targetCount * sizeof(float)];
  float *output = (float *)target.mutableBytes;
  for (NSUInteger i = 0; i < targetCount; i++) {
    double position = i * _announcementSourceRate / targetRate;
    NSUInteger left = MIN((NSUInteger)floor(position), sourceCount - 1);
    NSUInteger right = MIN(left + 1, sourceCount - 1);
    double fraction = position - left;
    double value = source[left] + (source[right] - source[left]) * fraction;
    output[i] = (float)(value * 32767.0 * _announcementVolume);
  }
  _announcementTarget = target;
  _announcementTargetRate = targetRate;
  _announcementPosition = 0;
}

- (void)beginRecording:(BOOL)record
       announcementPath:(NSString *)announcementPath
                  volume:(double)volume
              completion:(FlutterResult)completion {
  NSError *error = nil;
  if (![self loadAnnouncement:announcementPath error:&error]) {
    os_unfair_lock_lock(&_lock);
    _gateArmed = NO;
    os_unfair_lock_unlock(&_lock);
    completion([FlutterError errorWithCode:@"announcement_decode_failed"
                                   message:error.localizedDescription ?: @"Unable to decode announcement"
                                   details:nil]);
    return;
  }

  NSString *identifier = NSUUID.UUID.UUIDString;
  NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"alma-call-recordings"];
  if (![[NSFileManager defaultManager] createDirectoryAtPath:directory
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&error]) {
    os_unfair_lock_lock(&_lock);
    _gateArmed = NO;
    os_unfair_lock_unlock(&_lock);
    completion([FlutterError errorWithCode:@"recording_directory_failed"
                                   message:error.localizedDescription ?: @"Unable to prepare the recording directory"
                                   details:nil]);
    return;
  }

  os_unfair_lock_lock(&_lock);
  _recording = record;
  _stopping = NO;
  _gateArmed = announcementPath.length > 0;
  _sessionStartedAt = CACurrentMediaTime();
  _announcementVolume = MAX(0.2, MIN(1.0, volume));
  _announcementTarget = nil;
  _announcementTargetRate = 0;
  _announcementPosition = 0;
  _localPath = [directory stringByAppendingPathComponent:[identifier stringByAppendingString:@"-local.caf"]];
  _remotePath = [directory stringByAppendingPathComponent:[identifier stringByAppendingString:@"-remote.caf"]];
  _outputPath = [directory stringByAppendingPathComponent:[identifier stringByAppendingString:@".m4a"]];
  _hasLocalOffset = NO;
  _hasRemoteOffset = NO;
  os_unfair_lock_unlock(&_lock);

  completion(nil);
}

- (AVAudioFile *)openPcmFileAtPath:(NSString *)path sampleRate:(double)sampleRate {
  NSDictionary *settings = @{
    AVFormatIDKey: @(kAudioFormatLinearPCM),
    AVSampleRateKey: @(sampleRate),
    AVNumberOfChannelsKey: @1,
    AVLinearPCMBitDepthKey: @16,
    AVLinearPCMIsFloatKey: @NO,
    AVLinearPCMIsBigEndianKey: @NO,
    AVLinearPCMIsNonInterleaved: @YES,
  };
  NSError *error = nil;
  AVAudioFile *file = [[AVAudioFile alloc] initForWriting:[NSURL fileURLWithPath:path]
                                                 settings:settings
                                             commonFormat:AVAudioPCMFormatInt16
                                              interleaved:NO
                                                    error:&error];
  if (!file) NSLog(@"CallCompliance: unable to open PCM file: %@", error);
  return file;
}

- (void)writePcmData:(NSData *)data
            sampleRate:(double)sampleRate
                 local:(BOOL)local
                offset:(double)offset {
  if (data.length == 0) return;
  dispatch_async(_writerQueue, ^{
    AVAudioFile *file = local ? self->_localFile : self->_remoteFile;
    NSString *path = local ? self->_localPath : self->_remotePath;
    if (!file) {
      file = [self openPcmFileAtPath:path sampleRate:sampleRate];
      if (local) {
        self->_localFile = file;
      } else {
        self->_remoteFile = file;
      }
      if (local) {
        self->_localFirstOffset = offset;
        self->_hasLocalOffset = YES;
      } else {
        self->_remoteFirstOffset = offset;
        self->_hasRemoteOffset = YES;
      }
    }
    if (!file) return;

    AVAudioFormat *format = file.processingFormat;
    AVAudioFrameCount frames = (AVAudioFrameCount)(data.length / sizeof(int16_t));
    AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:frames];
    buffer.frameLength = frames;
    memcpy(buffer.int16ChannelData[0], data.bytes, data.length);
    NSError *error = nil;
    if (![file writeFromBuffer:buffer error:&error]) {
      NSLog(@"CallCompliance: PCM write failed: %@", error);
    }
  });
}

- (void)processBuffer:(RTC_OBJC_TYPE(RTCAudioBuffer) *)buffer
                  role:(AlmaComplianceAudioRole)role {
  NSUInteger frames = buffer.frames;
  NSUInteger channels = MAX((NSUInteger)1, buffer.channels);
  double sampleRate = frames * 100.0;
  BOOL local = role == AlmaComplianceAudioRoleLocal;
  NSMutableData *recorded = nil;

  os_unfair_lock_lock(&_lock);
  BOOL active = _recording || (local && _gateArmed);
  if (!active || _stopping) {
    os_unfair_lock_unlock(&_lock);
    return;
  }

  if (local && _gateArmed && _announcementSource) {
    [self prepareAnnouncementForRateLocked:sampleRate];
  }

  if (_recording) recorded = [NSMutableData dataWithLength:frames * sizeof(int16_t)];
  int16_t *pcm = recorded ? (int16_t *)recorded.mutableBytes : NULL;
  const float *announcement = (const float *)_announcementTarget.bytes;
  NSUInteger announcementCount = _announcementTarget.length / sizeof(float);

  for (NSUInteger frame = 0; frame < frames; frame++) {
    double mono = 0;
    if (local && _gateArmed) {
      float injected = 0;
      if (announcement && _announcementPosition < announcementCount) {
        injected = announcement[_announcementPosition++];
      }
      for (NSUInteger channel = 0; channel < channels; channel++) {
        [buffer rawBufferForChannel:channel][frame] = injected;
      }
      mono = injected;
      if (_announcementPosition >= announcementCount && announcementCount > 0) {
        _gateArmed = NO;
      }
    } else {
      for (NSUInteger channel = 0; channel < channels; channel++) {
        mono += [buffer rawBufferForChannel:channel][frame];
      }
      mono /= channels;
    }
    if (pcm) pcm[frame] = (int16_t)lrint(MAX(-32768.0, MIN(32767.0, mono)));
  }
  double offset = MAX(0, CACurrentMediaTime() - _sessionStartedAt);
  os_unfair_lock_unlock(&_lock);

  if (recorded) [self writePcmData:recorded sampleRate:sampleRate local:local offset:offset];
}

- (void)exportRecordingWithCompletion:(FlutterResult)completion {
  NSURL *localURL = [NSURL fileURLWithPath:_localPath];
  NSURL *remoteURL = [NSURL fileURLWithPath:_remotePath];
  BOOL hasLocal = [[NSFileManager defaultManager] fileExistsAtPath:_localPath];
  BOOL hasRemote = [[NSFileManager defaultManager] fileExistsAtPath:_remotePath];
  if (!hasLocal && !hasRemote) {
    completion(nil);
    return;
  }

  AVMutableComposition *composition = [AVMutableComposition composition];
  __block double durationSeconds = 0;
  NSError *compositionError = nil;
  NSArray<NSDictionary *> *sources = @[
    @{ @"url": localURL, @"offset": @(_hasLocalOffset ? _localFirstOffset : 0), @"exists": @(hasLocal) },
    @{ @"url": remoteURL, @"offset": @(_hasRemoteOffset ? _remoteFirstOffset : 0), @"exists": @(hasRemote) },
  ];
  for (NSDictionary *source in sources) {
    if (![source[@"exists"] boolValue]) continue;
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:source[@"url"] options:nil];
    AVAssetTrack *assetTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    if (!assetTrack) continue;
    AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                 preferredTrackID:kCMPersistentTrackID_Invalid];
    double offset = [source[@"offset"] doubleValue];
    if (![track insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                        ofTrack:assetTrack
                         atTime:CMTimeMakeWithSeconds(offset, 600)
                          error:&compositionError]) {
      completion([FlutterError errorWithCode:@"recording_mix_failed"
                                     message:compositionError.localizedDescription
                                     details:nil]);
      return;
    }
    durationSeconds = MAX(durationSeconds, offset + CMTimeGetSeconds(asset.duration));
  }

  [[NSFileManager defaultManager] removeItemAtPath:_outputPath error:nil];
  AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
      initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
  exporter.outputURL = [NSURL fileURLWithPath:_outputPath];
  exporter.outputFileType = AVFileTypeAppleM4A;
  exporter.shouldOptimizeForNetworkUse = YES;
  [exporter exportAsynchronouslyWithCompletionHandler:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSFileManager defaultManager] removeItemAtPath:self->_localPath error:nil];
      [[NSFileManager defaultManager] removeItemAtPath:self->_remotePath error:nil];
      if (exporter.status == AVAssetExportSessionStatusCompleted) {
        completion(@{
          @"path": self->_outputPath,
          @"duration_ms": @((NSInteger)llround(durationSeconds * 1000.0)),
          @"mime_type": @"audio/mp4",
        });
      } else {
        completion([FlutterError errorWithCode:@"recording_export_failed"
                                       message:exporter.error.localizedDescription ?: @"Unable to export recording"
                                       details:nil]);
      }
    });
  }];
}

- (void)stopWithCompletion:(FlutterResult)completion {
  os_unfair_lock_lock(&_lock);
  BOOL hadRecording = _recording;
  _recording = NO;
  _gateArmed = NO;
  _stopping = YES;
  os_unfair_lock_unlock(&_lock);

  dispatch_async(_writerQueue, ^{
    self->_localFile = nil;
    self->_remoteFile = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!hadRecording) {
        completion(nil);
      } else {
        [self exportRecordingWithCompletion:completion];
      }
    });
  });
}

- (void)cancel {
  os_unfair_lock_lock(&_lock);
  _recording = NO;
  _gateArmed = NO;
  _stopping = YES;
  os_unfair_lock_unlock(&_lock);
  dispatch_async(_writerQueue, ^{
    self->_localFile = nil;
    self->_remoteFile = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self->_localPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:self->_remotePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:self->_outputPath error:nil];
  });
}

@end

@implementation CallComplianceAudioPlugin {
  AlmaComplianceSession *_session;
  AlmaComplianceProcessor *_localProcessor;
  AlmaComplianceProcessor *_remoteProcessor;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel
      methodChannelWithName:@"com.almacrm.call_compliance_audio"
            binaryMessenger:registrar.messenger];
  CallComplianceAudioPlugin *instance = [[CallComplianceAudioPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _session = [[AlmaComplianceSession alloc] init];
    _localProcessor = [[AlmaComplianceProcessor alloc] initWithSession:_session
                                                                  role:AlmaComplianceAudioRoleLocal];
    _remoteProcessor = [[AlmaComplianceProcessor alloc] initWithSession:_session
                                                                   role:AlmaComplianceAudioRoleRemote];
    [[AudioManager sharedInstance].capturePostProcessingAdapter addProcessing:_localProcessor];
    [[AudioManager sharedInstance].renderPreProcessingAdapter addProcessing:_remoteProcessor];
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:@"armGate"]) {
    [_session armGate];
    result(nil);
  } else if ([call.method isEqualToString:@"begin"]) {
    NSDictionary *arguments = call.arguments ?: @{};
    id rawAnnouncementPath = arguments[@"announcement_path"];
    NSString *announcementPath = [rawAnnouncementPath isKindOfClass:NSString.class]
        ? rawAnnouncementPath
        : nil;
    [_session beginRecording:[arguments[@"record"] boolValue]
             announcementPath:announcementPath
                        volume:[arguments[@"announcement_volume"] doubleValue]
                    completion:result];
  } else if ([call.method isEqualToString:@"stop"]) {
    [_session stopWithCompletion:result];
  } else if ([call.method isEqualToString:@"cancel"]) {
    [_session cancel];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
