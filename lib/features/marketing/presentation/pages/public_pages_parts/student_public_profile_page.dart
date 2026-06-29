part of '../public_pages.dart';

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
                      decoration: BoxDecoration(color: c.accentLight, borderRadius: AppRadii.pillR),
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
