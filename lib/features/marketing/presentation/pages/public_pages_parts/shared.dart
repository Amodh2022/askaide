part of '../public_pages.dart';

/// Opens the school-demo WhatsApp chat (mirrors the frontend's ForSchools CTA).
Future<void> _openSchoolDemoWhatsApp() async {
  const phone = '9189489800367';
  const message =
      "Hi! I'm interested in AskAide for our school. Can we schedule a demo?";
  final uri =
      Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // No handler / launch failed — nothing actionable to surface here.
  }
}

/// Shared scrolling container constrained to a readable column.
class _PublicPage extends StatelessWidget {
  const _PublicPage({required this.child, this.maxWidth = 880});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
