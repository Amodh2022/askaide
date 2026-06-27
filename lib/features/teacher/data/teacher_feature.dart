import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/api_helpers.dart';
import '../../../core/network/endpoints.dart';

// ---- Helper ----------------------------------------------------------------

double _frac(double v) => v > 1 ? v / 100 : v;

// ---- Assignment models -----------------------------------------------------

class AssignmentSection extends Equatable {
  const AssignmentSection({required this.sectionId, required this.name, this.studentCount = 0});
  final String sectionId;
  final String name;
  final int studentCount;

  factory AssignmentSection.fromJson(Map<dynamic, dynamic> j) => AssignmentSection(
        sectionId: j.str(['sectionId', '_id', 'id']),
        name: j.str(['name', 'sectionName']),
        studentCount: j.intval(['studentCount', 'students']),
      );

  @override
  List<Object?> get props => [sectionId, name, studentCount];
}

class AssignmentClass extends Equatable {
  const AssignmentClass({required this.classId, required this.className, this.sections = const [], this.totalStudents = 0});
  final String classId;
  final String className;
  final List<AssignmentSection> sections;
  final int totalStudents;

  factory AssignmentClass.fromJson(Map<dynamic, dynamic> j) => AssignmentClass(
        classId: j.str(['classId', '_id', 'id']),
        className: j.str(['className', 'name']),
        sections: j.listAt(['sections']).whereType<Map>().map(AssignmentSection.fromJson).toList(),
        totalStudents: j.intval(['totalStudents', 'studentCount']),
      );

  @override
  List<Object?> get props => [classId, className, sections, totalStudents];
}

class TeacherAssignment extends Equatable {
  const TeacherAssignment({
    required this.subjectId,
    required this.subjectName,
    this.classes = const [],
    this.totalStudents = 0,
  });
  final String subjectId;
  final String subjectName;
  final List<AssignmentClass> classes;
  final int totalStudents;

  String get classLabel {
    final names = classes.map((c) => c.className).where((s) => s.isNotEmpty).toList();
    return names.join(', ');
  }

  factory TeacherAssignment.fromJson(Map<dynamic, dynamic> j) {
    final classList = j.listAt(['classes']).whereType<Map>().map(AssignmentClass.fromJson).toList();
    return TeacherAssignment(
      subjectId: j.str(['subjectId', '_id', 'id']),
      subjectName: j.str(['subjectName', 'name'], 'Subject'),
      classes: classList,
      totalStudents: j.intval(['totalStudents', 'studentCount']),
    );
  }

  @override
  List<Object?> get props => [subjectId, subjectName, classes, totalStudents];
}

class TeacherAssignmentsData extends Equatable {
  const TeacherAssignmentsData({
    this.teacherName = '',
    this.schoolName = '',
    this.assignments = const [],
    this.totalStudentsAcrossSubjects = 0,
  });
  final String teacherName;
  final String schoolName;
  final List<TeacherAssignment> assignments;
  final int totalStudentsAcrossSubjects;

  factory TeacherAssignmentsData.fromJson(Map<dynamic, dynamic> j) {
    final teacher = j['teacher'] is Map ? j['teacher'] as Map : const {};
    return TeacherAssignmentsData(
      teacherName: teacher.str(['name']),
      schoolName: j.str(['schoolName']),
      assignments: j.listAt(['assignments']).whereType<Map>().map(TeacherAssignment.fromJson).toList(),
      totalStudentsAcrossSubjects: j.intval(['totalStudentsAcrossSubjects']),
    );
  }

  @override
  List<Object?> get props => [teacherName, schoolName, assignments, totalStudentsAcrossSubjects];
}

// ---- Subject Dashboard models -----------------------------------------------

class ChapterProgress extends Equatable {
  const ChapterProgress({
    required this.chapterId,
    required this.name,
    required this.order,
    this.status = '',
    this.classAvgMastery = 0,
    this.studentsCompleted = 0,
    this.studentsInProgress = 0,
    this.studentsNotStarted = 0,
  });
  final String chapterId;
  final String name;
  final int order;
  final String status;
  final double classAvgMastery; // 0..1
  final int studentsCompleted;
  final int studentsInProgress;
  final int studentsNotStarted;

  factory ChapterProgress.fromJson(Map<dynamic, dynamic> j) => ChapterProgress(
        chapterId: j.str(['chapterId', '_id', 'id']),
        name: j.str(['name', 'chapterName'], 'Chapter'),
        order: j.intval(['order']),
        status: j.str(['status']),
        classAvgMastery: _frac(j.dbl(
            ['classAvgMastery', 'avgMastery', 'avgClassMastery', 'masteryScore', 'mastery'])),
        studentsCompleted: j.intval(['studentsCompleted', 'completed']),
        studentsInProgress: j.intval(['studentsInProgress', 'inProgress']),
        studentsNotStarted: j.intval(['studentsNotStarted', 'notStarted']),
      );

  @override
  List<Object?> get props => [chapterId, name, order, status, classAvgMastery];
}

class TopWeakTopicItem extends Equatable {
  const TopWeakTopicItem({required this.topicId, required this.name, required this.chapterName, this.studentsWeak = 0});
  final String topicId;
  final String name;
  final String chapterName;
  final int studentsWeak;

  factory TopWeakTopicItem.fromJson(Map<dynamic, dynamic> j) => TopWeakTopicItem(
        topicId: j.str(['topicId', '_id', 'id']),
        name: j.str(['name', 'topicName'], 'Topic'),
        chapterName: j.str(['chapterName', 'chapter']),
        studentsWeak: j.intval(['studentsWeak', 'studentCount']),
      );

  @override
  List<Object?> get props => [topicId, name, chapterName, studentsWeak];
}

class ClassSummaryItem extends Equatable {
  const ClassSummaryItem({required this.className, required this.sectionName, this.avgMastery = 0, this.studentCount = 0});
  final String className;
  final String sectionName;
  final double avgMastery; // 0..1
  final int studentCount;

  factory ClassSummaryItem.fromJson(Map<dynamic, dynamic> j) => ClassSummaryItem(
        className: j.str(['className', 'name']),
        sectionName: j.str(['sectionName', 'section']),
        avgMastery: _frac(j.dbl(['avgMastery', 'mastery'])),
        studentCount: j.intval(['studentCount', 'students']),
      );

  @override
  List<Object?> get props => [className, sectionName, avgMastery, studentCount];
}

class SubjectDashboard extends Equatable {
  const SubjectDashboard({
    this.subjectName = '',
    this.totalStudents = 0,
    this.activeThisWeek = 0,
    this.avgMastery = 0,
    this.avgCoverage = 0,
    this.studentsNeedingHelp = 0,
    this.chapterProgress = const [],
    this.topWeakTopics = const [],
    this.classSummary = const [],
  });
  final String subjectName;
  final int totalStudents;
  final int activeThisWeek;
  final double avgMastery; // 0..1
  final double avgCoverage; // 0..1 or 0..100 stored as fraction
  final int studentsNeedingHelp;
  final List<ChapterProgress> chapterProgress;
  final List<TopWeakTopicItem> topWeakTopics;
  final List<ClassSummaryItem> classSummary;

  factory SubjectDashboard.fromJson(Map<dynamic, dynamic> j) {
    final subject = j['subject'] is Map ? j['subject'] as Map : const {};
    final o = j['overview'] is Map ? j['overview'] as Map : j;
    return SubjectDashboard(
      subjectName: subject.str(['name']).isNotEmpty
          ? subject.str(['name'])
          : j.str(['subjectName', 'name']),
      totalStudents: o.intval(['totalStudents', 'studentCount']),
      activeThisWeek: o.intval(['activeThisWeek']),
      avgMastery: _frac(o.dbl(['avgSubjectMastery', 'avgMastery', 'mastery'])),
      avgCoverage: _frac(o.dbl(['avgSubjectCoverage', 'avgCoverage', 'coverage'])),
      studentsNeedingHelp: o.intval(['studentsNeedingHelp', 'atRisk']),
      chapterProgress: j.listAt(['chapterProgress']).whereType<Map>().map(ChapterProgress.fromJson).toList(),
      topWeakTopics: j.listAt(['topWeakTopics']).whereType<Map>().map(TopWeakTopicItem.fromJson).toList(),
      classSummary: j.listAt(['classSummary']).whereType<Map>().map(ClassSummaryItem.fromJson).toList(),
    );
  }

  @override
  List<Object?> get props => [subjectName, totalStudents, activeThisWeek, avgMastery, avgCoverage];
}

// ---- Student models --------------------------------------------------------

class StudentRow extends Equatable {
  const StudentRow({
    required this.id,
    required this.name,
    this.email = '',
    this.imageUrl,
    this.className = '',
    this.section = '',
    this.status = '',
    this.mastery = 0,
    this.coverage = 0,
    this.chaptersCompleted = 0,
    this.totalChapters = 0,
    this.weakTopicsCount = 0,
    this.lastPracticed = '',
    this.daysInactive = 0,
  });
  final String id;
  final String name;
  final String email;
  final String? imageUrl;
  final String className;
  final String section;
  final String status;
  final double mastery; // 0..1
  final double coverage; // 0..1
  final int chaptersCompleted;
  final int totalChapters;
  final int weakTopicsCount;
  final String lastPracticed; // ISO timestamp
  final int daysInactive;

  factory StudentRow.fromJson(Map<dynamic, dynamic> j) => StudentRow(
        id: j.str(['studentId', '_id', 'id']),
        name: j.str(['name', 'studentName'], 'Student'),
        email: j.str(['email']),
        imageUrl: j['image'] is String ? j['image'] as String : null,
        className: j.str(['class', 'className']),
        section: j.str(['section', 'sectionName']),
        status: j.str(['status']),
        mastery: _frac(j.dbl(['subjectMastery', 'mastery'])),
        coverage: _frac(j.dbl(['subjectCoverage', 'coverage'])),
        chaptersCompleted: j.intval(['chaptersCompleted', 'completed']),
        totalChapters: j.intval(['totalChapters']),
        weakTopicsCount: j.intval(['weakTopicsCount', 'weakTopics']),
        lastPracticed: j.str(['lastPracticed', 'lastActive']),
        daysInactive: j.intval(['daysInactive']),
      );

  @override
  List<Object?> get props => [id, name, mastery, status];
}

// ---- Student Progress models -----------------------------------------------

class StudentTopic extends Equatable {
  const StudentTopic({required this.topicId, required this.name, this.state = '', this.masteryScore = 0, this.lastPracticedAt = ''});
  final String topicId;
  final String name;
  final String state; // MASTERED, PRACTICING, LEARNING, WEAK, NOT_ATTEMPTED
  final double masteryScore; // 0..1
  final String lastPracticedAt;

  factory StudentTopic.fromJson(Map<dynamic, dynamic> j) => StudentTopic(
        topicId: j.str(['topicId', '_id', 'id']),
        name: j.str(['topicName', 'name'], 'Topic'),
        state: j.str(['state', 'masteryState', 'status']),
        masteryScore: _frac(j.dbl(['masteryScore', 'mastery'])),
        lastPracticedAt: j.str(['lastPracticedAt', 'lastPracticed']),
      );

  @override
  List<Object?> get props => [topicId, name, state, masteryScore];
}

class StudentChapterDetail extends Equatable {
  const StudentChapterDetail({
    required this.chapterId,
    required this.name,
    this.order = 0,
    this.status = '',
    this.coveragePercentage = 0,
    this.masteryScore = 0,
    this.topics = const [],
  });
  final String chapterId;
  final String name;
  final int order;
  final String status;
  final double coveragePercentage; // 0..100
  final double masteryScore; // 0..1
  final List<StudentTopic> topics;

  factory StudentChapterDetail.fromJson(Map<dynamic, dynamic> j) => StudentChapterDetail(
        chapterId: j.str(['chapterId', '_id', 'id']),
        name: j.str(['name', 'chapterName'], 'Chapter'),
        order: j.intval(['order']),
        status: j.str(['status']),
        coveragePercentage: j.dbl(['coveragePercentage', 'coverage']),
        masteryScore: _frac(j.dbl(['masteryScore', 'mastery'])),
        topics: j.listAt(['topics']).whereType<Map>().map(StudentTopic.fromJson).toList(),
      );

  @override
  List<Object?> get props => [chapterId, name, masteryScore];
}

class StudentWeakTopic extends Equatable {
  const StudentWeakTopic({required this.topicId, required this.name, required this.chapterName, this.masteryScore = 0});
  final String topicId;
  final String name;
  final String chapterName;
  final double masteryScore; // 0..1

  factory StudentWeakTopic.fromJson(Map<dynamic, dynamic> j) => StudentWeakTopic(
        topicId: j.str(['topicId', '_id', 'id']),
        name: j.str(['name', 'topicName'], 'Topic'),
        chapterName: j.str(['chapterName', 'chapter']),
        masteryScore: _frac(j.dbl(['masteryScore', 'mastery'])),
      );

  @override
  List<Object?> get props => [topicId, name, masteryScore];
}

class SubjectSummary extends Equatable {
  const SubjectSummary({
    this.subjectName = '',
    this.overallMastery = 0,
    this.overallCoverage = 0,
    this.chaptersStarted = 0,
    this.totalChapters = 0,
    this.lastActive = '',
    this.totalTimeSpent = 0,
  });
  final String subjectName;
  final double overallMastery; // 0..1
  final double overallCoverage; // 0..1
  final int chaptersStarted;
  final int totalChapters;
  final String lastActive;
  final int totalTimeSpent; // minutes

  factory SubjectSummary.fromJson(Map<dynamic, dynamic> j) => SubjectSummary(
        subjectName: j.str(['subjectName', 'name']),
        overallMastery: _frac(j.dbl(['overallMastery', 'mastery'])),
        overallCoverage: _frac(j.dbl(['overallCoverage', 'coverage'])),
        chaptersStarted: j.intval(['chaptersStarted', 'chaptersCompleted']),
        totalChapters: j.intval(['totalChapters']),
        lastActive: j.str(['lastActive', 'lastPracticed']),
        totalTimeSpent: j.intval(['totalTimeSpent', 'timeSpent']),
      );

  @override
  List<Object?> get props => [subjectName, overallMastery, overallCoverage, chaptersStarted, totalChapters];
}

class StudentProgressData extends Equatable {
  const StudentProgressData({
    this.studentName = '',
    this.studentClass = '',
    this.studentEmail = '',
    this.subjectSummary = const SubjectSummary(),
    this.chapters = const [],
    this.weakTopics = const [],
    this.recommendations = const [],
  });
  final String studentName;
  final String studentClass;
  final String studentEmail;
  final SubjectSummary subjectSummary;
  final List<StudentChapterDetail> chapters;
  final List<StudentWeakTopic> weakTopics;
  final List<String> recommendations;

  factory StudentProgressData.fromJson(Map<dynamic, dynamic> j) {
    final student = j['student'] is Map ? j['student'] as Map : const {};
    final summaryMap = j['subjectSummary'] is Map ? j['subjectSummary'] as Map : j;
    return StudentProgressData(
      studentName: student.str(['name']).isNotEmpty ? student.str(['name']) : j.str(['studentName']),
      studentClass: student.str(['class']),
      studentEmail: student.str(['email']),
      subjectSummary: SubjectSummary.fromJson(summaryMap),
      chapters: j.listAt(['chapters']).whereType<Map>().map(StudentChapterDetail.fromJson).toList(),
      weakTopics: j.listAt(['weakTopics']).whereType<Map>().map(StudentWeakTopic.fromJson).toList(),
      recommendations: j.listAt(['recommendations']).map((e) => e.toString()).toList(),
    );
  }

  @override
  List<Object?> get props => [studentName, studentEmail, subjectSummary];
}

// ---- Chapter Analytics models ---------------------------------------------

class MasteryDistribution extends Equatable {
  const MasteryDistribution({this.mastered = 0, this.practicing = 0, this.learning = 0, this.weak = 0});
  final int mastered;
  final int practicing;
  final int learning;
  final int weak;

  factory MasteryDistribution.fromJson(Map<dynamic, dynamic> j) => MasteryDistribution(
        mastered: j.intval(['MASTERED', 'mastered']),
        practicing: j.intval(['PRACTICING', 'practicing']),
        learning: j.intval(['LEARNING', 'learning']),
        weak: j.intval(['WEAK', 'weak']),
      );

  int get total => mastered + practicing + learning + weak;

  @override
  List<Object?> get props => [mastered, practicing, learning, weak];
}

class ChapterAnalyticsTopic extends Equatable {
  const ChapterAnalyticsTopic({
    required this.topicId,
    required this.name,
    this.status = '',
    this.classAvgMastery = 0,
    this.studentsAttempted = 0,
    this.studentsTotal = 0,
    this.distribution = const MasteryDistribution(),
  });
  final String topicId;
  final String name;
  final String status;
  final double classAvgMastery; // 0..1
  final int studentsAttempted;
  final int studentsTotal;
  final MasteryDistribution distribution;

  factory ChapterAnalyticsTopic.fromJson(Map<dynamic, dynamic> j) {
    final dist = j['masteryDistribution'] is Map
        ? MasteryDistribution.fromJson(j['masteryDistribution'] as Map)
        : const MasteryDistribution();
    return ChapterAnalyticsTopic(
      topicId: j.str(['topicId', '_id', 'id']),
      name: j.str(['name', 'topicName'], 'Topic'),
      status: j.str(['status']),
      classAvgMastery: _frac(j.dbl(['classAvgMastery', 'avgMastery', 'mastery'])),
      studentsAttempted: j.intval(['studentsAttempted', 'attempted']),
      studentsTotal: j.intval(['studentsTotal', 'total']),
      distribution: dist,
    );
  }

  @override
  List<Object?> get props => [topicId, name, classAvgMastery];
}

class StrugglingStudent extends Equatable {
  const StrugglingStudent({required this.studentId, required this.name, this.masteryScore = 0, this.weakTopics = 0});
  final String studentId;
  final String name;
  final double masteryScore; // 0..1
  final int weakTopics;

  factory StrugglingStudent.fromJson(Map<dynamic, dynamic> j) => StrugglingStudent(
        studentId: j.str(['studentId', '_id', 'id']),
        name: j.str(['name', 'studentName'], 'Student'),
        masteryScore: _frac(j.dbl(['masteryScore', 'mastery'])),
        weakTopics: j.intval(['weakTopics', 'weakTopicsCount']),
      );

  @override
  List<Object?> get props => [studentId, name, masteryScore];
}

class ChapterAnalytics extends Equatable {
  const ChapterAnalytics({
    this.chapterName = '',
    this.chapterOrder = 0,
    this.totalTopics = 0,
    this.avgMastery = 0,
    this.avgCoverage = 0,
    this.topics = const [],
    this.strugglingStudents = const [],
  });
  final String chapterName;
  final int chapterOrder;
  final int totalTopics;
  final double avgMastery; // 0..1
  final double avgCoverage; // 0..100 (percent)
  final List<ChapterAnalyticsTopic> topics;
  final List<StrugglingStudent> strugglingStudents;

  factory ChapterAnalytics.fromJson(Map<dynamic, dynamic> j) {
    final chapter = j['chapter'] is Map ? j['chapter'] as Map : const {};
    final o = j['overview'] is Map ? j['overview'] as Map : j;
    return ChapterAnalytics(
      chapterName: chapter.str(['name']).isNotEmpty
          ? chapter.str(['name'])
          : j.str(['chapterName', 'name']),
      chapterOrder: chapter.intval(['order']),
      totalTopics: o.intval(['totalTopics']),
      avgMastery: _frac(o.dbl(['classAvgMastery', 'avgMastery', 'mastery'])),
      avgCoverage: o.dbl(['classAvgCoverage', 'avgCoverage', 'coverage']),
      topics: j.listAt(['topics']).whereType<Map>().map(ChapterAnalyticsTopic.fromJson).toList(),
      strugglingStudents: j.listAt(['strugglingStudents']).whereType<Map>().map(StrugglingStudent.fromJson).toList(),
    );
  }

  @override
  List<Object?> get props => [chapterName, avgMastery, avgCoverage];
}

// ---- Weak Topics models ---------------------------------------------------

class DifficultyAccuracy extends Equatable {
  const DifficultyAccuracy({this.easy = 0, this.medium = 0, this.hard = 0});
  final double easy;
  final double medium;
  final double hard;

  factory DifficultyAccuracy.fromJson(Map<dynamic, dynamic> j) => DifficultyAccuracy(
        easy: _frac(j.dbl(['easyAccuracy', 'easy'])),
        medium: _frac(j.dbl(['mediumAccuracy', 'medium'])),
        hard: _frac(j.dbl(['hardAccuracy', 'hard'])),
      );

  @override
  List<Object?> get props => [easy, medium, hard];
}

class WeakTopicDetail extends Equatable {
  const WeakTopicDetail({
    required this.topicId,
    required this.name,
    required this.chapterName,
    this.teacherAction = 'MONITOR',
    this.studentsWeak = 0,
    this.totalStudents = 0,
    this.weakPercentage = 0,
    this.avgMastery = 0,
    this.difficulty = const DifficultyAccuracy(),
  });
  final String topicId;
  final String name;
  final String chapterName;
  final String teacherAction; // HIGH_PRIORITY, MEDIUM_PRIORITY, MONITOR
  final int studentsWeak;
  final int totalStudents;
  final int weakPercentage;
  final double avgMastery; // 0..1
  final DifficultyAccuracy difficulty;

  factory WeakTopicDetail.fromJson(Map<dynamic, dynamic> j) {
    final diff = j['difficulty'] is Map
        ? DifficultyAccuracy.fromJson(j['difficulty'] as Map)
        : const DifficultyAccuracy();
    return WeakTopicDetail(
      topicId: j.str(['topicId', '_id', 'id']),
      name: j.str(['name', 'topicName'], 'Topic'),
      chapterName: j.str(['chapterName', 'chapter']),
      teacherAction: j.str(['teacherAction', 'priority'], 'MONITOR'),
      studentsWeak: j.intval(['studentsWeak']),
      totalStudents: j.intval(['totalStudents']),
      weakPercentage: j.intval(['weakPercentage']),
      avgMastery: _frac(j.dbl(['avgMastery', 'mastery'])),
      difficulty: diff,
    );
  }

  @override
  List<Object?> get props => [topicId, name, teacherAction, studentsWeak];
}

class WeakTopicsData extends Equatable {
  const WeakTopicsData({this.totalWeakTopics = 0, this.topics = const [], this.classroomRecommendation = ''});
  final int totalWeakTopics;
  final List<WeakTopicDetail> topics;
  final String classroomRecommendation;

  factory WeakTopicsData.fromJson(Map<dynamic, dynamic> j) => WeakTopicsData(
        totalWeakTopics: j.intval(['totalWeakTopics', 'total']),
        topics: j.listAt(['topics']).whereType<Map>().map(WeakTopicDetail.fromJson).toList(),
        classroomRecommendation: j.str(['classroomRecommendation', 'recommendation']),
      );

  @override
  List<Object?> get props => [totalWeakTopics, topics];
}

// ---- Activity model -------------------------------------------------------

class ActivityItem extends Equatable {
  const ActivityItem({
    required this.studentName,
    this.studentImage,
    this.type = '',
    this.chapter = '',
    this.topic = '',
    this.score = 0,
    this.correctAnswers = 0,
    this.questionsAttempted = 0,
    this.timestamp = '',
  });
  final String studentName;
  final String? studentImage;
  final String type; // SESSION_COMPLETED, MASTERY_ACHIEVED, CHAPTER_STARTED
  final String chapter;
  final String topic;
  final double score; // 0..1
  final int correctAnswers;
  final int questionsAttempted;
  final String timestamp;

  factory ActivityItem.fromJson(Map<dynamic, dynamic> j) {
    final student = j['student'] is Map ? j['student'] as Map : const {};
    return ActivityItem(
      studentName: student.str(['name']).isNotEmpty
          ? student.str(['name'])
          : j.str(['studentName', 'name'], 'Student'),
      studentImage: student['image'] is String ? student['image'] as String : null,
      type: j.str(['type', 'action']),
      chapter: j.str(['chapter', 'chapterName']),
      topic: j.str(['topic', 'topicName']),
      score: _frac(j.dbl(['score'])),
      correctAnswers: j.intval(['correctAnswers']),
      questionsAttempted: j.intval(['questionsAttempted']),
      timestamp: j.str(['timestamp', 'createdAt']),
    );
  }

  String get actionLabel {
    switch (type) {
      case 'SESSION_COMPLETED':
        return 'completed a session';
      case 'MASTERY_ACHIEVED':
        return 'mastered a topic';
      case 'CHAPTER_STARTED':
        return 'started a chapter';
      default:
        return type.toLowerCase().replaceAll('_', ' ');
    }
  }

  @override
  List<Object?> get props => [studentName, type, timestamp];
}

// ---- Mock data for SuperAdmin ---------------------------------------------

class _TeacherMock {
  static const TeacherAssignmentsData assignments = TeacherAssignmentsData(
    teacherName: 'Ramesh Kumar',
    schoolName: 'Delhi Public School',
    totalStudentsAcrossSubjects: 142,
    assignments: [
      TeacherAssignment(
        subjectId: 'sub_math',
        subjectName: 'Mathematics',
        totalStudents: 67,
        classes: [
          AssignmentClass(
            classId: 'cls9',
            className: 'Class 9',
            totalStudents: 67,
            sections: [
              AssignmentSection(sectionId: 'sec1', name: 'A', studentCount: 35),
              AssignmentSection(sectionId: 'sec2', name: 'B', studentCount: 32),
            ],
          ),
        ],
      ),
      TeacherAssignment(
        subjectId: 'sub_physics',
        subjectName: 'Physics',
        totalStudents: 40,
        classes: [
          AssignmentClass(
            classId: 'cls10',
            className: 'Class 10',
            totalStudents: 40,
            sections: [AssignmentSection(sectionId: 'sec3', name: 'A', studentCount: 40)],
          ),
        ],
      ),
      TeacherAssignment(
        subjectId: 'sub_chemistry',
        subjectName: 'Chemistry',
        totalStudents: 35,
        classes: [
          AssignmentClass(
            classId: 'cls9',
            className: 'Class 9',
            totalStudents: 35,
            sections: [AssignmentSection(sectionId: 'sec1', name: 'A', studentCount: 35)],
          ),
        ],
      ),
    ],
  );

  static const SubjectDashboard subjectDashboard = SubjectDashboard(
    subjectName: 'Mathematics',
    totalStudents: 67,
    activeThisWeek: 52,
    avgMastery: 0.68,
    avgCoverage: 0.72,
    studentsNeedingHelp: 8,
    chapterProgress: [
      ChapterProgress(chapterId: 'ch1', name: 'Linear Equations', order: 1, status: 'STRONG', classAvgMastery: 0.82, studentsCompleted: 60, studentsInProgress: 5, studentsNotStarted: 2),
      ChapterProgress(chapterId: 'ch2', name: 'Quadratic Equations', order: 2, status: 'NEEDS_ATTENTION', classAvgMastery: 0.45, studentsCompleted: 10, studentsInProgress: 40, studentsNotStarted: 17),
      ChapterProgress(chapterId: 'ch3', name: 'Polynomials', order: 3, status: 'ON_TRACK', classAvgMastery: 0.58, studentsCompleted: 25, studentsInProgress: 30, studentsNotStarted: 12),
      ChapterProgress(chapterId: 'ch4', name: 'Triangles', order: 4, status: 'NOT_STARTED', classAvgMastery: 0, studentsCompleted: 0, studentsInProgress: 0, studentsNotStarted: 67),
      ChapterProgress(chapterId: 'ch5', name: 'Circles', order: 5, status: 'STRONG', classAvgMastery: 0.71, studentsCompleted: 45, studentsInProgress: 15, studentsNotStarted: 7),
    ],
    topWeakTopics: [
      TopWeakTopicItem(topicId: 't1', name: 'Discriminant', chapterName: 'Quadratic Equations', studentsWeak: 25),
      TopWeakTopicItem(topicId: 't2', name: 'Factorization', chapterName: 'Polynomials', studentsWeak: 18),
      TopWeakTopicItem(topicId: 't3', name: 'Word Problems', chapterName: 'Linear Equations', studentsWeak: 12),
    ],
    classSummary: [
      ClassSummaryItem(className: 'Class 9', sectionName: 'A', avgMastery: 0.72, studentCount: 35),
      ClassSummaryItem(className: 'Class 9', sectionName: 'B', avgMastery: 0.64, studentCount: 32),
    ],
  );

  static const List<StudentRow> studentsList = [
    StudentRow(id: 'stu1', name: 'Priya Singh', email: 'priya@school.com', className: 'Class 9', section: 'A', status: 'NEEDS_HELP', mastery: 0.32, coverage: 0.45, chaptersCompleted: 2, totalChapters: 5, weakTopicsCount: 4, lastPracticed: '2026-06-20'),
    StudentRow(id: 'stu2', name: 'Rahul Sharma', email: 'rahul@school.com', className: 'Class 9', section: 'B', status: 'STRONG', mastery: 0.91, coverage: 0.88, chaptersCompleted: 4, totalChapters: 5, weakTopicsCount: 0, lastPracticed: '2026-06-23'),
    StudentRow(id: 'stu3', name: 'Anika Patel', email: 'anika@school.com', className: 'Class 9', section: 'A', status: 'ON_TRACK', mastery: 0.67, coverage: 0.72, chaptersCompleted: 3, totalChapters: 5, weakTopicsCount: 1, lastPracticed: '2026-06-21'),
    StudentRow(id: 'stu4', name: 'Vijay Kumar', email: 'vijay@school.com', className: 'Class 9', section: 'B', status: 'NEEDS_REVISION', mastery: 0.48, coverage: 0.60, chaptersCompleted: 3, totalChapters: 5, weakTopicsCount: 3, lastPracticed: '2026-06-15'),
    StudentRow(id: 'stu5', name: 'Sneha Gupta', email: 'sneha@school.com', className: 'Class 9', section: 'A', status: 'INACTIVE', mastery: 0.55, coverage: 0.50, chaptersCompleted: 2, totalChapters: 5, weakTopicsCount: 2, lastPracticed: '2026-06-01'),
  ];

  static const StudentProgressData studentProgress = StudentProgressData(
    studentName: 'Priya Singh',
    studentClass: 'Class 9',
    studentEmail: 'priya@school.com',
    subjectSummary: SubjectSummary(
      subjectName: 'Mathematics',
      overallMastery: 0.32,
      overallCoverage: 0.45,
      chaptersStarted: 2,
      totalChapters: 5,
      lastActive: '2026-06-20',
      totalTimeSpent: 240,
    ),
    chapters: [
      StudentChapterDetail(
        chapterId: 'ch1', name: 'Linear Equations', order: 1, status: 'MASTERED',
        coveragePercentage: 100, masteryScore: 0.82,
        topics: [
          StudentTopic(topicId: 'tp1', name: 'One Variable', state: 'MASTERED', masteryScore: 0.90, lastPracticedAt: '2026-06-18'),
          StudentTopic(topicId: 'tp2', name: 'Two Variables', state: 'PRACTICING', masteryScore: 0.74, lastPracticedAt: '2026-06-20'),
        ],
      ),
      StudentChapterDetail(
        chapterId: 'ch2', name: 'Quadratic Equations', order: 2, status: 'NEEDS_REVISION',
        coveragePercentage: 60, masteryScore: 0.41,
        topics: [
          StudentTopic(topicId: 'tp3', name: 'Factoring', state: 'WEAK', masteryScore: 0.28, lastPracticedAt: '2026-06-15'),
          StudentTopic(topicId: 'tp4', name: 'Discriminant', state: 'WEAK', masteryScore: 0.21, lastPracticedAt: '2026-06-15'),
        ],
      ),
      StudentChapterDetail(
        chapterId: 'ch3', name: 'Polynomials', order: 3, status: 'LEARNING',
        coveragePercentage: 30, masteryScore: 0.55,
        topics: [
          StudentTopic(topicId: 'tp5', name: 'Degree', state: 'PRACTICING', masteryScore: 0.65, lastPracticedAt: '2026-06-20'),
        ],
      ),
    ],
    weakTopics: [
      StudentWeakTopic(topicId: 'tp4', name: 'Discriminant', chapterName: 'Quadratic Equations', masteryScore: 0.21),
      StudentWeakTopic(topicId: 'tp3', name: 'Factoring', chapterName: 'Quadratic Equations', masteryScore: 0.28),
    ],
    recommendations: [
      'Focus on Quadratic Equations — Priya needs more practice with discriminant calculations.',
      'Encourage daily 15-minute practice sessions to build consistency.',
    ],
  );

  static const ChapterAnalytics chapterAnalytics = ChapterAnalytics(
    chapterName: 'Quadratic Equations',
    chapterOrder: 2,
    totalTopics: 4,
    avgMastery: 0.45,
    avgCoverage: 60,
    topics: [
      ChapterAnalyticsTopic(topicId: 't1', name: 'Introduction', status: 'STRONG', classAvgMastery: 0.78, studentsAttempted: 60, studentsTotal: 67),
      ChapterAnalyticsTopic(topicId: 't2', name: 'Factoring Methods', status: 'NEEDS_ATTENTION', classAvgMastery: 0.41, studentsAttempted: 45, studentsTotal: 67),
      ChapterAnalyticsTopic(topicId: 't3', name: 'Discriminant', status: 'WEAK', classAvgMastery: 0.29, studentsAttempted: 38, studentsTotal: 67),
      ChapterAnalyticsTopic(topicId: 't4', name: 'Word Problems', status: 'NEEDS_ATTENTION', classAvgMastery: 0.52, studentsAttempted: 30, studentsTotal: 67),
    ],
    strugglingStudents: [
      StrugglingStudent(studentId: 'stu1', name: 'Priya Singh', masteryScore: 0.21, weakTopics: 4),
      StrugglingStudent(studentId: 'stu4', name: 'Vijay Kumar', masteryScore: 0.35, weakTopics: 3),
    ],
  );

  static const WeakTopicsData weakTopics = WeakTopicsData(
    totalWeakTopics: 3,
    classroomRecommendation: 'Schedule a revision session focusing on Quadratic Equations next week. Consider pair work between strong and struggling students on Discriminant problems.',
    topics: [
      WeakTopicDetail(topicId: 't3', name: 'Discriminant', chapterName: 'Quadratic Equations', teacherAction: 'HIGH_PRIORITY', studentsWeak: 25, totalStudents: 67, weakPercentage: 37, avgMastery: 0.28),
      WeakTopicDetail(topicId: 't2', name: 'Factorization', chapterName: 'Polynomials', teacherAction: 'MEDIUM_PRIORITY', studentsWeak: 18, totalStudents: 67, weakPercentage: 27, avgMastery: 0.41),
      WeakTopicDetail(topicId: 't1', name: 'Word Problems', chapterName: 'Linear Equations', teacherAction: 'MONITOR', studentsWeak: 12, totalStudents: 67, weakPercentage: 18, avgMastery: 0.55),
    ],
  );

  static const List<ActivityItem> activityFeed = [
    ActivityItem(studentName: 'Rahul Sharma', type: 'SESSION_COMPLETED', chapter: 'Linear Equations', score: 0.88, correctAnswers: 14, questionsAttempted: 16, timestamp: '2026-06-24T08:30:00Z'),
    ActivityItem(studentName: 'Anika Patel', type: 'MASTERY_ACHIEVED', chapter: 'Linear Equations', topic: 'One Variable', timestamp: '2026-06-24T07:15:00Z'),
    ActivityItem(studentName: 'Vijay Kumar', type: 'CHAPTER_STARTED', chapter: 'Polynomials', timestamp: '2026-06-23T16:45:00Z'),
    ActivityItem(studentName: 'Priya Singh', type: 'SESSION_COMPLETED', chapter: 'Quadratic Equations', score: 0.45, correctAnswers: 5, questionsAttempted: 11, timestamp: '2026-06-23T14:00:00Z'),
    ActivityItem(studentName: 'Sneha Gupta', type: 'SESSION_COMPLETED', chapter: 'Polynomials', score: 0.72, correctAnswers: 9, questionsAttempted: 13, timestamp: '2026-06-23T11:30:00Z'),
  ];
}

// ---- Repository ---------------------------------------------------------------

abstract class TeacherRepository {
  Future<Either<Failure, TeacherAssignmentsData>> assignments(String teacherId);

  Future<Either<Failure, SubjectDashboard>> subjectDashboard(
      String teacherId, String subjectId);

  Future<Either<Failure, ({List<StudentRow> students, int totalCount})>> students(
      String teacherId, String subjectId,
      {String? status, String? sortBy, String? order});

  Future<Either<Failure, WeakTopicsData>> weakTopics(
      String teacherId, String subjectId,
      {String? classId, String? sectionId, double? threshold});

  Future<Either<Failure, List<ActivityItem>>> activity(
      String teacherId, String subjectId, {int limit = 20});

  Future<Either<Failure, ChapterAnalytics>> chapterAnalytics(
      String teacherId, String subjectId, String chapterId,
      {String? classId, String? sectionId});

  Future<Either<Failure, StudentProgressData>> studentProgress(
      String teacherId, String studentId, String subjectId);
}

class TeacherRepositoryImpl implements TeacherRepository {
  TeacherRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<Either<Failure, TeacherAssignmentsData>> assignments(String teacherId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.teacherAssignments(teacherId));
        return TeacherAssignmentsData.fromJson(res.dataMap());
      });

  @override
  Future<Either<Failure, SubjectDashboard>> subjectDashboard(
          String teacherId, String subjectId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.teacherSubjectDashboard(teacherId, subjectId));
        return SubjectDashboard.fromJson(res.dataMap());
      });

  @override
  Future<Either<Failure, ({List<StudentRow> students, int totalCount})>> students(
          String teacherId, String subjectId,
          {String? status, String? sortBy, String? order}) =>
      guardEither(() async {
        final res = await _dio.get(
          Endpoints.teacherStudentsList(teacherId, subjectId),
          queryParameters: {
            if (status != null && status != 'all') 'status': status,
            if (sortBy != null) 'sortBy': sortBy,
            if (order != null) 'order': order,
          },
        );
        final body = res.dataMap();
        final list = body.listAt(['students']).whereType<Map>().map(StudentRow.fromJson).toList();
        return (students: list, totalCount: body.intval(['totalCount', 'total']));
      });

  @override
  Future<Either<Failure, WeakTopicsData>> weakTopics(
          String teacherId, String subjectId,
          {String? classId, String? sectionId, double? threshold}) =>
      guardEither(() async {
        final res = await _dio.get(
          Endpoints.teacherWeakTopics(teacherId, subjectId),
          queryParameters: {
            if (classId != null) 'classId': classId,
            if (sectionId != null) 'sectionId': sectionId,
            if (threshold != null) 'threshold': threshold,
          },
        );
        return WeakTopicsData.fromJson(res.dataMap());
      });

  @override
  Future<Either<Failure, List<ActivityItem>>> activity(
          String teacherId, String subjectId, {int limit = 20}) =>
      guardEither(() async {
        final res = await _dio.get(
          Endpoints.teacherActivity(teacherId, subjectId),
          queryParameters: {'limit': limit},
        );
        return res.dataList(['activities']).whereType<Map>().map(ActivityItem.fromJson).toList();
      });

  @override
  Future<Either<Failure, ChapterAnalytics>> chapterAnalytics(
          String teacherId, String subjectId, String chapterId,
          {String? classId, String? sectionId}) =>
      guardEither(() async {
        final res = await _dio.get(
          Endpoints.teacherChapterAnalytics(teacherId, subjectId, chapterId),
          queryParameters: {
            if (classId != null) 'classId': classId,
            if (sectionId != null) 'sectionId': sectionId,
          },
        );
        return ChapterAnalytics.fromJson(res.dataMap());
      });

  @override
  Future<Either<Failure, StudentProgressData>> studentProgress(
          String teacherId, String studentId, String subjectId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.teacherStudentProgress(teacherId, studentId, subjectId));
        return StudentProgressData.fromJson(res.dataMap());
      });
}

// ---- Cubits ---------------------------------------------------------------

enum TLoad { initial, loading, loaded, error }

// Home (assignments)
class TeacherHomeState extends Equatable {
  const TeacherHomeState({this.status = TLoad.initial, this.data = const TeacherAssignmentsData(), this.error});
  final TLoad status;
  final TeacherAssignmentsData data;
  final String? error;

  TeacherHomeState copyWith({TLoad? status, TeacherAssignmentsData? data, String? error}) =>
      TeacherHomeState(status: status ?? this.status, data: data ?? this.data, error: error);

  @override
  List<Object?> get props => [status, data, error];
}

class TeacherHomeCubit extends Cubit<TeacherHomeState> {
  TeacherHomeCubit(this._repo) : super(const TeacherHomeState());
  final TeacherRepository _repo;

  Future<void> load(String teacherId, {bool mock = false}) async {
    emit(state.copyWith(status: TLoad.loading));
    if (mock) {
      emit(state.copyWith(status: TLoad.loaded, data: _TeacherMock.assignments));
      return;
    }
    if (teacherId.isEmpty) { emit(state.copyWith(status: TLoad.loaded)); return; }
    final r = await _repo.assignments(teacherId);
    r.fold(
      (f) => emit(state.copyWith(status: TLoad.error, error: f.message)),
      (d) => emit(state.copyWith(status: TLoad.loaded, data: d)),
    );
  }
}

// Subject Dashboard
class TeacherSubjectState extends Equatable {
  const TeacherSubjectState({
    this.status = TLoad.initial,
    this.dashboard = const SubjectDashboard(),
    this.error,
  });
  final TLoad status;
  final SubjectDashboard dashboard;
  final String? error;

  TeacherSubjectState copyWith({TLoad? status, SubjectDashboard? dashboard, String? error}) =>
      TeacherSubjectState(status: status ?? this.status, dashboard: dashboard ?? this.dashboard, error: error);

  @override
  List<Object?> get props => [status, dashboard, error];
}

class TeacherSubjectCubit extends Cubit<TeacherSubjectState> {
  TeacherSubjectCubit(this._repo) : super(const TeacherSubjectState());
  final TeacherRepository _repo;

  Future<void> load(String teacherId, String subjectId, {bool mock = false}) async {
    emit(state.copyWith(status: TLoad.loading));
    if (mock) {
      emit(state.copyWith(status: TLoad.loaded, dashboard: _TeacherMock.subjectDashboard));
      return;
    }
    final r = await _repo.subjectDashboard(teacherId, subjectId);
    r.fold(
      (f) => emit(state.copyWith(status: TLoad.error, error: f.message)),
      (d) => emit(state.copyWith(status: TLoad.loaded, dashboard: d)),
    );
  }
}

// Students List
class TeacherStudentsState extends Equatable {
  const TeacherStudentsState({
    this.status = TLoad.initial,
    this.students = const [],
    this.totalCount = 0,
    this.error,
  });
  final TLoad status;
  final List<StudentRow> students;
  final int totalCount;
  final String? error;

  TeacherStudentsState copyWith({TLoad? status, List<StudentRow>? students, int? totalCount, String? error}) =>
      TeacherStudentsState(
        status: status ?? this.status,
        students: students ?? this.students,
        totalCount: totalCount ?? this.totalCount,
        error: error,
      );

  @override
  List<Object?> get props => [status, students, totalCount, error];
}

class TeacherStudentsCubit extends Cubit<TeacherStudentsState> {
  TeacherStudentsCubit(this._repo) : super(const TeacherStudentsState());
  final TeacherRepository _repo;

  Future<void> load(String teacherId, String subjectId,
      {String status = 'all', String sortBy = 'mastery', String order = 'desc', bool mock = false}) async {
    emit(state.copyWith(status: TLoad.loading));
    if (mock) {
      emit(state.copyWith(status: TLoad.loaded, students: _TeacherMock.studentsList, totalCount: _TeacherMock.studentsList.length));
      return;
    }
    final r = await _repo.students(teacherId, subjectId, status: status, sortBy: sortBy, order: order);
    r.fold(
      (f) => emit(state.copyWith(status: TLoad.error, error: f.message)),
      (d) => emit(state.copyWith(status: TLoad.loaded, students: d.students, totalCount: d.totalCount)),
    );
  }
}

// Chapter Analytics
class TeacherChapterState extends Equatable {
  const TeacherChapterState({this.status = TLoad.initial, this.data = const ChapterAnalytics(), this.error});
  final TLoad status;
  final ChapterAnalytics data;
  final String? error;

  TeacherChapterState copyWith({TLoad? status, ChapterAnalytics? data, String? error}) =>
      TeacherChapterState(status: status ?? this.status, data: data ?? this.data, error: error);

  @override
  List<Object?> get props => [status, data, error];
}

class TeacherChapterCubit extends Cubit<TeacherChapterState> {
  TeacherChapterCubit(this._repo) : super(const TeacherChapterState());
  final TeacherRepository _repo;

  Future<void> load(String teacherId, String subjectId, String chapterId, {bool mock = false}) async {
    emit(state.copyWith(status: TLoad.loading));
    if (mock) {
      emit(state.copyWith(status: TLoad.loaded, data: _TeacherMock.chapterAnalytics));
      return;
    }
    final r = await _repo.chapterAnalytics(teacherId, subjectId, chapterId);
    r.fold(
      (f) => emit(state.copyWith(status: TLoad.error, error: f.message)),
      (d) => emit(state.copyWith(status: TLoad.loaded, data: d)),
    );
  }
}

// Weak Topics
class TeacherWeakTopicsState extends Equatable {
  const TeacherWeakTopicsState({this.status = TLoad.initial, this.data = const WeakTopicsData(), this.error});
  final TLoad status;
  final WeakTopicsData data;
  final String? error;

  TeacherWeakTopicsState copyWith({TLoad? status, WeakTopicsData? data, String? error}) =>
      TeacherWeakTopicsState(status: status ?? this.status, data: data ?? this.data, error: error);

  @override
  List<Object?> get props => [status, data, error];
}

class TeacherWeakTopicsCubit extends Cubit<TeacherWeakTopicsState> {
  TeacherWeakTopicsCubit(this._repo) : super(const TeacherWeakTopicsState());
  final TeacherRepository _repo;

  Future<void> load(String teacherId, String subjectId, {bool mock = false}) async {
    emit(state.copyWith(status: TLoad.loading));
    if (mock) {
      emit(state.copyWith(status: TLoad.loaded, data: _TeacherMock.weakTopics));
      return;
    }
    final r = await _repo.weakTopics(teacherId, subjectId);
    r.fold(
      (f) => emit(state.copyWith(status: TLoad.error, error: f.message)),
      (d) => emit(state.copyWith(status: TLoad.loaded, data: d)),
    );
  }
}

// Activity Feed
class TeacherActivityState extends Equatable {
  const TeacherActivityState({this.status = TLoad.initial, this.activities = const [], this.error});
  final TLoad status;
  final List<ActivityItem> activities;
  final String? error;

  TeacherActivityState copyWith({TLoad? status, List<ActivityItem>? activities, String? error}) =>
      TeacherActivityState(status: status ?? this.status, activities: activities ?? this.activities, error: error);

  @override
  List<Object?> get props => [status, activities, error];
}

class TeacherActivityCubit extends Cubit<TeacherActivityState> {
  TeacherActivityCubit(this._repo) : super(const TeacherActivityState());
  final TeacherRepository _repo;

  Future<void> load(String teacherId, String subjectId, {bool mock = false}) async {
    emit(state.copyWith(status: TLoad.loading));
    if (mock) {
      emit(state.copyWith(status: TLoad.loaded, activities: _TeacherMock.activityFeed));
      return;
    }
    final r = await _repo.activity(teacherId, subjectId);
    r.fold(
      (f) => emit(state.copyWith(status: TLoad.error, error: f.message)),
      (d) => emit(state.copyWith(status: TLoad.loaded, activities: d)),
    );
  }
}

// Student Progress
class TeacherStudentState extends Equatable {
  const TeacherStudentState({this.status = TLoad.initial, this.data = const StudentProgressData(), this.error});
  final TLoad status;
  final StudentProgressData data;
  final String? error;

  TeacherStudentState copyWith({TLoad? status, StudentProgressData? data, String? error}) =>
      TeacherStudentState(status: status ?? this.status, data: data ?? this.data, error: error);

  @override
  List<Object?> get props => [status, data, error];
}

class TeacherStudentCubit extends Cubit<TeacherStudentState> {
  TeacherStudentCubit(this._repo) : super(const TeacherStudentState());
  final TeacherRepository _repo;

  Future<void> load(String teacherId, String studentId, String subjectId, {bool mock = false}) async {
    emit(state.copyWith(status: TLoad.loading));
    if (mock) {
      emit(state.copyWith(status: TLoad.loaded, data: _TeacherMock.studentProgress));
      return;
    }
    final r = await _repo.studentProgress(teacherId, studentId, subjectId);
    r.fold(
      (f) => emit(state.copyWith(status: TLoad.error)),
      (d) => emit(state.copyWith(status: TLoad.loaded, data: d)),
    );
  }
}
