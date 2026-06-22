import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_colors.dart';

/// WhatsApp FAB shown bottom-right on public pages. Opens a wa.me deep link.
/// Phone/message mirror the frontend's FloatingWhatsAppButton.
class WhatsAppFab extends StatelessWidget {
  const WhatsAppFab({
    super.key,
    this.phone = '9189489800367',
    this.message =
        "Hi! I'm interested in AskAide for our school. Can we schedule a demo?",
  });

  final String phone;
  final String message;

  Future<void> _open() async {
    // Launch directly rather than gating on canLaunchUrl: on Android 11+ the
    // query check can return a false negative, and launchUrl throws if it
    // genuinely can't resolve a handler (caught below).
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No handler / launch failed — nothing actionable to do here.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FloatingActionButton(
      heroTag: 'whatsapp_fab',
      backgroundColor: c.success,
      onPressed: _open,
      child: const Icon(LucideIcons.messageCircle, color: Colors.white),
    );
  }
}
