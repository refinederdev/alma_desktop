#ifndef FLUTTER_PLUGIN_CALL_COMPLIANCE_AUDIO_PLUGIN_H_
#define FLUTTER_PLUGIN_CALL_COMPLIANCE_AUDIO_PLUGIN_H_

#include <flutter_plugin_registrar.h>

#ifdef CALL_COMPLIANCE_AUDIO_PLUGIN_IMPL
#define CALL_COMPLIANCE_AUDIO_PLUGIN_EXPORT __declspec(dllexport)
#else
#define CALL_COMPLIANCE_AUDIO_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

CALL_COMPLIANCE_AUDIO_PLUGIN_EXPORT void
CallComplianceAudioPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_CALL_COMPLIANCE_AUDIO_PLUGIN_H_
