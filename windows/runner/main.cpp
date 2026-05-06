#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <algorithm>
#include <shobjidl_core.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  ::SetCurrentProcessExplicitAppUserModelID(L"com.almacrm.desktop.ALMA_CRM");

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  RECT work_area = {0, 0, ::GetSystemMetrics(SM_CXSCREEN),
                    ::GetSystemMetrics(SM_CYSCREEN)};
  ::SystemParametersInfoW(SPI_GETWORKAREA, 0, &work_area, 0);

  const int work_width = work_area.right - work_area.left;
  const int work_height = work_area.bottom - work_area.top;

  // Keep default size comfortable, but always fit in visible work area so the
  // title-bar buttons stay reachable on small screens.
  const int desired_width = 1280;
  const int desired_height = 820;
  const int width_margin = 24;
  const int height_margin = 24;
  const int min_width = std::min(900, work_width);
  const int min_height = std::min(620, work_height);
  const int max_width = std::max(min_width, work_width - width_margin);
  const int max_height = std::max(min_height, work_height - height_margin);

  const int window_width = std::max(min_width, std::min(desired_width, max_width));
  const int window_height =
      std::max(min_height, std::min(desired_height, max_height));

  const int window_x =
      work_area.left + std::max(0, (work_width - window_width) / 2);
  const int window_y =
      work_area.top + std::max(0, (work_height - window_height) / 2);

  Win32Window::Point origin(window_x, window_y);
  Win32Window::Size size(window_width, window_height);
  if (!window.Create(L"ALMA CRM", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
