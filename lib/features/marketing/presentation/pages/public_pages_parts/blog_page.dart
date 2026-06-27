part of '../public_pages.dart';

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
