import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

ThemeData darkThemeData() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
      primary: Colors.indigo,
      secondary: Colors.tealAccent[700],
    ),
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
      headlineLarge: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
      labelLarge: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 14.sp),
      bodyMedium: TextStyle(fontSize: 12.sp),
      bodySmall: TextStyle(fontSize: 10.sp),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      contentPadding: EdgeInsets.all(16.r),
    ),
  );
}
