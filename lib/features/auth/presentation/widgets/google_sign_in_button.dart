import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget { 
  final VoidCallback? onPressed; 
  final bool isLoading; 
 
  const GoogleSignInButton({super.key, this.onPressed, this.isLoading = false}); 
 
  @override 
  Widget build(BuildContext context) { 
    final theme = Theme.of(context);
    
    return SizedBox( 
      width: double.infinity, 
      height: 52, 
      child: OutlinedButton( 
        onPressed: isLoading ? null : onPressed, 
        style: OutlinedButton.styleFrom( 
          backgroundColor: theme.colorScheme.surface, 
          side: BorderSide(color: theme.dividerColor), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
        ), 
        child: isLoading 
            ? const SizedBox( 
                width: 20, height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2), 
              ) 
            : Row( 
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Image.asset('assets/icons/google_logo.png', width: 24, height: 24), 
                  const SizedBox(width: 12), 
                  Text( 
                    'Lanjutkan dengan Google', 
                    style: TextStyle( 
                      fontSize: 16, 
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface, 
                    ), 
                  ), 
                ], 
              ), 
      ), 
    ); 
  } 
}