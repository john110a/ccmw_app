import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'config/theme.dart';

class CCMWApp extends StatelessWidget {
  const CCMWApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean City & Municipal Watch',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.splash,
      routes: Routes.allRoutes,
    );
  }
}