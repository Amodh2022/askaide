import 'package:equatable/equatable.dart';

/// Selectable items in the StudyConfig funnel: Class → Subject → Chapter →
/// Topic. Kept as a single small family of value objects.

class ClassOption extends Equatable {
  const ClassOption({required this.id, required this.name});
  final String id;
  final String name;
  @override
  List<Object?> get props => [id, name];
}

class SubjectOption extends Equatable {
  const SubjectOption({required this.id, required this.name, this.classId});
  final String id;
  final String name;
  final String? classId;
  @override
  List<Object?> get props => [id, name, classId];
}

class ChapterOption extends Equatable {
  const ChapterOption({
    required this.id,
    required this.name,
    this.number,
    this.subjectId,
    this.comingSoon = false,
    this.isStartable = true,
  });
  final String id;
  final String name;
  final int? number;
  final String? subjectId;
  final bool comingSoon;
  /// False when the backend marks the chapter as not yet startable (e.g. no
  /// questions generated). The chapter is shown in the list but cannot be
  /// selected.
  final bool isStartable;
  @override
  List<Object?> get props => [id, name, number, subjectId, comingSoon, isStartable];
}

class TopicOption extends Equatable {
  const TopicOption({required this.id, required this.name, this.chapterId});
  final String id;
  final String name;
  final String? chapterId;
  @override
  List<Object?> get props => [id, name, chapterId];
}
