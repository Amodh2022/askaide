part of '../role_dashboard_pages.dart';

class _TeacherAiGeneratorPageState extends State<TeacherAiGeneratorPage> {
  final _prompt = TextEditingController();
  String? _answer;
  bool _loading = false;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (_prompt.text.trim().isEmpty) return;
    setState(() { _loading = true; _answer = null; });
    final r = await sl<AiTeacherToolsRepository>().ask(_prompt.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _answer = r.fold((f) => 'Error: ${f.message}', (a) => a);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                  eyebrow: 'TEACHER', title: 'AI', emphasis: 'generator.',
                  subtitle: 'Ask the assistant to generate questions, notes, or explanations.'),
              const SizedBox(height: 20),
              TextField(
                controller: _prompt,
                maxLines: 4,
                style: AppTypography.bodyLarge(c.textPrimary),
                cursorColor: c.accent,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.bgCard,
                  hintText: 'e.g. Generate 5 medium MCQs on photosynthesis',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.cardR, borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.cardR, borderSide: BorderSide(color: c.accent)),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _go,
                style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
                child: Text(_loading ? 'Generating…' : 'Generate'),
              ),
              if (_answer != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: context.cardDecoration(),
                  child: MarkdownBody(data: _answer!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
