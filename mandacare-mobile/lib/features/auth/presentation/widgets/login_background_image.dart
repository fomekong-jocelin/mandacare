import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class LoginBackgroundImage extends StatelessWidget {
  const LoginBackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/brand/login_background.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.48, 0.72, 1],
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.02),
                AppColors.lightBackground.withValues(alpha: 0.78),
                AppColors.lightBackground.withValues(alpha: 0.96),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
