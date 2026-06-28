import 'package:equatable/equatable.dart';

import '../../../core/network/api_helpers.dart';

/// A class option (with its subjects) from `/study/configuration`.
class ClassConfig extends Equatable {
  const ClassConfig(
      {required this.id, required this.name, required this.subjects});
  final String id;
  final String name;
  final List<SubjectOption> subjects;

  factory ClassConfig.fromJson(Map<dynamic, dynamic> j) => ClassConfig(
        id: j.str(['_id', 'id']),
        name: j.str(['name', 'className'], 'Class'),
        subjects: j
            .listAt(['subjects'])
            .whereType<Map>()
            .map(SubjectOption.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [id, name, subjects];
}

class SubjectOption extends Equatable {
  const SubjectOption(
      {required this.id, required this.name, this.chapters = const []});
  final String id;
  final String name;

  /// Chapters as listed by `/study/configuration` — the only source that
  /// carries [ConfigChapter.isStartable] (the per-subject topic-progress payload
  /// does not), so the Progress page reads startability from here.
  final List<ConfigChapter> chapters;

  factory SubjectOption.fromJson(Map<dynamic, dynamic> j) => SubjectOption(
        id: j.str(['_id', 'id']),
        name: j.str(['name', 'subjectName'], 'Subject'),
        chapters: j
            .listAt(['chapters'])
            .whereType<Map>()
            .map(ConfigChapter.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [id, name, chapters];
}

/// A chapter as listed by `/study/configuration`, carrying the [isStartable]
/// flag that gates whether a practice session can be started for it.
class ConfigChapter extends Equatable {
  const ConfigChapter(
      {required this.id, required this.name, required this.isStartable});
  final String id;
  final String name;
  final bool isStartable;

  factory ConfigChapter.fromJson(Map<dynamic, dynamic> j) => ConfigChapter(
        id: j.str(['_id', 'id', 'chapterId']),
        name: j.str(['name', 'chapterName'], 'Chapter'),
        isStartable: j['isStartable'] == true,
      );

  @override
  List<Object?> get props => [id, name, isStartable];
}

/// A topic row inside a chapter detail view.
class TopicItem extends Equatable {
  const TopicItem({
    required this.topicId,
    required this.name,
    required this.state,
    required this.masteryScore,
    this.lastPracticedAt,
  });
  final String topicId;
  final String name;
  final String state; // NOT_STARTED | WEAK | LEARNING | STRONG
  final double masteryScore; // 0..1
  final DateTime? lastPracticedAt;

  factory TopicItem.fromJson(Map<dynamic, dynamic> j) => TopicItem(
        topicId: j.str(['topicId', '_id', 'id']),
        name: j.str(['topicName', 'name'], 'Topic'),
        state: j.str(['state'], 'NOT_STARTED'),
        masteryScore: j.dbl(['masteryScore']),
        lastPracticedAt: DateTime.tryParse(j.str(['lastPracticedAt'])),
      );

  @override
  List<Object?> get props =>
      [topicId, name, state, masteryScore, lastPracticedAt];
}

/// A chapter row with coverage + mastery + topic counts.
class ChapterProgress extends Equatable {
  const ChapterProgress({
    required this.chapterId,
    required this.name,
    required this.order,
    required this.status,
    required this.totalTopics,
    required this.attemptedTopics,
    required this.coveragePercent,
    required this.masteryScore,
    required this.topics,
  });
  final String chapterId;
  final String name;
  final int order;
  final String status; // NOT_STARTED | IN_PROGRESS | ...
  final int totalTopics;
  final int attemptedTopics;
  final double coveragePercent; // 0..100
  final double masteryScore; // 0..1
  final List<TopicItem> topics;

  factory ChapterProgress.fromJson(Map<dynamic, dynamic> j) => ChapterProgress(
        chapterId: j.str(['chapterId', '_id', 'id']),
        name: j.str(['name', 'chapterName'], 'Chapter'),
        order: j.intval(['order']),
        status: j.str(['status'], 'NOT_STARTED'),
        totalTopics: j.intval(['totalTopics']),
        attemptedTopics: j.intval(['attemptedTopics']),
        coveragePercent: j.dbl(['coveragePercentage', 'coverage']),
        masteryScore: j.dbl(['masteryScore', 'mastery']),
        topics: j
            .listAt(['topics'])
            .whereType<Map>()
            .map(TopicItem.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [
        chapterId,
        name,
        order,
        status,
        totalTopics,
        attemptedTopics,
        coveragePercent,
        masteryScore,
        topics
      ];
}

/// The full topic-progress payload for a subject.
class SubjectProgressData extends Equatable {
  const SubjectProgressData({
    required this.subjectId,
    required this.subjectCoverage,
    required this.subjectMastery,
    required this.chapterBreakdown,
    required this.chapters,
  });
  final String subjectId;
  final double subjectCoverage; // 0..100
  final double subjectMastery; // 0..1
  final Map<String, int> chapterBreakdown; // status -> count
  final List<ChapterProgress> chapters;

  factory SubjectProgressData.fromJson(Map<dynamic, dynamic> j) {
    final bd =
        j['chapterBreakdown'] is Map ? j['chapterBreakdown'] as Map : const {};
    return SubjectProgressData(
      subjectId: j.str(['subjectId']),
      subjectCoverage: j.dbl(['subjectCoverage']),
      subjectMastery: j.dbl(['subjectMastery']),
      chapterBreakdown: {
        for (final k in [
          'not_started',
          'weak',
          'needs_revision',
          'good',
          'strong'
        ])
          k: (bd[k] is num ? (bd[k] as num).toInt() : 0),
      },
      chapters: j
          .listAt(['chapters'])
          .whereType<Map>()
          .map(ChapterProgress.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [subjectId, subjectCoverage, subjectMastery, chapterBreakdown, chapters];
}
