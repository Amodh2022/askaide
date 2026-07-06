import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_feature.dart';

class UploadChapterState extends Equatable {
  const UploadChapterState({
    this.classId,
    this.subjectId,
    this.subjects = const [],
    this.chapters = const [],
    this.loadingChapters = false,
    this.fileBytes,
    this.fileName,
    this.uploading = false,
  });

  final String? classId;
  final String? subjectId;
  final List<AdminRecord> subjects;
  final List<AdminRecord> chapters;
  final bool loadingChapters;
  final Uint8List? fileBytes;
  final String? fileName;
  final bool uploading;

  UploadChapterState copyWith({
    String? classId,
    String? subjectId,
    List<AdminRecord>? subjects,
    List<AdminRecord>? chapters,
    bool? loadingChapters,
    Uint8List? fileBytes,
    String? fileName,
    bool? uploading,
    bool clearFile = false,
  }) =>
      UploadChapterState(
        classId: classId ?? this.classId,
        subjectId: subjectId ?? this.subjectId,
        subjects: subjects ?? this.subjects,
        chapters: chapters ?? this.chapters,
        loadingChapters: loadingChapters ?? this.loadingChapters,
        fileBytes: clearFile ? null : (fileBytes ?? this.fileBytes),
        fileName: clearFile ? null : (fileName ?? this.fileName),
        uploading: uploading ?? this.uploading,
      );

  @override
  List<Object?> get props => [
        classId,
        subjectId,
        subjects,
        chapters,
        loadingChapters,
        fileBytes,
        fileName,
        uploading,
      ];
}

/// Owns the admin "Upload chapter" panel: class/subject cascading selection,
/// the picked PDF, the chapter name/order controllers, and the
/// upload/delete-chapter flows against [AdminRepository].
class UploadChapterCubit extends Cubit<UploadChapterState> {
  UploadChapterCubit(this._repo)
      : name = TextEditingController(),
        order = TextEditingController(),
        super(const UploadChapterState());

  final AdminRepository _repo;
  final TextEditingController name;
  final TextEditingController order;

  Future<void> selectClass(String classId) async {
    emit(UploadChapterState(classId: classId));
    final r = await _repo.subjects(classId);
    if (isClosed) return;
    emit(state.copyWith(subjects: r.getOrElse(() => const [])));
  }

  Future<void> selectSubject(String subjectId) async {
    emit(state.copyWith(
        subjectId: subjectId, loadingChapters: true, chapters: const []));
    final r = await _repo.chapters(state.classId!, subjectId);
    if (isClosed) return;
    emit(state.copyWith(
        loadingChapters: false, chapters: r.getOrElse(() => const [])));
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    emit(state.copyWith(fileBytes: file.bytes, fileName: file.name));
  }

  void clearFile() => emit(state.copyWith(clearFile: true));

  /// Returns true on success so the caller can show a snackbar.
  Future<bool> deleteChapter(String id) async {
    final subjectId = state.subjectId!;
    final r = await _repo.deleteChapters(state.classId!, subjectId, [id]);
    if (isClosed) return r.isRight();
    if (r.isRight()) await selectSubject(subjectId);
    return r.isRight();
  }

  /// Returns true on success so the caller can show a snackbar.
  Future<bool> upload() async {
    final classId = state.classId;
    final subjectId = state.subjectId;
    final bytes = state.fileBytes;
    final chapterName = name.text.trim();
    final chapterOrder = int.tryParse(order.text.trim()) ?? 0;
    final filename = state.fileName ?? 'chapter.pdf';

    if (classId == null || subjectId == null || bytes == null || chapterName.isEmpty) {
      return false;
    }

    emit(state.copyWith(uploading: true));
    final r = await _repo.createChapterWithPdf(
      classId: classId,
      subjectId: subjectId,
      chapterName: chapterName,
      order: chapterOrder,
      bytes: bytes,
      filename: filename,
    );
    if (isClosed) return r.isRight();
    emit(state.copyWith(uploading: false));

    if (r.isRight()) {
      name.clear();
      order.clear();
      clearFile();
      await selectSubject(subjectId);
    }
    return r.isRight();
  }

  @override
  Future<void> close() {
    name.dispose();
    order.dispose();
    return super.close();
  }
}
