import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/notification_service.dart';
import '../../../domain/entities/university_entity.dart';
import '../../../domain/repositories/applications_repository.dart';
import 'my_applications_states.dart';

class MyApplicationsCubit extends Cubit<MyApplicationsState> {
  final ApplicationsRepository repository;
  MyApplicationsCubit(this.repository) : super(MyApplicationsInitial());

  Future<void> loadApplications() async {
    if (isClosed) return;
    emit(MyApplicationsLoading());
    try {
      final apps = await repository.getMyApplications();
      if (!isClosed) {
        emit(
          MyApplicationsLoaded(
            allApplications: apps,
            filteredApplications: apps,
            activeFilter: 'all',
            statusCounts: _calculateCounts(apps),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) emit(MyApplicationsError(e.toString()));
    }
  }

  Future<void> deleteApplication(String universityId, String programId) async {
    final previousState = state;

    if (previousState is MyApplicationsLoaded) {
      final updatedAll = previousState.allApplications.where((app) {
        final appProgramId = app.programs.isNotEmpty
            ? app.programs.first.id
            : '';
        return !(app.id == universityId && appProgramId == programId);
      }).toList();

      emit(
        previousState.copyWith(
          allApplications: updatedAll,
          filteredApplications: _applyFilter(
            updatedAll,
            previousState.activeFilter,
          ),
          statusCounts: _calculateCounts(updatedAll),
        ),
      );
    }

    try {
      await repository.removeSavedProgram(
        universityId: universityId,
        programId: programId,
      );
      if (!isClosed && previousState is! MyApplicationsLoaded) {
        await loadApplications();
      }
    } catch (e) {
      if (previousState is MyApplicationsLoaded && !isClosed) {
        emit(previousState);
        return;
      }
      if (!isClosed) emit(MyApplicationsError("Delete failed"));
    }
  }

  void filterApplications(String status) {
    if (state is MyApplicationsLoaded) {
      final currentState = state as MyApplicationsLoaded;
      final filtered = status == 'all'
          ? currentState.allApplications
          : currentState.allApplications
                .where((e) => e.status == status)
                .toList();
      emit(
        currentState.copyWith(
          filteredApplications: filtered,
          activeFilter: status,
        ),
      );
    }
  }

  void searchApplications(String query) {
    if (state is MyApplicationsLoaded) {
      final currentState = state as MyApplicationsLoaded;
      if (query.isEmpty) {
        filterApplications(currentState.activeFilter);
        return;
      }
      final searched = currentState.allApplications.where((app) {
        final matchesName = app.name.toLowerCase().contains(
          query.toLowerCase(),
        );
        final matchesProgram = app.programs.any(
          (p) => p.programName.toLowerCase().contains(query.toLowerCase()),
        );
        return matchesName || matchesProgram;
      }).toList();
      emit(currentState.copyWith(filteredApplications: searched));
    }
  }

  Map<String, int> _calculateCounts(List<UniversityEntity> apps) {
    return {
      'all': apps.length,
      'saved': apps.where((e) => e.status == 'saved').length,
      'applied': apps.where((e) => e.status == 'applied').length,
      'accepted': apps.where((e) => e.status == 'accepted').length,
    };
  }

  List<UniversityEntity> _applyFilter(
    List<UniversityEntity> apps,
    String status,
  ) {
    return status == 'all'
        ? apps
        : apps.where((e) => e.status == status).toList();
  }

  // 5. تحديث حالة الطلب مع إشعار
  Future<void> updateApplicationStatus(
    String universityId,
    String programId,
    String newStatus,
  ) async {
    if (state is MyApplicationsLoaded) {
      final currentState = state as MyApplicationsLoaded;

      // Get old status for notification
      String oldStatus = 'saved';
      final app = currentState.allApplications
          .where((u) => u.id == universityId)
          .firstOrNull;
      if (app != null && app.programs.isNotEmpty) {
        oldStatus = app.status;
      }

      try {
        // Update in backend
        await repository.updateApplicationStatus(
          universityId: universityId,
          programId: programId,
          newStatus: newStatus,
        );

        // Send notification
        if (oldStatus != newStatus) {
          final details = await repository.getApplicationDetails(
            universityId: universityId,
            programId: programId,
          );
          if (details != null) {
            await NotificationService.notifyApplicationStatusChange(
              programName: details['university_programs']?['program_name'] ?? 'Unknown Program',
              universityName: details['universities']?['name'] ?? 'Unknown University',
              oldStatus: oldStatus,
              newStatus: newStatus,
            );
          }
        }

        // Update local state
        final updatedList = currentState.allApplications.map((uni) {
          final appProgramId = uni.programs.isNotEmpty ? uni.programs.first.id : '';
          final isSameApplication = uni.id == universityId && appProgramId == programId;
          return isSameApplication ? uni.copyWith(status: newStatus) : uni;
        }).toList();

        emit(
          currentState.copyWith(
            allApplications: updatedList,
            filteredApplications: _applyFilter(updatedList, currentState.activeFilter),
            statusCounts: _calculateCounts(updatedList),
          ),
        );
      } catch (e) {
        if (!isClosed) emit(MyApplicationsError("Failed to update status: $e"));
      }
    }
  }

  // 6. تحديث الملاحظات (تم استعادتها)
  Future<void> updateNotesInList(
    String universityId,
    String newNotes, {
    String? programId,
  }) async {
    if (state is MyApplicationsLoaded) {
      try {
        await repository.updateApplicationNotes(
          universityId: universityId,
          programId: programId,
          newNotes: newNotes,
        );
        // تحديث محلي سريع لضمان تجربة مستخدم سلسة
        final currentState = state as MyApplicationsLoaded;
        final updatedList = currentState.allApplications.map((uni) {
          final appProgramId = uni.programs.isNotEmpty
              ? uni.programs.first.id
              : '';
          final isSameApplication =
              uni.id == universityId &&
              (programId == null || appProgramId == programId);

          return isSameApplication ? uni.copyWith(notes: newNotes) : uni;
        }).toList();
        emit(
          currentState.copyWith(
            allApplications: updatedList,
            filteredApplications: _applyFilter(
              updatedList,
              currentState.activeFilter,
            ),
          ),
        );
      } catch (e) {
        if (!isClosed) emit(MyApplicationsError("Failed to update notes"));
      }
    }
  }

  void updateLocalApp(
    String universityId, {
    String? programId,
    String? portalStatus,
    String? paymentStatus,
    bool? autoTrack,
  }) {
    if (state is MyApplicationsLoaded) {
      final currentState = state as MyApplicationsLoaded;
      final updatedList = currentState.allApplications.map((uni) {
        final appProgramId = uni.programs.isNotEmpty ? uni.programs.first.id : '';
        final isSame = uni.id == universityId && (programId == null || appProgramId == programId);
        if (!isSame) return uni;
        return uni.copyWith(
          portalStatus: portalStatus,
          paymentStatus: paymentStatus,
          autoTrack: autoTrack,
        );
      }).toList();
      emit(
        currentState.copyWith(
          allApplications: updatedList,
          filteredApplications: _applyFilter(
            updatedList,
            currentState.activeFilter,
          ),
          statusCounts: _calculateCounts(updatedList),
        ),
      );
    }
  }
}
