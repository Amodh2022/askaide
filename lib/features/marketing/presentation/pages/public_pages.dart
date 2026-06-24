import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/network/api_helpers.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../question_paper/data/question_paper_feature.dart';
import '../../../question_paper/presentation/pages/question_paper_pages.dart';
import '../../data/blog_data.dart';

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

/// `/try` — guest practice teaser (three free questions).
class TryNowPage extends StatelessWidget {
  const TryNowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _PublicPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            eyebrow: 'FREE TRIAL',
            title: 'Try three',
            emphasis: 'questions.',
            subtitle: 'No account needed. Pick a chapter and feel the difference.',
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: context.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready when you are', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Start a free session — we\'ll ask one question at a time and adapt to you.',
                    style: AppTypography.bodyMedium(c.textMuted)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(RoutePaths.signup),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent, foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                  child: const Text('Start free practice →'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `/for-schools` — B2B landing: hero, benefits grid, CTA.
class ForSchoolsPage extends StatelessWidget {
  const ForSchoolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const benefits = [
      ['01', 'Daily habit', 'Ten-minute sessions students actually finish.'],
      ['02', 'Measurable', '15–25% score improvement by week six.'],
      ['03', 'Mobile-first', 'Works on ₹8K phones, 80% cached offline.'],
      ['04', 'Zero IT overhead', 'CSV onboarding, no installs, no servers.'],
    ];
    return _PublicPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            eyebrow: 'FOR PRINCIPALS & HEADS OF SCHOOL',
            title: 'A daily habit,',
            emphasis: 'measurable.',
            subtitle: 'Adaptive practice that lifts outcomes — at ₹200/student/year.',
          ),
          const SizedBox(height: 24),
          // Content-height cards in a responsive grid (2 cols when wide, else 1)
          // so nothing overflows in portrait or landscape.
          LayoutBuilder(builder: (context, cons) {
            final cols = cons.maxWidth > 520 ? 2 : 1;
            const gap = 12.0;
            final cardWidth = (cons.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final b in benefits)
                  SizedBox(
                    width: cols == 1 ? cons.maxWidth : cardWidth,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: context.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(b[0], style: AppTypography.mono(c.accent, size: 11)),
                          const SizedBox(height: 6),
                          Text(b[1],
                              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(b[2], style: AppTypography.bodySmall(c.textMuted)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openSchoolDemoWhatsApp,
            icon: const Icon(LucideIcons.messageCircle, size: 18, color: Colors.white),
            label: Text('Book a demo on WhatsApp', style: AppTypography.button(Colors.white)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

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
                borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: c.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: c.accent)),
          ),
        ),
      ],
    );
  }
}

/// `/blog` — content hub listing the curated articles.
class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _PublicPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            eyebrow: 'ASKAIDE BLOG',
            title: 'Learning insights &',
            emphasis: 'study guides.',
          ),
          const SizedBox(height: 24),
          for (final post in kBlogPosts)
            GestureDetector(
              onTap: () => context.go('/blog/${post.slug}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: context.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.category.toUpperCase(),
                        style: AppTypography.mono(c.accent, size: 10)),
                    const SizedBox(height: 8),
                    Text(post.title,
                        style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 19)),
                    const SizedBox(height: 6),
                    Text(post.excerpt, style: AppTypography.bodyMedium(c.textMuted)),
                    const SizedBox(height: 10),
                    Text('${post.author} • ${post.readTime}',
                        style: AppTypography.bodySmall(c.textMuted).copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `/blog/:slug` — a single article.
class BlogPostPage extends StatelessWidget {
  const BlogPostPage({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final post = blogPostBySlug(slug);
    return _PublicPage(
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.go(RoutePaths.blog),
            child: Text('← Blog', style: AppTypography.bodySmall(c.textMuted)),
          ),
          const SizedBox(height: 16),
          if (post == null) ...[
            Text('Article not found',
                style: AppTypography.h2(c.textPrimary).copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text('This post may have moved.', style: AppTypography.bodyMedium(c.textMuted)),
          ] else ...[
            Text(post.category.toUpperCase(), style: AppTypography.mono(c.accent, size: 10)),
            const SizedBox(height: 8),
            Text(post.title, style: AppTypography.h1(c.textPrimary).copyWith(fontSize: 34)),
            const SizedBox(height: 12),
            Text('${post.author} • ${post.readTime}',
                style: AppTypography.bodySmall(c.textMuted)),
            const SizedBox(height: 24),
            for (final para in post.body.split('\n\n'))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(para, style: AppTypography.bodyLarge(c.textSecondary)),
              ),
          ],
        ],
      ),
    );
  }
}

/// `/privacy-policy` and `/terms-of-service` share a sectioned legal layout.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.eyebrow});
  final String title;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _PublicPage(
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(eyebrow: eyebrow, title: title),
          const SizedBox(height: 24),
          for (var i = 1; i <= 4; i++) ...[
            Text('$i. Section heading',
                style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Placeholder legal copy. The full text is provided by AskAide and rendered '
              'here in clear, readable sections.',
              style: AppTypography.bodyMedium(c.textSecondary),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

/// `/class/:classId/subject/:subjectId` and the chapter variant — SEO pages.
class SeoCataloguePage extends StatelessWidget {
  const SeoCataloguePage({super.key, required this.title, this.isChapter = false});
  final String title;
  final bool isChapter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _PublicPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            eyebrow: 'CATALOGUE',
            title: isChapter ? 'Chapter' : 'Subject',
            emphasis: 'overview.',
            subtitle: title,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(RoutePaths.tryNow),
            style: FilledButton.styleFrom(
              backgroundColor: c.accent, foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
            child: const Text('Practice this →'),
          ),
        ],
      ),
    );
  }
}

/// `/student/:userId` — shareable public achievement card.
/// Holds the public, non-sensitive stats shown on a shareable profile card.
class _PublicProfileData {
  _PublicProfileData({
    required this.name,
    required this.accountType,
    required this.questions,
    required this.accuracy,
    required this.subjects,
    required this.currentStreak,
    required this.longestStreak,
  });
  final String name;
  final String accountType;
  final int questions;
  final double accuracy; // 0..100
  final int subjects;
  final int currentStreak;
  final int longestStreak;
}

class StudentPublicProfilePage extends StatefulWidget {
  const StudentPublicProfilePage({super.key, required this.userId});
  final String userId;
  @override
  State<StudentPublicProfilePage> createState() => _StudentPublicProfilePageState();
}

class _StudentPublicProfilePageState extends State<StudentPublicProfilePage> {
  _PublicProfileData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<dynamic, dynamic>> _get(String path) async {
    try {
      final res = await sl<Dio>().get(path);
      return res.dataMap();
    } catch (_) {
      return const {};
    }
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _get('/profile/public/${widget.userId}'),
      _get(Endpoints.streak(widget.userId)),
      _get(Endpoints.userProgress(widget.userId)),
    ]);
    final profile = results[0];
    final streak = results[1];
    final progress = results[2];
    final acc = progress['overallAccuracy'] is Map ? progress['overallAccuracy'] as Map : const {};
    if (!mounted) return;
    setState(() {
      _loading = false;
      _data = _PublicProfileData(
        name: profile.str(['name', 'userName'], 'AskAide Student'),
        accountType: profile.str(['accountType', 'role']),
        questions: acc.intval(['totalCount']),
        accuracy: acc.dbl(['accuracyPercent']),
        subjects: progress.listAt(['subjects', 'subjectsProgress']).length,
        currentStreak: streak.intval(['currentStreak']),
        longestStreak: streak.intval(['longestStreak']),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = _data;
    return _PublicPage(
      maxWidth: 560,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: context.cardDecoration(),
        child: _loading
            ? const Shimmer(
                child: Column(
                  children: [
                    SkeletonBox(width: 72, height: 72, radius: 36),
                    SizedBox(height: 16),
                    SkeletonBox(width: 180, height: 16),
                    SizedBox(height: 12),
                    SkeletonBox(width: 240, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 200, height: 12),
                  ],
                ),
              )
            : Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: c.accentLight,
                    child: Text(
                      (d?.name.isNotEmpty ?? false) ? d!.name[0].toUpperCase() : 'A',
                      style: AppTypography.statNumber(c.accent, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(d?.name ?? 'AskAide Student', style: AppTypography.h3(c.textPrimary)),
                  if ((d?.accountType ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: c.accentLight, borderRadius: BorderRadius.circular(99)),
                      child: Text(d!.accountType.toUpperCase(), style: AppTypography.mono(c.accent, size: 9)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _PubStat(value: '${d?.questions ?? 0}', label: 'QUESTIONS'),
                      _PubStat(
                          value: (d == null || d.questions == 0) ? '—' : '${d.accuracy.round()}%',
                          label: 'ACCURACY'),
                      _PubStat(value: '🔥 ${d?.currentStreak ?? 0}', label: 'STREAK'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _PubStat(value: '🏆 ${d?.longestStreak ?? 0}', label: 'BEST STREAK'),
                      _PubStat(value: '${d?.subjects ?? 0}', label: 'SUBJECTS'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '/student/${widget.userId}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile link copied!')));
                    },
                    icon: Icon(LucideIcons.share2, size: 16, color: c.textPrimary),
                    label: Text('Share profile', style: AppTypography.button(c.textPrimary)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: c.border)),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PubStat extends StatelessWidget {
  const _PubStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.statNumber(c.accent, size: 26)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.mono(c.textMuted, size: 9)),
        ],
      ),
    );
  }
}

/// `/free-paper-generator` — real guest paper generation (lead magnet).
/// A two-step flow (Class & Subject → Chapters) generates a sample paper via the
/// public endpoint, then captures the lead's details before letting them
/// download the PDF. Mirrors React's PublicPaperGenerator.
class PublicPaperGeneratorPage extends StatelessWidget {
  const PublicPaperGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PublicQpCubit>(
      create: (_) => sl<PublicQpCubit>()..init(),
      child: const _PublicPaperGeneratorView(),
    );
  }
}

class _PublicPaperGeneratorView extends StatefulWidget {
  const _PublicPaperGeneratorView();
  @override
  State<_PublicPaperGeneratorView> createState() => _PublicPaperGeneratorViewState();
}

class _PublicPaperGeneratorViewState extends State<_PublicPaperGeneratorView> {
  bool _downloading = false;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _onNext(PublicQpState s) {
    final cubit = context.read<PublicQpCubit>();
    if (s.step == 1) {
      if (!s.step1Valid) {
        _snack('Please select a class and subject.');
        return;
      }
      cubit.next();
    } else if (s.step == 2) {
      if (!s.step2Valid) {
        _snack('Please select at least one chapter.');
        return;
      }
      cubit.generate();
    }
  }

  Future<void> _download(PublicQpState s) async {
    if (!s.leadValid) {
      _snack('Please enter your name, school and a valid email/WhatsApp.');
      return;
    }
    final paper = s.paper;
    if (paper == null) return;
    setState(() => _downloading = true);
    try {
      await printPaperPdf(paper);
      _snack('PDF ready.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PublicQpCubit, PublicQpState>(
      listenWhen: (p, n) => p.error != n.error && n.error != null,
      listener: (context, state) => _snack(state.error!),
      builder: (context, state) {
        return _PublicPage(
          child: state.stage == PubGenStage.ready
              ? _readyView(context, state)
              : _setupView(context, state),
        );
      },
    );
  }

  // ---- Setup (steps 1 & 2) -------------------------------------------------
  Widget _setupView(BuildContext context, PublicQpState s) {
    final c = context.colors;
    final cubit = context.read<PublicQpCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          eyebrow: 'FREE PAPER GENERATOR · CBSE · ICSE · STATE',
          title: 'A paper in',
          emphasis: 'seconds.',
          subtitle:
              'Select class, subject and chapters. AI builds the paper — MCQs, '
              'fill-in-the-blanks, answer key included. No account needed.',
        ),
        const SizedBox(height: 20),
        _PubStepIndicator(current: s.step, steps: const ['Class & Subject', 'Chapters']),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.step == 1) ...[
                Text('SELECT CLASS', style: AppTypography.mono(c.textMuted, size: 10)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    for (final cls in s.classes)
                      ChoiceChip(
                        label: Text(cls.name),
                        selected: s.classId == cls.id,
                        onSelected: (_) => cubit.selectClass(cls.id),
                        selectedColor: c.accentLight,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('SELECT SUBJECT', style: AppTypography.mono(c.textMuted, size: 10)),
                const SizedBox(height: 8),
                if (s.classId == null)
                  Text('Select a class first.', style: AppTypography.bodySmall(c.textMuted))
                else
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      for (final sub in s.subjects)
                        ChoiceChip(
                          label: Text(sub.name),
                          selected: s.subjectId == sub.id,
                          onSelected: (_) => cubit.selectSubject(sub.id),
                          selectedColor: c.accentLight,
                        ),
                    ],
                  ),
              ],
              if (s.step == 2) ...[
                Row(
                  children: [
                    Text('SELECT CHAPTERS', style: AppTypography.mono(c.textMuted, size: 10)),
                    const Spacer(),
                    if (s.chapters.isNotEmpty)
                      TextButton(
                        onPressed: cubit.selectAllChapters,
                        child: Text(
                          s.chapterIds.length == s.chapters.length
                              ? 'Deselect all'
                              : 'Select all',
                          style: AppTypography.bodySmall(c.accent),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (s.chapters.isEmpty)
                  Text('No chapters available for this subject yet.',
                      style: AppTypography.bodySmall(c.textMuted))
                else
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      for (final ch in s.chapters)
                        FilterChip(
                          label: Text(ch.name),
                          selected: s.chapterIds.contains(ch.id),
                          onSelected: (_) => cubit.toggleChapter(ch.id),
                          selectedColor: c.accentLight,
                          checkmarkColor: c.accent,
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                Text('DEMO — 10 questions · MCQ & fill-in-blank · answer key included',
                    style: AppTypography.mono(c.textMuted, size: 9)),
              ],
              const SizedBox(height: 20),
              Divider(color: c.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (s.step > 1)
                    OutlinedButton.icon(
                      onPressed: cubit.back,
                      icon: const Icon(LucideIcons.chevronLeft, size: 16),
                      label: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: s.generating ? null : () => _onNext(s),
                    icon: s.generating
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(s.step < 2 ? LucideIcons.chevronRight : LucideIcons.fileText, size: 16),
                    label: Text(s.generating
                        ? 'Generating…'
                        : (s.step < 2 ? 'Continue' : 'Generate paper')),
                    style: FilledButton.styleFrom(
                        backgroundColor: c.accent, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Ready (lead capture + download) -------------------------------------
  Widget _readyView(BuildContext context, PublicQpState s) {
    final c = context.colors;
    final cubit = context.read<PublicQpCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          eyebrow: 'PAPER READY',
          title: 'Your paper is',
          emphasis: 'ready.',
          subtitle: '10 questions · answer key included.',
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('YOUR DETAILS · TO DOWNLOAD',
                  style: AppTypography.mono(c.textMuted, size: 10)),
              const SizedBox(height: 12),
              _PubTextField(hint: 'Full name', onChanged: cubit.setName),
              const SizedBox(height: 10),
              _PubTextField(hint: 'School name', onChanged: cubit.setSchoolName),
              const SizedBox(height: 10),
              _PubTextField(
                  hint: 'WhatsApp number or email', onChanged: cubit.setContactInfo),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.lock, size: 12, color: c.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text("No spam. We'll send a backup to your contact.",
                        style: AppTypography.mono(c.textMuted, size: 9)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _downloading ? null : () => _download(s),
                icon: _downloading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.download, size: 16),
                label: Text(_downloading ? 'Preparing PDF…' : 'Download PDF'),
                style: FilledButton.styleFrom(
                    backgroundColor: c.textPrimary,
                    foregroundColor: c.bgPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FOR SCHOOLS', style: AppTypography.mono(c.textMuted, size: 10)),
              const SizedBox(height: 8),
              Text('One account. Unlimited papers.',
                  style: AppTypography.h3(c.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Teacher dashboard, difficulty control, saved history and '
                'class-level analytics.',
                style: AppTypography.bodyMedium(c.textMuted),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => context.go(RoutePaths.signup),
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent, foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
                child: const Text('Create school account →'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PubStepIndicator extends StatelessWidget {
  const _PubStepIndicator({required this.current, required this.steps});
  final int current;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: context.cardDecoration(),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: current == i + 1 ? c.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      (i + 1) < current ? LucideIcons.circleCheck : LucideIcons.circle,
                      size: 16,
                      color: current == i + 1
                          ? Colors.white
                          : ((i + 1) < current ? c.success : c.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(steps[i],
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(
                              current == i + 1 ? Colors.white : c.textMuted)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PubTextField extends StatelessWidget {
  const _PubTextField({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      onChanged: onChanged,
      style: AppTypography.bodyLarge(c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium(c.textMuted),
        filled: true,
        fillColor: c.bgRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: c.border),
        ),
      ),
    );
  }
}
