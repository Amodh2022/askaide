import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/brand_logo.dart';

/// Cold-start holding screen shown while the persisted auth token is checked.
/// Keeps the sign-in page from flashing before an already-authenticated user
/// is redirected into the app.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bgPrimary,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(size: 40),
            // SizedBox(
            //   width: 22,
            //   height: 22,
            //   child: CircularProgressIndicator(strokeWidth: 2.5, color: c.accent),
            // ),
          ],
        ),
      ),
    );
  }
}
