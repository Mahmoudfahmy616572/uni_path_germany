import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/applications_repository.dart';
import 'university_details_state.dart';

class UniversityDetailsCubit extends Cubit<UniversityDetailsState> {
  final ApplicationsRepository repository;
  int _currentMatchPercentage = 0;
  UniversityDetailsCubit(this.repository) : super(UniversityDetailsInitial());
  // 2. ضيف الدالة الجديدة دي هنا عشان تلقط النسبة من الشاشة أول ما تفتح
  void setInitialMatchPercentage(int percentage) {
    _currentMatchPercentage = percentage;
  }

  // الفحص المبدئي عند فتح الشاشة
  Future<void> checkInitialSaveStatus(String universityId) async {
    try {
      bool saved = await repository.checkIfSaved(universityId);
      emit(
        UniversitySaveStatus(
          isSaved: saved,
          isLoading: false,
          matchPercentage: _currentMatchPercentage,
        ),
      );
    } catch (e) {
      emit(
        UniversitySaveStatus(
          isSaved: false,
          isLoading: false,
          errorMessage: e.toString(),
          matchPercentage: _currentMatchPercentage,
        ),
      );
    }
  }

  // دالة الـ Toggle الأساسية للزرار السفلي
  Future<void> toggleSaveUniversity(
    String universityId,
    bool currentStatus,
  ) async {
    emit(UniversitySaveStatus(isSaved: currentStatus, isLoading: true));
    try {
      if (currentStatus) {
        await repository.removeSavedUniversity(universityId);
        emit(
          UniversitySaveStatus(
            isSaved: false,
            isLoading: false,
            isFromAction: true,
            matchPercentage: _currentMatchPercentage,
          ),
        );
      } else {
        await repository.saveUniversity(universityId);
        emit(
          UniversitySaveStatus(
            isSaved: true,
            isLoading: false,
            isFromAction: true,
            matchPercentage: _currentMatchPercentage,
          ),
        );
      }
    } catch (e) {
      emit(
        UniversitySaveStatus(
          isSaved: currentStatus,
          isLoading: false,
          errorMessage: e.toString(),
          isFromAction: true,
          matchPercentage: _currentMatchPercentage,
        ),
      );
    }
  }

  // 🔥 الدالة الجديدة لتحديث ورقة معينة في الـ Checklist دايناميك
  // 🎯 دالة تحديث الملاحظات للنظام المستقل في شاشة التفاصيل
  Future<void> updateNotes({
    required String universityId,
    required String newNotes,
  }) async {
    try {
      await repository.updateApplicationNotes(
        universityId: universityId,
        newNotes: newNotes,
      );
      // إعادة استدعاء الفحص لتحديث الـ UI بالكامل بالقيم الجديدة
      await checkInitialSaveStatus(universityId);
    } catch (e) {
      emit(
        UniversitySaveStatus(
          isSaved: true,
          errorMessage: "Failed to update notes",
          matchPercentage: _currentMatchPercentage,
        ),
      );
    }
  }

  // 🔥 دالة الـ Checklist الأصلية المحدثة لتنادي نفس الـ Repo المركزي
  Future<void> updateChecklistItem({
    required String universityId,
    required String column,
    required bool newValue,
  }) async {
    try {
      await repository.updateApplicationDocument(
        universityId: universityId,
        columnName: column,
        newValue: newValue,
      );
      await checkInitialSaveStatus(universityId);
    } catch (e) {
      emit(
        UniversitySaveStatus(
          isSaved: true,
          errorMessage: "Failed to update document",
          matchPercentage: _currentMatchPercentage,
        ),
      );
    }
  }
}
