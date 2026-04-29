import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WelcomeLogo extends StatelessWidget {
  const WelcomeLogo({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final logoSize = size ?? 96.r;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Image.asset(
            'assets/images/paro_logo.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'PARO Cüzdan',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
