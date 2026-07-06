part of '../question_paper_pages.dart';

/// Builds a safe PDF filename from a paper title, mirroring React's
/// `` `${title}.pdf`.replace(/[^a-zA-Z0-9.\-_ ]/g, '') ``.
String _pdfFileName(String title) {
  final base = title.trim().isEmpty ? 'question-paper' : title.trim();
  final safe = base.replaceAll(RegExp(r'[^a-zA-Z0-9.\-_ ]'), '');
  return '$safe.pdf';
}

/// Builds the printable PDF for a question paper. Renders a header (school /
/// exam / meta), general instructions, MCQ + fill-in-blank sections and an
/// optional answer key. Mirrors the React public PDF layout.
Future<Uint8List> _buildPdf(PaperPreview preview, PdfPageFormat format, bool withAnswers) async {
  const marks = {'Easy': 1, 'Medium': 2, 'Hard': 3};
  final doc = pw.Document();

  pw.Widget questionBlock(int displayNo, PaperQuestion q, {bool showOptions = true}) {
    final m = marks[q.difficulty] ?? 1;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text('Q$displayNo. ${q.text}',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text('[$m Mark${m > 1 ? 's' : ''}]',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          if (showOptions && q.options.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            for (var o = 0; o < q.options.length; o++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
                child: pw.Text('(${String.fromCharCode(97 + o)}) ${q.options[o]}',
                    style: const pw.TextStyle(fontSize: 10)),
              ),
          ],
        ],
      ),
    );
  }

  final sections = QuestionSectionFactory.groupSections(preview.questions);
  // Fall back to flat numbering when there is no type info on questions.
  final hasSections = sections.isNotEmpty;
  final sectionOffsets = <int>[
    for (var i = 0, total = 0; i < sections.length; total += sections[i].questions.length, i++)
      total,
  ];
  final ordered = hasSections
      ? [for (final s in sections) ...s.questions]
      : preview.questions;

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      build: (ctx) => [
        if (preview.schoolName.isNotEmpty)
          pw.Center(
            child: pw.Text(preview.schoolName.toUpperCase(),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
        pw.Center(
          child: pw.Text(
              preview.examName.isNotEmpty ? preview.examName : preview.title,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            [
              if (preview.duration > 0) 'Time: ${preview.duration} min',
              if (preview.totalMarks > 0) 'Total Marks: ${preview.totalMarks}',
            ].join('   |   '),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.Divider(),
        if (preview.instructions.isNotEmpty) ...[
          pw.Text('General Instructions:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          for (var i = 0; i < preview.instructions.length; i++)
            pw.Text('${i + 1}. ${preview.instructions[i]}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
          pw.SizedBox(height: 8),
        ],
        if (hasSections)
          for (var s = 0; s < sections.length; s++) ...[
            if (s > 0) pw.SizedBox(height: 6),
            pw.Text(sections[s].spec.sectionLabel,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            for (var i = 0; i < sections[s].questions.length; i++)
              questionBlock(sectionOffsets[s] + i + 1, sections[s].questions[i],
                  showOptions: sections[s].spec.showOptions),
          ]
        else
          for (var i = 0; i < ordered.length; i++) questionBlock(i + 1, ordered[i]),
        if (withAnswers) ...[
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.Text('Answer Key',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          for (var i = 0; i < ordered.length; i++)
            if (ordered[i].correctAnswer.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text('Q${i + 1}: ${ordered[i].correctAnswer}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.green800)),
              ),
        ],
      ],
    ),
  );
  return doc.save();
}
