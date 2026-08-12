cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "call_compliance_audio")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "call_compliance_audio_plugin")

add_library(${PLUGIN_NAME} SHARED
  "call_compliance_audio_plugin.cpp"
  "include/call_compliance_audio/call_compliance_audio_plugin.h"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE
  CALL_COMPLIANCE_AUDIO_PLUGIN_IMPL
  NOMINMAX
)
target_compile_options(${PLUGIN_NAME} PRIVATE /wd4244 /wd4267)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  flutter_webrtc_plugin
  mfplat
  mfreadwrite
  mfuuid
  ole32
)

set(call_compliance_audio_bundled_libraries
  ""
  PARENT_SCOPE
)
