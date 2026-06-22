import 'package:equatable/equatable.dart';

/// A blog article. The frontend ships posts as static content (blogData.js);
/// we mirror that with a small curated set so the blog renders real articles.
class BlogPost extends Equatable {
  const BlogPost({
    required this.slug,
    required this.title,
    required this.category,
    required this.excerpt,
    required this.readTime,
    required this.author,
    required this.body,
  });

  final String slug;
  final String title;
  final String category;
  final String excerpt;
  final String readTime;
  final String author;
  final String body; // markdown-ish plain text

  @override
  List<Object?> get props => [slug, title, category, excerpt, readTime, author, body];
}

/// Curated launch articles.
const List<BlogPost> kBlogPosts = [
  BlogPost(
    slug: 'practice-beats-watching',
    title: 'Why ten minutes of practice beats an hour of videos',
    category: 'Learning Science',
    excerpt:
        'Active recall and spaced practice move knowledge into long-term memory far faster than passive watching.',
    readTime: '4 min read',
    author: 'AskAide',
    body:
        'Watching a video feels productive, but recognition is not recall. When you answer a '
        'question, your brain reconstructs the idea from scratch — and that effort is exactly '
        "what builds durable memory.\n\nAskAide asks one question at a time, adapts to your "
        'level, and gives instant feedback so every minute is active. Ten focused minutes a '
        'day, done consistently, outperforms marathon cram sessions.',
  ),
  BlogPost(
    slug: 'adaptive-difficulty',
    title: 'How adaptive difficulty keeps you in the productive zone',
    category: 'Product',
    excerpt:
        'Too easy is boring, too hard is discouraging. Adaptive practice keeps you right at the edge of your ability.',
    readTime: '3 min read',
    author: 'AskAide',
    body:
        'Learning happens fastest at the edge of what you can do. AskAide tracks your accuracy '
        'in real time and nudges difficulty up or down so you are always challenged but never '
        'overwhelmed — the so-called "desirable difficulty" that research links to faster mastery.',
  ),
  BlogPost(
    slug: 'building-a-study-streak',
    title: 'The quiet power of a daily study streak',
    category: 'Habits',
    excerpt:
        'Streaks turn studying from a decision into a default. Here is how to build one that lasts.',
    readTime: '5 min read',
    author: 'AskAide',
    body:
        'Motivation is unreliable; habits are not. A streak gives you a tiny, visible reason to '
        'show up each day. Start with a goal you cannot fail — five questions — and let '
        'consistency compound. Miss a day? The streak freeze has your back. Show up again tomorrow.',
  ),
];

BlogPost? blogPostBySlug(String slug) {
  for (final p in kBlogPosts) {
    if (p.slug == slug) return p;
  }
  return null;
}
