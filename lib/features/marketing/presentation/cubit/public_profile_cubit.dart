import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_helpers.dart';
import '../../../../core/network/endpoints.dart';

/// Holds the public, non-sensitive stats shown on a shareable profile card.
class PublicProfileData {
  const PublicProfileData({
    required this.name,
    required this.accountType,
    required this.questions,
    required this.accuracy,
    required this.subjects,
    required this.currentStreak,
    required this.longestStreak,
  });

  final String name;
  final String accountType;
  final int questions;
  final double accuracy; // 0..100
  final int subjects;
  final int currentStreak;
  final int longestStreak;
}

class PublicProfileState extends Equatable {
  const PublicProfileState({this.loading = true, this.data});

  final bool loading;
  final PublicProfileData? data;

  @override
  List<Object?> get props => [loading, data];
}

/// Loads the shareable `/student/:userId` public achievement card data from
/// the profile, streak, and progress endpoints.
class PublicProfileCubit extends Cubit<PublicProfileState> {
  PublicProfileCubit(this._dio) : super(const PublicProfileState());

  final Dio _dio;

  Future<Map<dynamic, dynamic>> _get(String path) async {
    try {
      final res = await _dio.get(path);
      return res.dataMap();
    } catch (_) {
      return const {};
    }
  }

  Future<void> load(String userId) async {
    final results = await Future.wait([
      _get('/profile/public/$userId'),
      _get(Endpoints.streak(userId)),
      _get(Endpoints.userProgress(userId)),
    ]);
    if (isClosed) return;
    final profile = results[0];
    final streak = results[1];
    final progress = results[2];
    final acc = progress['overallAccuracy'] is Map ? progress['overallAccuracy'] as Map : const {};
    emit(PublicProfileState(
      loading: false,
      data: PublicProfileData(
        name: profile.str(['name', 'userName'], 'AskAide Student'),
        accountType: profile.str(['accountType', 'role']),
        questions: acc.intval(['totalCount']),
        accuracy: acc.dbl(['accuracyPercent']),
        subjects: progress.listAt(['subjects', 'subjectsProgress']).length,
        currentStreak: streak.intval(['currentStreak']),
        longestStreak: streak.intval(['longestStreak']),
      ),
    ));
  }
}
