import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alma_desktop/features/global/presentation/controllers/global_controller.dart';
import 'core/config/app_routes.dart';
import 'core/config/desktop_window.dart';
import 'core/lang/languages.dart';

import 'core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppDesktopLayout.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return GetBuilder<GlobalController>(
          builder: (global) {
            return GetMaterialApp(
              debugShowCheckedModeBanner: false,
              getPages: AppRoutes.routes,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: global.themeMode,
              translations: Languages(),
              locale: GlobalController.to.currentLocale,
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: GlobalController.to.supportedLocales,
              initialRoute: AppRoutes.splash,
            );
          },
        );
      },
    );
  }
}
