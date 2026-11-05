import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
          )
          else
            const Icon(
              Icons.g_mobiledata_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          const SizedBox(width: 10),
          Text(
            isLoading
              ? 'Connecting...'
              : 'Continue with Google',
          ),
        ],
      ),
    );
  }
}