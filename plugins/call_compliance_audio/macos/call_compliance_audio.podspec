Pod::Spec.new do |s|
  s.name             = 'call_compliance_audio'
  s.version          = '0.1.0'
  s.summary          = 'Alma Desktop call compliance audio processor.'
  s.description      = 'Injects a disclosure into WebRTC capture and records both call directions.'
  s.homepage         = 'https://almacrm.com'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'Alma CRM' => 'support@almacrm.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.dependency 'flutter_webrtc'
  s.frameworks = 'AVFoundation', 'AudioToolbox', 'CoreMedia', 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
