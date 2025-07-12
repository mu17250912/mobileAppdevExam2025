import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const GoogleSignInButton({Key? key, this.onPressed, this.loading = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          elevation: 0,
        ),
        onPressed: loading ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Image.network(
              'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
              height: 22,
              width: 22,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Sign in with Google',
                style: const TextStyle(
                  color: Color(0xFF3C4043),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: 'Roboto',
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (loading) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3C4043))),
              ),
            ]
          ],
        ),
      ),
    );
  }
} 