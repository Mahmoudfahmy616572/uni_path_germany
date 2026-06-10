import 'package:equatable/equatable.dart';

import '../../../domain/entities/university_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final int matchScore;
  final List<UniversityEntity> recommendations;

  // 🎯 حقول الـ Pagination الجديدة
  final bool isFetchingMore; // هل نقوم حالياً بجلب صفحة جديدة؟
  final bool hasReachedMax; // هل وصلنا لنهاية البيانات في قاعدة البيانات؟

  const HomeLoaded({
    required this.matchScore,
    required this.recommendations,
    this.isFetchingMore = false,
    this.hasReachedMax = false,
  });

  // دالة copyWith ضرورية جداً لتحديث القائمة دون مسح البيانات القديمة
  HomeLoaded copyWith({
    int? matchScore,
    List<UniversityEntity>? recommendations,
    bool? isFetchingMore,
    bool? hasReachedMax,
  }) {
    return HomeLoaded(
      matchScore: matchScore ?? this.matchScore,
      recommendations: recommendations ?? this.recommendations,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [
    matchScore,
    recommendations,
    isFetchingMore,
    hasReachedMax,
  ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}
