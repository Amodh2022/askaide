import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/api_helpers.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/taxonomy/taxonomy_repository.dart';

class PaperQuestion extends Equatable {
  const PaperQuestion({
    required this.text,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.questionType = '',
    this.difficulty = '',
  });
  final String text;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String questionType;
  final String difficulty;

  factory PaperQuestion.fromJson(Map<dynamic, dynamic> j) => PaperQuestion(
        text: j.str(['questionText', 'text']),
        options: j.listAt(['options']).map((e) => e.toString()).toList(),
        correctAnswer: j.str(['correctAnswer']),
        explanation: j.str(['explanation']),
        questionType: j.str(['questionType', 'type']),
        difficulty: j.str(['difficulty']),
      );

  @override
  List<Object?> get props =>
      [text, options, correctAnswer, explanation, questionType, difficulty];
}

class PaperPreview extends Equatable {
  const PaperPreview({
    this.id = '',
    this.title = '',
    this.questions = const [],
    this.schoolName = '',
    this.examName = '',
    this.className = '',
    this.subjectName = '',
    this.duration = 0,
    this.totalMarks = 0,
    this.includeAnswerKey = true,
    this.instructions = const [],
  });
  final String id;
  final String title;
  final List<PaperQuestion> questions;
  final String schoolName;
  final String examName;
  final String className;
  final String subjectName;
  final int duration;
  final int totalMarks;
  final bool includeAnswerKey;
  final List<String> instructions;

  static String _refName(dynamic v) => v is Map ? (v['name']?.toString() ?? '') : '';

  factory PaperPreview.fromJson(Map<dynamic, dynamic> j) {
    final cfg = j['config'];
    return PaperPreview(
      id: j.str(['_id', 'id']),
      title: j.str(['title'], 'Question Paper'),
      questions:
          j.listAt(['questions']).whereType<Map>().map(PaperQuestion.fromJson).toList(),
      schoolName: j.str(['schoolName']),
      examName: j.str(['examName']),
      className: _refName(j['classId']),
      subjectName: _refName(j['subjectId']),
      duration: j.intval(['duration']),
      totalMarks: j.intval(['totalMarks']),
      includeAnswerKey: cfg is Map ? cfg['includeAnswerKey'] != false : true,
      instructions:
          j.listAt(['instructions']).map((e) => e.toString()).toList(),
    );
  }

  @override
  List<Object?> get props => [
        id, title, questions, schoolName, examName, className, subjectName,
        duration, totalMarks, includeAnswerKey, instructions,
      ];
}

class PaperSummary extends Equatable {
  const PaperSummary({
    required this.id,
    required this.title,
    required this.questionCount,
    this.createdAt,
    this.className = '',
    this.subjectName = '',
    this.totalMarks = 0,
    this.duration = 0,
  });
  final String id;
  final String title;
  final int questionCount;
  final String? createdAt;
  final String className;
  final String subjectName;
  final int totalMarks;
  final int duration;

  static String _refName(dynamic v) {
    if (v is Map) return v['name']?.toString() ?? '';
    return '';
  }

  factory PaperSummary.fromJson(Map<dynamic, dynamic> j) {
    final cfg = j['config'];
    final cfgQ = cfg is Map ? (cfg['totalQuestions'] as num?)?.toInt() : null;
    final qIds = j['questionIds'];
    return PaperSummary(
      id: j.str(['_id', 'id']),
      title: j.str(['title'], 'Question Paper'),
      questionCount: cfgQ ??
          (qIds is List
              ? qIds.length
              : j.intval(['questionCount', 'numberOfQuestions'])),
      createdAt: j['createdAt']?.toString(),
      className: _refName(j['classId']),
      subjectName: _refName(j['subjectId']),
      totalMarks: j.intval(['totalMarks']),
      duration: j.intval(['duration']),
    );
  }

  @override
  List<Object?> get props =>
      [id, title, questionCount, createdAt, className, subjectName, totalMarks, duration];
}

class QuestionPaperRepository {
  QuestionPaperRepository(this._dio);
  final Dio _dio;

  String pdfUrl(String paperId) =>
      '${AppConstants.apiBaseUrl}${Endpoints.questionPaperPdfUrl(paperId)}';

  Future<Either<Failure, ({List<PaperSummary> papers, int total, int totalPages})>>
      history({int page = 1, int limit = 10}) => guardEither(() async {
        final res = await _dio.get(
          Endpoints.questionPaperHistoryPath,
          queryParameters: {'page': page, 'limit': limit},
        );
        final body = res.dataMap();
        final pg = body['pagination'] is Map
            ? Map<dynamic, dynamic>.from(body['pagination'] as Map)
            : const <dynamic, dynamic>{};
        final papers = res
            .dataList(['data', 'papers'])
            .whereType<Map>()
            .map(PaperSummary.fromJson)
            .toList();
        final total = pg.intval(['total']);
        final totalPages = pg.intval(['totalPages']);
        return (
          papers: papers,
          total: total,
          totalPages: totalPages > 0 ? totalPages : 1,
        );
      });

  Future<Either<Failure, PaperPreview>> preview(String paperId) => guardEither(() async {
        final res = await _dio.get(Endpoints.questionPaperPreview(paperId));
        return PaperPreview.fromJson(res.dataMap());
      });

  Future<Either<Failure, String>> generate(Map<String, dynamic> body) =>
      guardEither(() async {
        final res = await _dio.post(Endpoints.questionPaper, data: body);
        return res.dataMap().str(['_id', 'id', 'paperId']);
      });

  Future<Either<Failure, Unit>> deletePaper(String paperId) =>
      guardEither(() async {
        await _dio.delete(Endpoints.questionPaperDelete(paperId));
        return unit;
      });

  /// Guest/public generation (lead magnet). Returns the full paper payload so
  /// the caller can render a PDF without authentication. Mirrors React's
  /// `generatePublicPaper({ leadParams, paperParams })`.
  Future<Either<Failure, PaperPreview>> generatePublic(
          Map<String, dynamic> body) =>
      guardEither(() async {
        final res = await _dio.post(Endpoints.questionPaperPublicGenerate, data: body);
        return PaperPreview.fromJson(res.dataMap());
      });
}

enum QpLoad { initial, loading, loaded, error }

class PaperPreviewState extends Equatable {
  const PaperPreviewState({this.status = QpLoad.initial, this.preview, this.error});
  final QpLoad status;
  final PaperPreview? preview;
  final String? error;

  PaperPreviewState copyWith({QpLoad? status, PaperPreview? preview, String? error}) =>
      PaperPreviewState(
          status: status ?? this.status, preview: preview ?? this.preview, error: error);

  @override
  List<Object?> get props => [status, preview, error];
}

class PaperPreviewCubit extends Cubit<PaperPreviewState> {
  PaperPreviewCubit(this._repo) : super(const PaperPreviewState());
  final QuestionPaperRepository _repo;

  Future<void> load(String paperId) async {
    emit(state.copyWith(status: QpLoad.loading));
    final r = await _repo.preview(paperId);
    r.fold(
      (f) => emit(state.copyWith(status: QpLoad.error, error: f.message)),
      (p) => emit(state.copyWith(status: QpLoad.loaded, preview: p)),
    );
  }
}

class PaperHistoryState extends Equatable {
  const PaperHistoryState({
    this.status = QpLoad.initial,
    this.papers = const [],
    this.page = 1,
    this.total = 0,
    this.totalPages = 1,
    this.error,
  });
  final QpLoad status;
  final List<PaperSummary> papers;
  final int page;
  final int total;
  final int totalPages;
  final String? error;

  PaperHistoryState copyWith({
    QpLoad? status,
    List<PaperSummary>? papers,
    int? page,
    int? total,
    int? totalPages,
    String? error,
  }) =>
      PaperHistoryState(
        status: status ?? this.status,
        papers: papers ?? this.papers,
        page: page ?? this.page,
        total: total ?? this.total,
        totalPages: totalPages ?? this.totalPages,
        error: error,
      );

  @override
  List<Object?> get props => [status, papers, page, total, totalPages, error];
}

class PaperHistoryCubit extends Cubit<PaperHistoryState> {
  PaperHistoryCubit(this._repo) : super(const PaperHistoryState());
  final QuestionPaperRepository _repo;

  Future<void> load({int page = 1}) async {
    emit(state.copyWith(status: QpLoad.loading));
    final r = await _repo.history(page: page);
    r.fold(
      (f) => emit(state.copyWith(status: QpLoad.error, error: f.message)),
      (result) => emit(state.copyWith(
        status: QpLoad.loaded,
        papers: result.papers,
        page: page,
        total: result.total,
        totalPages: result.totalPages,
        error: null,
      )),
    );
  }

  /// Deletes a paper and removes it from the list optimistically on success.
  Future<bool> delete(String paperId) async {
    final r = await _repo.deletePaper(paperId);
    return r.fold((_) => false, (_) {
      emit(state.copyWith(
          papers: state.papers.where((p) => p.id != paperId).toList()));
      return true;
    });
  }
}

// ---- Generator (taxonomy pickers + generate) ------------------------------

class QpGenState extends Equatable {
  const QpGenState({
    this.step = 1,
    this.classes = const [],
    this.subjects = const [],
    this.chapters = const [],
    this.classId,
    this.subjectId,
    this.chapterIds = const {},
    this.title = '',
    this.schoolName = '',
    this.examName = 'Examination',
    this.duration = 60,
    this.easy = 3,
    this.medium = 4,
    this.hard = 3,
    this.questionTypes = const {'mcq'},
    this.includeAnswerKey = true,
    this.instructions = const [],
    this.generating = false,
    this.generatedPaperId,
    this.error,
  });

  final int step;
  final List<TaxItem> classes;
  final List<TaxItem> subjects;
  final List<TaxItem> chapters;
  final String? classId;
  final String? subjectId;
  final Set<String> chapterIds;
  final String title;
  final String schoolName;
  final String examName;
  final int duration;
  final int easy;
  final int medium;
  final int hard;
  final Set<String> questionTypes;
  final bool includeAnswerKey;
  final List<String> instructions;
  final bool generating;
  final String? generatedPaperId;
  final String? error;

  int get totalQuestions => easy + medium + hard;
  int get estimatedMarks => easy * 1 + medium * 2 + hard * 3;

  /// Step 1 is valid once a title, subject and class are chosen.
  bool get step1Valid =>
      title.trim().isNotEmpty && classId != null && subjectId != null;

  /// Step 2 is valid once chapters are picked and at least one question is set.
  bool get step2Valid => chapterIds.isNotEmpty && totalQuestions >= 1;

  bool get canGenerate => step1Valid && step2Valid && !generating;

  QpGenState copyWith({
    int? step,
    List<TaxItem>? classes,
    List<TaxItem>? subjects,
    List<TaxItem>? chapters,
    String? classId,
    String? subjectId,
    Set<String>? chapterIds,
    String? title,
    String? schoolName,
    String? examName,
    int? duration,
    int? easy,
    int? medium,
    int? hard,
    Set<String>? questionTypes,
    bool? includeAnswerKey,
    List<String>? instructions,
    bool? generating,
    String? generatedPaperId,
    String? error,
    bool clearSubject = false,
    bool clearChapters = false,
  }) =>
      QpGenState(
        step: step ?? this.step,
        classes: classes ?? this.classes,
        subjects: subjects ?? this.subjects,
        chapters: chapters ?? this.chapters,
        classId: classId ?? this.classId,
        subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
        chapterIds: clearChapters ? const {} : (chapterIds ?? this.chapterIds),
        title: title ?? this.title,
        schoolName: schoolName ?? this.schoolName,
        examName: examName ?? this.examName,
        duration: duration ?? this.duration,
        easy: easy ?? this.easy,
        medium: medium ?? this.medium,
        hard: hard ?? this.hard,
        questionTypes: questionTypes ?? this.questionTypes,
        includeAnswerKey: includeAnswerKey ?? this.includeAnswerKey,
        instructions: instructions ?? this.instructions,
        generating: generating ?? this.generating,
        generatedPaperId: generatedPaperId,
        error: error,
      );

  @override
  List<Object?> get props => [
        step, classes, subjects, chapters, classId, subjectId, chapterIds,
        title, schoolName, examName, duration, easy, medium, hard,
        questionTypes, includeAnswerKey, instructions,
        generating, generatedPaperId, error,
      ];
}

class QpGeneratorCubit extends Cubit<QpGenState> {
  QpGeneratorCubit(this._papers, this._tax) : super(const QpGenState());
  final QuestionPaperRepository _papers;
  final TaxonomyRepository _tax;

  Future<void> init() async {
    final r = await _tax.classes();
    emit(state.copyWith(classes: r.getOrElse(() => const [])));
  }

  Future<void> selectClass(String classId) async {
    emit(state.copyWith(
        classId: classId, subjects: const [], chapters: const [],
        clearSubject: true, clearChapters: true));
    final r = await _tax.subjects(classId);
    emit(state.copyWith(subjects: r.getOrElse(() => const [])));
  }

  Future<void> selectSubject(String subjectId) async {
    final classId = state.classId;
    if (classId == null) return;
    emit(state.copyWith(subjectId: subjectId, chapters: const [], clearChapters: true));
    final r = await _tax.chapters(classId, subjectId);
    emit(state.copyWith(chapters: r.getOrElse(() => const [])));
  }

  void toggleChapter(String id) {
    final next = Set<String>.from(state.chapterIds);
    if (!next.add(id)) next.remove(id);
    emit(state.copyWith(chapterIds: next));
  }

  void selectAllChapters() {
    if (state.chapterIds.length == state.chapters.length) {
      emit(state.copyWith(chapterIds: const {}));
    } else {
      emit(state.copyWith(chapterIds: state.chapters.map((c) => c.id).toSet()));
    }
  }

  void setTitle(String v) => emit(state.copyWith(title: v));
  void setSchoolName(String v) => emit(state.copyWith(schoolName: v));
  void setExamName(String v) => emit(state.copyWith(examName: v));
  void setDuration(int v) => emit(state.copyWith(duration: v));
  void setEasy(int v) => emit(state.copyWith(easy: v < 0 ? 0 : v));
  void setMedium(int v) => emit(state.copyWith(medium: v < 0 ? 0 : v));
  void setHard(int v) => emit(state.copyWith(hard: v < 0 ? 0 : v));
  void setAnswerKey(bool v) => emit(state.copyWith(includeAnswerKey: v));

  void toggleType(String type) {
    final next = Set<String>.from(state.questionTypes);
    if (next.contains(type)) {
      if (next.length > 1) next.remove(type);
    } else {
      next.add(type);
    }
    emit(state.copyWith(questionTypes: next));
  }

  void addInstruction(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    emit(state.copyWith(instructions: [...state.instructions, t]));
  }

  void removeInstruction(int index) {
    final next = [...state.instructions]..removeAt(index);
    emit(state.copyWith(instructions: next));
  }

  void goToStep(int step) => emit(state.copyWith(step: step.clamp(1, 3)));
  void next() => emit(state.copyWith(step: (state.step + 1).clamp(1, 3)));
  void back() => emit(state.copyWith(step: (state.step - 1).clamp(1, 3)));

  Future<void> generate() async {
    if (!state.canGenerate) return;
    emit(state.copyWith(generating: true, error: null));
    final r = await _papers.generate({
      'title': state.title,
      'classId': state.classId,
      'subjectId': state.subjectId,
      'chapterIds': state.chapterIds.toList(),
      'config': {
        'totalQuestions': state.totalQuestions,
        'difficultyMix': {
          'easy': state.easy,
          'medium': state.medium,
          'hard': state.hard,
        },
        'questionTypes': state.questionTypes.toList(),
        'includeAnswerKey': state.includeAnswerKey,
      },
      'duration': state.duration,
      'schoolName': state.schoolName,
      'examName': state.examName,
      'instructions': state.instructions,
    });
    r.fold(
      (f) => emit(state.copyWith(generating: false, error: f.message)),
      (paperId) => emit(state.copyWith(generating: false, generatedPaperId: paperId)),
    );
  }
}

// ---- Public/guest generator -----------------------------------------------

enum PubGenStage { setup, ready }

class PublicQpState extends Equatable {
  const PublicQpState({
    this.step = 1,
    this.stage = PubGenStage.setup,
    this.classes = const [],
    this.subjects = const [],
    this.chapters = const [],
    this.classId,
    this.subjectId,
    this.chapterIds = const {},
    this.name = '',
    this.schoolName = '',
    this.contactInfo = '',
    this.generating = false,
    this.paper,
    this.error,
  });

  final int step;
  final PubGenStage stage;
  final List<TaxItem> classes;
  final List<TaxItem> subjects;
  final List<TaxItem> chapters;
  final String? classId;
  final String? subjectId;
  final Set<String> chapterIds;
  final String name;
  final String schoolName;
  final String contactInfo;
  final bool generating;
  final PaperPreview? paper;
  final String? error;

  bool get step1Valid => classId != null && subjectId != null;
  bool get step2Valid => chapterIds.isNotEmpty;
  bool get leadValid =>
      name.trim().isNotEmpty &&
      schoolName.trim().isNotEmpty &&
      contactInfo.trim().length >= 5;

  PublicQpState copyWith({
    int? step,
    PubGenStage? stage,
    List<TaxItem>? classes,
    List<TaxItem>? subjects,
    List<TaxItem>? chapters,
    String? classId,
    String? subjectId,
    Set<String>? chapterIds,
    String? name,
    String? schoolName,
    String? contactInfo,
    bool? generating,
    PaperPreview? paper,
    String? error,
    bool clearSubject = false,
    bool clearChapters = false,
  }) =>
      PublicQpState(
        step: step ?? this.step,
        stage: stage ?? this.stage,
        classes: classes ?? this.classes,
        subjects: subjects ?? this.subjects,
        chapters: chapters ?? this.chapters,
        classId: classId ?? this.classId,
        subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
        chapterIds: clearChapters ? const {} : (chapterIds ?? this.chapterIds),
        name: name ?? this.name,
        schoolName: schoolName ?? this.schoolName,
        contactInfo: contactInfo ?? this.contactInfo,
        generating: generating ?? this.generating,
        paper: paper ?? this.paper,
        error: error,
      );

  @override
  List<Object?> get props => [
        step, stage, classes, subjects, chapters, classId, subjectId,
        chapterIds, name, schoolName, contactInfo, generating, paper, error,
      ];
}

class PublicQpCubit extends Cubit<PublicQpState> {
  PublicQpCubit(this._papers, this._tax) : super(const PublicQpState());
  final QuestionPaperRepository _papers;
  final TaxonomyRepository _tax;

  Future<void> init() async {
    final r = await _tax.classes();
    emit(state.copyWith(classes: r.getOrElse(() => const [])));
  }

  Future<void> selectClass(String classId) async {
    emit(state.copyWith(
        classId: classId, subjects: const [], chapters: const [],
        clearSubject: true, clearChapters: true));
    final r = await _tax.subjects(classId);
    emit(state.copyWith(subjects: r.getOrElse(() => const [])));
  }

  Future<void> selectSubject(String subjectId) async {
    final classId = state.classId;
    if (classId == null) return;
    emit(state.copyWith(subjectId: subjectId, chapters: const [], clearChapters: true));
    final r = await _tax.chapters(classId, subjectId);
    emit(state.copyWith(chapters: r.getOrElse(() => const [])));
  }

  void toggleChapter(String id) {
    final next = Set<String>.from(state.chapterIds);
    if (!next.add(id)) next.remove(id);
    emit(state.copyWith(chapterIds: next));
  }

  void selectAllChapters() {
    if (state.chapterIds.length == state.chapters.length) {
      emit(state.copyWith(chapterIds: const {}));
    } else {
      emit(state.copyWith(chapterIds: state.chapters.map((c) => c.id).toSet()));
    }
  }

  void setName(String v) => emit(state.copyWith(name: v));
  void setSchoolName(String v) => emit(state.copyWith(schoolName: v));
  void setContactInfo(String v) => emit(state.copyWith(contactInfo: v));

  void next() => emit(state.copyWith(step: (state.step + 1).clamp(1, 2)));
  void back() => emit(state.copyWith(step: (state.step - 1).clamp(1, 2)));

  String _name(List<TaxItem> list, String? id) =>
      list.firstWhere((e) => e.id == id, orElse: () => const TaxItem(id: '', name: '')).name;

  Future<void> generate() async {
    if (!state.step1Valid || !state.step2Valid) return;
    emit(state.copyWith(generating: true, error: null));
    final className = _name(state.classes, state.classId);
    final subjectName = _name(state.subjects, state.subjectId);
    const total = 10;
    final r = await _papers.generatePublic({
      'leadParams': {
        'name': state.name,
        'schoolName': state.schoolName,
        'contactInfo': state.contactInfo,
      },
      'paperParams': {
        'title': '$className $subjectName Assessment',
        'classId': state.classId,
        'subjectId': state.subjectId,
        'chapterIds': state.chapterIds.toList(),
        'config': {
          'totalQuestions': total,
          'difficultyMix': {
            'easy': (total * 0.4).ceil(),
            'medium': (total * 0.4).ceil(),
            'hard': (total * 0.2).floor(),
          },
          'questionTypes': ['mcq', 'fillblanks'],
          'includeAnswerKey': true,
        },
        'schoolName': state.schoolName,
        'duration': 45,
      },
    });
    r.fold(
      (f) => emit(state.copyWith(generating: false, error: f.message)),
      (paper) => emit(state.copyWith(
          generating: false, paper: paper, stage: PubGenStage.ready, step: 3)),
    );
  }
}
