import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/question_type.dart';
import '../../../../core/taxonomy/taxonomy_repository.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../../core/presentation/widgets/chip_picker.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/presentation/widgets/step_indicator.dart';
import '../../../../core/theme/state_visuals.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/question_paper_feature.dart';

part 'question_paper_pages_parts/generator_view.dart';
part 'question_paper_pages_parts/wizard_widgets.dart';
part 'question_paper_pages_parts/question_type_section.dart';
part 'question_paper_pages_parts/preview_view.dart';
part 'question_paper_pages_parts/pdf_builder.dart';
part 'question_paper_pages_parts/history_view.dart';

/// `/question-paper` — a three-step wizard (Setup → Questions → Options) for
/// generating an exam paper. Mirrors QuestionPaperGenerator's flow.
class QuestionPaperGeneratorPage extends StatelessWidget {
  const QuestionPaperGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final teacherId = context.read<ProfileCubit>().state.user?.id ?? '';
    return BlocProvider<QpGeneratorCubit>(
      create: (_) => sl<QpGeneratorCubit>()..init(teacherId),
      child: const _GeneratorView(),
    );
  }
}

class QuestionPaperPreviewPage extends StatelessWidget {
  const QuestionPaperPreviewPage({super.key, required this.paperId});
  final String paperId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaperPreviewCubit>(
      create: (_) => sl<PaperPreviewCubit>()..load(paperId),
      child: _PreviewView(paperId: paperId),
    );
  }
}

/// Opens the system print/share sheet for a generated [preview] with an answer
/// key included. Used by the public/guest generator to download its PDF.
Future<void> printPaperPdf(PaperPreview preview, {bool withAnswers = true}) {
  return Printing.layoutPdf(
    name: preview.examName.isNotEmpty ? preview.examName : preview.title,
    onLayout: (format) async => _buildPdf(preview, format, withAnswers),
  );
}

/// `/question-paper/history` — archive of generated papers, loaded live.
class QuestionPaperHistoryPage extends StatelessWidget {
  const QuestionPaperHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaperHistoryCubit>(
      create: (_) => sl<PaperHistoryCubit>()..load(),
      child: const _PaperHistoryView(),
    );
  }
}
