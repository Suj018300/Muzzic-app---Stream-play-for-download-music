import 'package:client/core/theme/app_pallet.dart';
import 'package:flutter/material.dart';

class AuthGradientButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onTap;

  const AuthGradientButton({
    super.key,
    required this.buttonText,
    required this.onTap
    });

  @override
  Widget build(BuildContext context) {
    return Container( 
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Pallete.gradient1, Pallete.gradient2],
        ),
        borderRadius: BorderRadius.circular(10),
      ),

      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          fixedSize: Size(395, 55),
          backgroundColor: Pallete.transparentColor,
          shadowColor: Pallete.transparentColor,
        ),
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            // color: 
          ),
          ),
      ),
    );
  }
}
