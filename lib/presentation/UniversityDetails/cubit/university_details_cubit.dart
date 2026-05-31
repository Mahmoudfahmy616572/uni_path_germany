import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/applications_repository.dart';
import 'university_details_state.dart';

class UniversityDetailsCubit extends Cubit<UniversityDetailsState> {
  final ApplicationsRepository repository;
  UniversityDetailsCubit(this.repository) : super(UniversityDetailsInitial());

  // الفحص المبدئي عند فتح الشاشة
  Future<void> checkInitialSaveStatus(String universityId) async {
    try {
      bool saved = await repository.checkIfSaved(universityId);
      emit(UniversitySaveStatus(isSaved: saved, isLoading: false));
    } catch (e) {
      emit(
        UniversitySaveStatus(
          isSaved: false,
          isLoading: false,
          errorMessage: e.toString(),
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
          ),
        );
      } else {
        await repository.saveUniversity(universityId);
        emit(
          UniversitySaveStatus(
            isSaved: true,
            isLoading: false,
            isFromAction: true,
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
        ),
      );
    }
  }

  // 🔥 الدالة الجديدة لتحديث ورقة معينة في الـ Checklist دايناميك
  Future<void> updateChecklistItem({
    required String universityId,
    required String column,
    required bool newValue,
  }) async {
    try {
      // نداء الـ Repo لتحديث خانة معينة (مثلا has_cv = true)
      await repository.updateApplicationDocument(
        universityId: universityId,
        columnName: column,
        newValue: newValue,
      );

      // إعادة قراءة الحالة لتحديث الـ UI
      await checkInitialSaveStatus(universityId);
    } catch (e) {
      emit(
        UniversitySaveStatus(
          isSaved: true,
          errorMessage: "Failed to update document",
        ),
      );
    }
  }
}
