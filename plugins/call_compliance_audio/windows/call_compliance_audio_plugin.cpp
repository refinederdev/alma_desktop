#include "include/call_compliance_audio/call_compliance_audio_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter_webrtc/flutter_web_r_t_c_plugin.h>
#include <flutter_webrtc.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <windows.h>
#include <wrl/client.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <cstdint>
#include <cstdio>
#include <deque>
#include <iterator>
#include <limits>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <utility>
#include <variant>
#include <vector>

#include <rtc_audio_processing.h>

namespace call_compliance_audio {
namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using Microsoft::WRL::ComPtr;

constexpr int kRecordingSampleRate = 48000;
constexpr char kChannelName[] = "com.almacrm.call_compliance_audio";

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) return std::wstring();
  const int size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                                       value.data(),
                                       static_cast<int>(value.size()), nullptr,
                                       0);
  if (size <= 0) return std::wstring();
  std::wstring result(static_cast<size_t>(size), L'\0');
  MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
                      static_cast<int>(value.size()), result.data(), size);
  return result;
}

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) return std::string();
  const int size = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
                                      value.data(),
                                      static_cast<int>(value.size()), nullptr,
                                      0, nullptr, nullptr);
  if (size <= 0) return std::string();
  std::string result(static_cast<size_t>(size), '\0');
  WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, value.data(),
                      static_cast<int>(value.size()), result.data(), size,
                      nullptr, nullptr);
  return result;
}

std::string HresultMessage(HRESULT result) {
  wchar_t* message = nullptr;
  const DWORD flags = FORMAT_MESSAGE_ALLOCATE_BUFFER |
                      FORMAT_MESSAGE_FROM_SYSTEM |
                      FORMAT_MESSAGE_IGNORE_INSERTS;
  const DWORD length = FormatMessageW(
      flags, nullptr, static_cast<DWORD>(result), 0,
      reinterpret_cast<wchar_t*>(&message), 0, nullptr);
  std::wstring text = length > 0 && message != nullptr
                          ? std::wstring(message, length)
                          : L"Windows error " + std::to_wstring(result);
  if (message != nullptr) LocalFree(message);
  while (!text.empty() &&
         (text.back() == L'\r' || text.back() == L'\n' ||
          text.back() == L' ')) {
    text.pop_back();
  }
  return WideToUtf8(text);
}

class ComScope {
 public:
  ComScope() : result_(CoInitializeEx(nullptr, COINIT_MULTITHREADED)) {}
  ~ComScope() {
    if (result_ == S_OK || result_ == S_FALSE) CoUninitialize();
  }

 private:
  HRESULT result_;
};

class MediaFoundationScope {
 public:
  MediaFoundationScope() : result_(MFStartup(MF_VERSION)) {}
  ~MediaFoundationScope() {
    if (SUCCEEDED(result_)) MFShutdown();
  }
  HRESULT result() const { return result_; }

 private:
  HRESULT result_;
};

struct AnnouncementAudio {
  std::vector<int16_t> samples;
  int sample_rate = 0;
};

bool DecodeAnnouncement(const std::wstring& path,
                        AnnouncementAudio* output,
                        std::string* error) {
  ComScope com;
  MediaFoundationScope media_foundation;
  if (FAILED(media_foundation.result())) {
    *error = "Unable to start Windows Media Foundation: " +
             HresultMessage(media_foundation.result());
    return false;
  }

  ComPtr<IMFSourceReader> reader;
  HRESULT result =
      MFCreateSourceReaderFromURL(path.c_str(), nullptr, &reader);
  if (FAILED(result)) {
    *error = "Unable to open the call announcement: " +
             HresultMessage(result);
    return false;
  }

  reader->SetStreamSelection(MF_SOURCE_READER_ALL_STREAMS, FALSE);
  result = reader->SetStreamSelection(MF_SOURCE_READER_FIRST_AUDIO_STREAM,
                                      TRUE);

  ComPtr<IMFMediaType> requested_type;
  if (SUCCEEDED(result)) result = MFCreateMediaType(&requested_type);
  if (SUCCEEDED(result)) {
    result = requested_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio);
  }
  if (SUCCEEDED(result)) {
    result = requested_type->SetGUID(MF_MT_SUBTYPE, MFAudioFormat_PCM);
  }
  if (SUCCEEDED(result)) {
    result = requested_type->SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, 16);
  }
  if (SUCCEEDED(result)) {
    result = reader->SetCurrentMediaType(MF_SOURCE_READER_FIRST_AUDIO_STREAM,
                                         nullptr, requested_type.Get());
  }
  if (FAILED(result)) {
    *error = "Unable to decode the call announcement: " +
             HresultMessage(result);
    return false;
  }

  ComPtr<IMFMediaType> actual_type;
  result = reader->GetCurrentMediaType(MF_SOURCE_READER_FIRST_AUDIO_STREAM,
                                       &actual_type);
  UINT32 sample_rate = 0;
  UINT32 channels = 0;
  UINT32 bits = 0;
  if (SUCCEEDED(result)) {
    result = actual_type->GetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND,
                                    &sample_rate);
  }
  if (SUCCEEDED(result)) {
    result = actual_type->GetUINT32(MF_MT_AUDIO_NUM_CHANNELS, &channels);
  }
  if (SUCCEEDED(result)) {
    result = actual_type->GetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, &bits);
  }
  if (FAILED(result) || sample_rate == 0 || channels == 0 || bits != 16) {
    *error = "Windows returned an unsupported announcement audio format";
    return false;
  }

  std::vector<int16_t> interleaved;
  while (true) {
    DWORD flags = 0;
    ComPtr<IMFSample> sample;
    result = reader->ReadSample(MF_SOURCE_READER_FIRST_AUDIO_STREAM, 0,
                                nullptr, &flags, nullptr, &sample);
    if (FAILED(result)) {
      *error = "Unable to read the call announcement: " +
               HresultMessage(result);
      return false;
    }
    if (sample != nullptr) {
      ComPtr<IMFMediaBuffer> buffer;
      result = sample->ConvertToContiguousBuffer(&buffer);
      if (FAILED(result)) {
        *error = "Unable to read announcement PCM data: " +
                 HresultMessage(result);
        return false;
      }
      BYTE* bytes = nullptr;
      DWORD length = 0;
      result = buffer->Lock(&bytes, nullptr, &length);
      if (FAILED(result)) {
        *error = "Unable to access announcement PCM data: " +
                 HresultMessage(result);
        return false;
      }
      const size_t count = static_cast<size_t>(length) / sizeof(int16_t);
      const int16_t* pcm = reinterpret_cast<const int16_t*>(bytes);
      interleaved.insert(interleaved.end(), pcm, pcm + count);
      buffer->Unlock();
    }
    if ((flags & MF_SOURCE_READERF_ENDOFSTREAM) != 0) break;
  }

  const size_t frame_count = interleaved.size() / channels;
  if (frame_count == 0) {
    *error = "The call announcement contains no audio samples";
    return false;
  }
  output->samples.resize(frame_count);
  for (size_t frame = 0; frame < frame_count; ++frame) {
    int64_t sum = 0;
    for (UINT32 channel = 0; channel < channels; ++channel) {
      sum += interleaved[frame * channels + channel];
    }
    output->samples[frame] = static_cast<int16_t>(sum / channels);
  }
  output->sample_rate = static_cast<int>(sample_rate);
  return true;
}

std::vector<int16_t> ResamplePcm(const int16_t* source,
                                 size_t source_count,
                                 int source_rate,
                                 int target_rate) {
  if (source_count == 0 || source_rate <= 0 || target_rate <= 0) return {};
  if (source_rate == target_rate) {
    return std::vector<int16_t>(source, source + source_count);
  }
  const size_t target_count = static_cast<size_t>(std::ceil(
      static_cast<double>(source_count) * target_rate / source_rate));
  std::vector<int16_t> output(target_count);
  for (size_t index = 0; index < target_count; ++index) {
    const double position =
        static_cast<double>(index) * source_rate / target_rate;
    const size_t left = std::min(static_cast<size_t>(position),
                                 source_count - 1);
    const size_t right = std::min(left + 1, source_count - 1);
    const double fraction = position - static_cast<double>(left);
    const double value = source[left] +
                         (source[right] - source[left]) * fraction;
    output[index] = static_cast<int16_t>(std::clamp(
        std::lround(value), static_cast<long>(-32768),
        static_cast<long>(32767)));
  }
  return output;
}

std::wstring NewRecordingIdentifier() {
  GUID guid{};
  if (FAILED(CoCreateGuid(&guid))) {
    return std::to_wstring(GetTickCount64());
  }
  wchar_t value[40] = {};
  StringFromGUID2(guid, value, static_cast<int>(std::size(value)));
  std::wstring result(value);
  result.erase(std::remove_if(result.begin(), result.end(),
                              [](wchar_t character) {
                                return character == L'{' ||
                                       character == L'}' ||
                                       character == L'-';
                              }),
               result.end());
  return result;
}

bool PrepareRecordingPaths(std::wstring* local,
                           std::wstring* remote,
                           std::wstring* mixed_wav,
                           std::wstring* output,
                           std::string* error) {
  wchar_t temporary[MAX_PATH + 1] = {};
  const DWORD length = GetTempPathW(MAX_PATH, temporary);
  if (length == 0 || length > MAX_PATH) {
    *error = "Unable to locate the Windows temporary directory";
    return false;
  }
  std::wstring directory(temporary);
  if (!directory.empty() && directory.back() != L'\\') directory += L'\\';
  directory += L"alma-call-recordings";
  if (!CreateDirectoryW(directory.c_str(), nullptr) &&
      GetLastError() != ERROR_ALREADY_EXISTS) {
    *error = "Unable to create the call recording directory";
    return false;
  }
  const std::wstring base = directory + L"\\" + NewRecordingIdentifier();
  *local = base + L"-local.pcm";
  *remote = base + L"-remote.pcm";
  *mixed_wav = base + L"-mixed.wav";
  *output = base + L".m4a";
  return true;
}

void WriteUint16(FILE* file, uint16_t value) {
  fwrite(&value, sizeof(value), 1, file);
}

void WriteUint32(FILE* file, uint32_t value) {
  fwrite(&value, sizeof(value), 1, file);
}

void WriteWavHeader(FILE* file, uint32_t sample_count) {
  const uint32_t data_size = sample_count * sizeof(int16_t);
  fwrite("RIFF", 1, 4, file);
  WriteUint32(file, 36 + data_size);
  fwrite("WAVEfmt ", 1, 8, file);
  WriteUint32(file, 16);
  WriteUint16(file, 1);
  WriteUint16(file, 1);
  WriteUint32(file, kRecordingSampleRate);
  WriteUint32(file, kRecordingSampleRate * sizeof(int16_t));
  WriteUint16(file, sizeof(int16_t));
  WriteUint16(file, 16);
  fwrite("data", 1, 4, file);
  WriteUint32(file, data_size);
}

bool EncodeWavToAac(const std::wstring& wav_path,
                    const std::wstring& output_path,
                    std::string* error) {
  ComScope com;
  MediaFoundationScope media_foundation;
  if (FAILED(media_foundation.result())) {
    *error = "Unable to start Windows audio encoding: " +
             HresultMessage(media_foundation.result());
    return false;
  }

  ComPtr<IMFSourceReader> reader;
  HRESULT result =
      MFCreateSourceReaderFromURL(wav_path.c_str(), nullptr, &reader);
  if (FAILED(result)) {
    *error = "Unable to open the mixed call audio: " +
             HresultMessage(result);
    return false;
  }
  reader->SetStreamSelection(MF_SOURCE_READER_ALL_STREAMS, FALSE);
  result = reader->SetStreamSelection(MF_SOURCE_READER_FIRST_AUDIO_STREAM,
                                      TRUE);

  ComPtr<IMFMediaType> input_type;
  if (SUCCEEDED(result)) {
    result = reader->GetCurrentMediaType(MF_SOURCE_READER_FIRST_AUDIO_STREAM,
                                         &input_type);
  }

  ComPtr<IMFSinkWriter> writer;
  if (SUCCEEDED(result)) {
    result = MFCreateSinkWriterFromURL(output_path.c_str(), nullptr, nullptr,
                                       &writer);
  }

  ComPtr<IMFMediaType> output_type;
  if (SUCCEEDED(result)) result = MFCreateMediaType(&output_type);
  if (SUCCEEDED(result)) {
    result = output_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio);
  }
  if (SUCCEEDED(result)) {
    result = output_type->SetGUID(MF_MT_SUBTYPE, MFAudioFormat_AAC);
  }
  if (SUCCEEDED(result)) {
    result = output_type->SetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND,
                                    kRecordingSampleRate);
  }
  if (SUCCEEDED(result)) {
    result = output_type->SetUINT32(MF_MT_AUDIO_NUM_CHANNELS, 1);
  }
  if (SUCCEEDED(result)) {
    result = output_type->SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, 16);
  }
  if (SUCCEEDED(result)) {
    result = output_type->SetUINT32(MF_MT_AUDIO_AVG_BYTES_PER_SECOND, 24000);
  }
  if (SUCCEEDED(result)) {
    result = output_type->SetUINT32(MF_MT_AUDIO_BLOCK_ALIGNMENT, 1);
  }
  if (SUCCEEDED(result)) {
    result = output_type->SetUINT32(MF_MT_AAC_PAYLOAD_TYPE, 0);
  }
  if (SUCCEEDED(result)) {
    result = output_type->SetUINT32(
        MF_MT_AAC_AUDIO_PROFILE_LEVEL_INDICATION, 0x29);
  }

  DWORD output_stream = 0;
  if (SUCCEEDED(result)) {
    result = writer->AddStream(output_type.Get(), &output_stream);
  }
  if (SUCCEEDED(result)) {
    result = writer->SetInputMediaType(output_stream, input_type.Get(),
                                       nullptr);
  }
  if (SUCCEEDED(result)) result = writer->BeginWriting();
  if (FAILED(result)) {
    *error = "Unable to start Windows AAC encoding: " +
             HresultMessage(result);
    return false;
  }

  while (true) {
    DWORD flags = 0;
    ComPtr<IMFSample> sample;
    result = reader->ReadSample(MF_SOURCE_READER_FIRST_AUDIO_STREAM, 0,
                                nullptr, &flags, nullptr, &sample);
    if (FAILED(result)) break;
    if (sample != nullptr) {
      result = writer->WriteSample(output_stream, sample.Get());
      if (FAILED(result)) break;
    }
    if ((flags & MF_SOURCE_READERF_ENDOFSTREAM) != 0) break;
  }
  if (SUCCEEDED(result)) result = writer->Finalize();
  if (FAILED(result)) {
    *error = "Unable to finish Windows AAC encoding: " +
             HresultMessage(result);
    return false;
  }
  return true;
}

struct AudioChunk {
  bool local = false;
  std::vector<int16_t> samples;
};

struct RecordingResult {
  bool has_recording = false;
  std::string path;
  int64_t duration_ms = 0;
  std::string mime_type;
  std::string error;
};

class ComplianceSession {
 public:
  ComplianceSession() : writer_thread_(&ComplianceSession::WriterLoop, this) {}

  ~ComplianceSession() {
    Cancel();
    {
      std::lock_guard<std::mutex> lock(mutex_);
      writer_shutdown_ = true;
      writer_condition_.notify_all();
    }
    if (writer_thread_.joinable()) writer_thread_.join();
  }

  void ArmGate() {
    std::lock_guard<std::mutex> lock(mutex_);
    gate_armed_ = true;
  }

  bool Begin(bool record,
             const std::string& announcement_path,
             double announcement_volume,
             std::string* error) {
    AnnouncementAudio announcement;
    if (!announcement_path.empty() &&
        !DecodeAnnouncement(Utf8ToWide(announcement_path), &announcement,
                            error)) {
      std::lock_guard<std::mutex> lock(mutex_);
      gate_armed_ = false;
      return false;
    }

    std::wstring local_path;
    std::wstring remote_path;
    std::wstring mixed_wav_path;
    std::wstring output_path;
    if (record &&
        !PrepareRecordingPaths(&local_path, &remote_path, &mixed_wav_path,
                               &output_path, error)) {
      std::lock_guard<std::mutex> lock(mutex_);
      gate_armed_ = false;
      return false;
    }

    FILE* local_file = nullptr;
    FILE* remote_file = nullptr;
    if (record &&
        (_wfopen_s(&local_file, local_path.c_str(), L"wb") != 0 ||
         _wfopen_s(&remote_file, remote_path.c_str(), L"wb") != 0)) {
      if (local_file != nullptr) fclose(local_file);
      if (remote_file != nullptr) fclose(remote_file);
      DeleteFileW(local_path.c_str());
      DeleteFileW(remote_path.c_str());
      *error = "Unable to open the Windows call recording files";
      std::lock_guard<std::mutex> lock(mutex_);
      gate_armed_ = false;
      return false;
    }

    std::lock_guard<std::mutex> lock(mutex_);
    if (recording_ || stopping_) {
      if (local_file != nullptr) fclose(local_file);
      if (remote_file != nullptr) fclose(remote_file);
      DeleteFileW(local_path.c_str());
      DeleteFileW(remote_path.c_str());
      *error = "A call recording is already active";
      return false;
    }
    local_file_ = local_file;
    remote_file_ = remote_file;
    local_path_ = std::move(local_path);
    remote_path_ = std::move(remote_path);
    mixed_wav_path_ = std::move(mixed_wav_path);
    output_path_ = std::move(output_path);
    announcement_source_ = std::move(announcement.samples);
    announcement_source_rate_ = announcement.sample_rate;
    announcement_target_.clear();
    announcement_target_rate_ = 0;
    announcement_position_ = 0;
    announcement_volume_ = std::clamp(announcement_volume, 0.2, 1.0);
    gate_armed_ = !announcement_path.empty();
    recording_ = record;
    stopping_ = false;
    local_first_offset_ = 0;
    remote_first_offset_ = 0;
    local_has_offset_ = false;
    remote_has_offset_ = false;
    local_sample_count_ = 0;
    remote_sample_count_ = 0;
    session_started_ = std::chrono::steady_clock::now();
    return true;
  }

  void Process(bool local, int buffer_size, float* buffer) {
    if (buffer == nullptr || buffer_size <= 0) return;
    std::unique_lock<std::mutex> lock(mutex_);
    if (stopping_ || (!recording_ && !(local && gate_armed_))) return;

    const int sample_rate = buffer_size * 100;
    if (local && gate_armed_ && !announcement_source_.empty()) {
      PrepareAnnouncementLocked(sample_rate);
    }

    std::vector<int16_t> pcm;
    if (recording_) pcm.resize(static_cast<size_t>(buffer_size));
    for (int index = 0; index < buffer_size; ++index) {
      float sample = buffer[index];
      if (local && gate_armed_) {
        sample = 0.0f;
        if (announcement_position_ < announcement_target_.size()) {
          sample = announcement_target_[announcement_position_++];
        }
        buffer[index] = sample;
        if (!announcement_target_.empty() &&
            announcement_position_ >= announcement_target_.size()) {
          gate_armed_ = false;
        }
      }
      if (!pcm.empty()) {
        pcm[static_cast<size_t>(index)] = static_cast<int16_t>(std::clamp(
            std::lround(sample), static_cast<long>(-32768),
            static_cast<long>(32767)));
      }
    }

    if (pcm.empty()) return;
    AudioChunk chunk;
    chunk.local = local;
    chunk.samples = ResamplePcm(pcm.data(), pcm.size(), sample_rate,
                                kRecordingSampleRate);
    const double offset_seconds = std::max(
        0.0, std::chrono::duration<double>(std::chrono::steady_clock::now() -
                                          session_started_)
                 .count());
    const uint64_t offset = static_cast<uint64_t>(std::llround(
        offset_seconds * static_cast<double>(kRecordingSampleRate)));
    if (local && !local_has_offset_) {
      local_has_offset_ = true;
      local_first_offset_ = offset;
    } else if (!local && !remote_has_offset_) {
      remote_has_offset_ = true;
      remote_first_offset_ = offset;
    }
    chunks_.push_back(std::move(chunk));
    writer_condition_.notify_one();
  }

  RecordingResult Stop() {
    bool had_recording = false;
    {
      std::unique_lock<std::mutex> lock(mutex_);
      had_recording = recording_;
      recording_ = false;
      gate_armed_ = false;
      stopping_ = true;
      drained_condition_.wait(lock, [this] {
        return chunks_.empty() && !writer_busy_;
      });
    }
    CloseRawFiles();

    RecordingResult result;
    if (had_recording) result = MixRecording();
    {
      std::lock_guard<std::mutex> lock(mutex_);
      stopping_ = false;
      announcement_source_.clear();
      announcement_target_.clear();
    }
    return result;
  }

  void Cancel() {
    {
      std::unique_lock<std::mutex> lock(mutex_);
      recording_ = false;
      gate_armed_ = false;
      stopping_ = true;
      chunks_.clear();
      drained_condition_.wait(lock, [this] { return !writer_busy_; });
    }
    CloseRawFiles();
    DeleteFileW(local_path_.c_str());
    DeleteFileW(remote_path_.c_str());
    DeleteFileW(mixed_wav_path_.c_str());
    DeleteFileW(output_path_.c_str());
    std::lock_guard<std::mutex> lock(mutex_);
    stopping_ = false;
    announcement_source_.clear();
    announcement_target_.clear();
  }

 private:
  void PrepareAnnouncementLocked(int target_rate) {
    if (target_rate <= 0 || announcement_source_rate_ <= 0 ||
        announcement_source_.empty()) {
      return;
    }
    if (!announcement_target_.empty() &&
        announcement_target_rate_ == target_rate) {
      return;
    }
    const std::vector<int16_t> resampled = ResamplePcm(
        announcement_source_.data(), announcement_source_.size(),
        announcement_source_rate_, target_rate);
    announcement_target_.resize(resampled.size());
    for (size_t index = 0; index < resampled.size(); ++index) {
      announcement_target_[index] = static_cast<float>(
          resampled[index] * announcement_volume_);
    }
    announcement_target_rate_ = target_rate;
    announcement_position_ = 0;
  }

  void WriterLoop() {
    while (true) {
      AudioChunk chunk;
      {
        std::unique_lock<std::mutex> lock(mutex_);
        writer_condition_.wait(lock, [this] {
          return writer_shutdown_ || !chunks_.empty();
        });
        if (writer_shutdown_ && chunks_.empty()) return;
        chunk = std::move(chunks_.front());
        chunks_.pop_front();
        writer_busy_ = true;
      }

      FILE* destination = chunk.local ? local_file_ : remote_file_;
      if (destination != nullptr && !chunk.samples.empty()) {
        fwrite(chunk.samples.data(), sizeof(int16_t), chunk.samples.size(),
               destination);
        if (chunk.local) {
          local_sample_count_ += chunk.samples.size();
        } else {
          remote_sample_count_ += chunk.samples.size();
        }
      }

      {
        std::lock_guard<std::mutex> lock(mutex_);
        writer_busy_ = false;
        if (chunks_.empty()) drained_condition_.notify_all();
      }
    }
  }

  void CloseRawFiles() {
    if (local_file_ != nullptr) {
      fclose(local_file_);
      local_file_ = nullptr;
    }
    if (remote_file_ != nullptr) {
      fclose(remote_file_);
      remote_file_ = nullptr;
    }
  }

  static void AddSource(FILE* source,
                        uint64_t source_count,
                        uint64_t source_offset,
                        uint64_t block_start,
                        size_t block_size,
                        std::vector<int32_t>* mixed) {
    if (source == nullptr || source_count == 0) return;
    const uint64_t block_end = block_start + block_size;
    const uint64_t source_end = source_offset + source_count;
    const uint64_t overlap_start = std::max(block_start, source_offset);
    const uint64_t overlap_end = std::min(block_end, source_end);
    if (overlap_start >= overlap_end) return;

    const uint64_t source_index = overlap_start - source_offset;
    const size_t destination_index =
        static_cast<size_t>(overlap_start - block_start);
    const size_t count = static_cast<size_t>(overlap_end - overlap_start);
    std::vector<int16_t> samples(count);
    _fseeki64(source, static_cast<int64_t>(source_index * sizeof(int16_t)),
              SEEK_SET);
    const size_t read = fread(samples.data(), sizeof(int16_t), count, source);
    for (size_t index = 0; index < read; ++index) {
      (*mixed)[destination_index + index] += samples[index];
    }
  }

  RecordingResult MixRecording() {
    RecordingResult result;
    const uint64_t local_end = local_has_offset_
                                   ? local_first_offset_ + local_sample_count_
                                   : 0;
    const uint64_t remote_end = remote_has_offset_
                                    ? remote_first_offset_ + remote_sample_count_
                                    : 0;
    uint64_t total_samples = std::max(local_end, remote_end);
    if (total_samples == 0) return result;

    const uint64_t max_wav_samples =
        (std::numeric_limits<uint32_t>::max() - 36ULL) / sizeof(int16_t);
    total_samples = std::min(total_samples, max_wav_samples);

    FILE* local = nullptr;
    FILE* remote = nullptr;
    FILE* output = nullptr;
    if (local_sample_count_ > 0) {
      _wfopen_s(&local, local_path_.c_str(), L"rb");
    }
    if (remote_sample_count_ > 0) {
      _wfopen_s(&remote, remote_path_.c_str(), L"rb");
    }
    if (_wfopen_s(&output, mixed_wav_path_.c_str(), L"wb") != 0 ||
        output == nullptr) {
      if (local != nullptr) fclose(local);
      if (remote != nullptr) fclose(remote);
      result.error = "Unable to create the mixed Windows call recording";
      return result;
    }

    WriteWavHeader(output, static_cast<uint32_t>(total_samples));
    constexpr size_t kBlockSize = 8192;
    for (uint64_t block_start = 0; block_start < total_samples;
         block_start += kBlockSize) {
      const size_t block_size = static_cast<size_t>(std::min<uint64_t>(
          kBlockSize, total_samples - block_start));
      std::vector<int32_t> mixed(block_size, 0);
      AddSource(local, local_sample_count_, local_first_offset_, block_start,
                block_size, &mixed);
      AddSource(remote, remote_sample_count_, remote_first_offset_, block_start,
                block_size, &mixed);
      std::vector<int16_t> pcm(block_size);
      for (size_t index = 0; index < block_size; ++index) {
        pcm[index] = static_cast<int16_t>(
            std::clamp(mixed[index], -32768, 32767));
      }
      fwrite(pcm.data(), sizeof(int16_t), pcm.size(), output);
    }
    if (local != nullptr) fclose(local);
    if (remote != nullptr) fclose(remote);
    fclose(output);
    DeleteFileW(local_path_.c_str());
    DeleteFileW(remote_path_.c_str());

    result.has_recording = true;
    result.duration_ms = static_cast<int64_t>(std::llround(
        static_cast<double>(total_samples) * 1000.0 /
        kRecordingSampleRate));
    std::string encoding_error;
    if (EncodeWavToAac(mixed_wav_path_, output_path_, &encoding_error)) {
      DeleteFileW(mixed_wav_path_.c_str());
      result.path = WideToUtf8(output_path_);
      result.mime_type = "audio/mp4";
    } else {
      DeleteFileW(output_path_.c_str());
      result.path = WideToUtf8(mixed_wav_path_);
      result.mime_type = "audio/wav";
    }
    return result;
  }

  std::mutex mutex_;
  std::condition_variable writer_condition_;
  std::condition_variable drained_condition_;
  std::deque<AudioChunk> chunks_;
  std::thread writer_thread_;
  bool writer_shutdown_ = false;
  bool writer_busy_ = false;
  bool recording_ = false;
  bool gate_armed_ = false;
  bool stopping_ = false;
  std::chrono::steady_clock::time_point session_started_;

  std::vector<int16_t> announcement_source_;
  int announcement_source_rate_ = 0;
  std::vector<float> announcement_target_;
  int announcement_target_rate_ = 0;
  size_t announcement_position_ = 0;
  double announcement_volume_ = 0.9;

  FILE* local_file_ = nullptr;
  FILE* remote_file_ = nullptr;
  std::wstring local_path_;
  std::wstring remote_path_;
  std::wstring mixed_wav_path_;
  std::wstring output_path_;
  uint64_t local_first_offset_ = 0;
  uint64_t remote_first_offset_ = 0;
  bool local_has_offset_ = false;
  bool remote_has_offset_ = false;
  uint64_t local_sample_count_ = 0;
  uint64_t remote_sample_count_ = 0;
};

class ComplianceProcessor : public libwebrtc::RTCAudioProcessing::CustomProcessing {
 public:
  ComplianceProcessor(ComplianceSession* session, bool local)
      : session_(session), local_(local) {}

  void Initialize(int sample_rate_hz, int num_channels) override {
    (void)sample_rate_hz;
    (void)num_channels;
  }

  void Process(int num_bands,
               int num_frames,
               int buffer_size,
               float* buffer) override {
    (void)num_bands;
    (void)num_frames;
    session_->Process(local_, buffer_size, buffer);
  }

  void Reset(int new_rate) override { (void)new_rate; }
  void Release() override {}

 private:
  ComplianceSession* session_;
  bool local_;
};

const EncodableValue* FindArgument(const EncodableMap* arguments,
                                   const char* name) {
  if (arguments == nullptr) return nullptr;
  const auto iterator = arguments->find(EncodableValue(name));
  return iterator == arguments->end() ? nullptr : &iterator->second;
}

std::string StringArgument(const EncodableMap* arguments, const char* name) {
  const EncodableValue* value = FindArgument(arguments, name);
  if (value == nullptr) return std::string();
  const std::string* string = std::get_if<std::string>(value);
  return string == nullptr ? std::string() : *string;
}

bool BoolArgument(const EncodableMap* arguments,
                  const char* name,
                  bool fallback) {
  const EncodableValue* value = FindArgument(arguments, name);
  if (value == nullptr) return fallback;
  const bool* boolean = std::get_if<bool>(value);
  return boolean == nullptr ? fallback : *boolean;
}

double DoubleArgument(const EncodableMap* arguments,
                      const char* name,
                      double fallback) {
  const EncodableValue* value = FindArgument(arguments, name);
  if (value == nullptr) return fallback;
  if (const double* number = std::get_if<double>(value)) return *number;
  if (const int* number = std::get_if<int>(value)) {
    return static_cast<double>(*number);
  }
  return fallback;
}

class CallComplianceAudioPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
    auto channel =
        std::make_unique<flutter::MethodChannel<EncodableValue>>(
            registrar->messenger(), kChannelName,
            &flutter::StandardMethodCodec::GetInstance());
    auto plugin = std::make_unique<CallComplianceAudioPlugin>();
    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto& call, auto result) {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });
    registrar->AddPlugin(std::move(plugin));
  }

  CallComplianceAudioPlugin()
      : capture_processor_(&session_, true),
        render_processor_(&session_, false) {}

  ~CallComplianceAudioPlugin() override {
    if (audio_processing_) {
      audio_processing_->SetCapturePostProcessing(nullptr);
      audio_processing_->SetRenderPreProcessing(nullptr);
    }
  }

 private:
  bool EnsureAttached(std::string* error) {
    if (audio_processing_) return true;
    flutter_webrtc_plugin::FlutterWebRTC* webrtc =
        FlutterWebRTCPluginSharedInstance();
    if (webrtc == nullptr) {
      *error = "The Windows WebRTC calling engine is not initialized";
      return false;
    }
    audio_processing_ = webrtc->audio_processing();
    if (!audio_processing_) {
      *error = "The Windows WebRTC audio processor is unavailable";
      return false;
    }
    audio_processing_->SetCapturePostProcessing(&capture_processor_);
    audio_processing_->SetRenderPreProcessing(&render_processor_);
    return true;
  }

  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    std::string error;
    if (method_call.method_name() == "armGate") {
      if (!EnsureAttached(&error)) {
        result->Error("webrtc_unavailable", error);
        return;
      }
      session_.ArmGate();
      result->Success();
      return;
    }

    if (method_call.method_name() == "begin") {
      if (!EnsureAttached(&error)) {
        result->Error("webrtc_unavailable", error);
        return;
      }
      const EncodableMap* arguments =
          std::get_if<EncodableMap>(method_call.arguments());
      if (!session_.Begin(
              BoolArgument(arguments, "record", true),
              StringArgument(arguments, "announcement_path"),
              DoubleArgument(arguments, "announcement_volume", 0.9),
              &error)) {
        result->Error("recording_start_failed", error);
        return;
      }
      result->Success();
      return;
    }

    if (method_call.method_name() == "stop") {
      std::thread([this, result = std::move(result)]() mutable {
        RecordingResult recording = session_.Stop();
        if (!recording.error.empty()) {
          result->Error("recording_export_failed", recording.error);
        } else if (!recording.has_recording) {
          result->Success();
        } else {
          EncodableMap response;
          response[EncodableValue("path")] = EncodableValue(recording.path);
          response[EncodableValue("duration_ms")] =
              EncodableValue(recording.duration_ms);
          response[EncodableValue("mime_type")] =
              EncodableValue(recording.mime_type);
          result->Success(EncodableValue(response));
        }
      }).detach();
      return;
    }

    if (method_call.method_name() == "cancel") {
      session_.Cancel();
      result->Success();
      return;
    }
    result->NotImplemented();
  }

  ComplianceSession session_;
  ComplianceProcessor capture_processor_;
  ComplianceProcessor render_processor_;
  libwebrtc::scoped_refptr<libwebrtc::RTCAudioProcessing> audio_processing_;
};

}  // namespace
}  // namespace call_compliance_audio

void CallComplianceAudioPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  call_compliance_audio::CallComplianceAudioPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
