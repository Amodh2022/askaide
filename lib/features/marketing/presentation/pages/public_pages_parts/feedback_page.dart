part of '../public_pages.dart';

/// `/feedback` — a working feedback form (name, email, message, rating).
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and feedback are required.')));
      return;
    }
    setState(() => _submitting = true);
    var ok = true;
    try {
      await sl<Dio>().post(Endpoints.feedback, data: {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'feedback': _message.text.trim(),
        if (_rating > 0) 'rating': _rating,
      });
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Thank you for your feedback!' : 'Failed to record feedback.')));
    if (ok) {
      _name.clear();
      _email.clear();
      _message.clear();
      setState(() => _rating = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _PublicPage(
      maxWidth: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(eyebrow: 'FEEDBACK', title: 'Tell us', emphasis: 'more.'),
          const SizedBox(height: 24),
          _input(c, 'Your name', _name, 'Enter your name'),
          const SizedBox(height: 14),
          _input(c, 'Email', _email, 'your@email.com'),
          const SizedBox(height: 14),
          _input(c, 'Message', _message,
              "Tell us what's on your mind... What do you love? What could be better?",
              maxLines: 5),
          const SizedBox(height: 14),
          Text('RATING', style: AppTypography.mono(c.textMuted, size: 10)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(filled ? LucideIcons.star : LucideIcons.star,
                    color: filled ? c.accentSecondary : c.border, size: 24),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: c.textPrimary, foregroundColor: c.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              child: Text(_submitting ? 'Sending…' : 'Send feedback',
                  style: AppTypography.button(c.bgPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(AskAideColors c, String label, TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTypography.bodyLarge(c.textPrimary),
          cursorColor: c.accent,
          decoration: InputDecoration(
            filled: true,
            fillColor: c.bgCard,
            hintText: hint,
            hintStyle: AppTypography.bodyMedium(c.textMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.cardR, borderSide: BorderSide(color: c.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.cardR, borderSide: BorderSide(color: c.accent)),
          ),
        ),
      ],
    );
  }
}
