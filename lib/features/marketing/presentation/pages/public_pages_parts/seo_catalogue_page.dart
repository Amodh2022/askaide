part of '../public_pages.dart';

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
