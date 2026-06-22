// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestionModelImpl _$$QuestionModelImplFromJson(Map<String, dynamic> json) =>
    _$QuestionModelImpl(
      id: json['_id'] as String?,
      questionText: json['questionText'] as String?,
      question: json['question'] as String?,
      type: json['type'] as String?,
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      correctAnswer: json['correctAnswer'] as String?,
      answer: json['answer'] as String?,
      explanation: json['explanation'] as String?,
      difficulty: json['difficulty'] as String?,
      chapterId: json['chapterId'] as String?,
    );

Map<String, dynamic> _$$QuestionModelImplToJson(_$QuestionModelImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'questionText': instance.questionText,
      'question': instance.question,
      'type': instance.type,
      'options': instance.options,
      'correctAnswer': instance.correctAnswer,
      'answer': instance.answer,
      'explanation': instance.explanation,
      'difficulty': instance.difficulty,
      'chapterId': instance.chapterId,
    };
