import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/applications_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'my_applications_states.dart';

class MyApplicationsCubit extends Cubit<MyApplicationsState> {
  final ApplicationsRepository repository;
  final AuthRepository authRepository;

  MyApplicationsCubit(this.repository, this.authRepository)
    : super(MyApplicationsInitial()) {
    print("🚀 Cubit Instance Created: ${this.hashCode}");
    loadApplications();
  }

  // 1️⃣ جلب البيانات لأول مرة وحساب العدادات
  Future<void> loadApplications() async {
    emit(MyApplicationsLoading());
    try {
      final apps = await repository.getMyApplications();
      final counts = _calculateCounts(apps);

      emit(
        MyApplicationsLoaded(
          allApplications: apps,
          filteredApplications: apps,
          activeFilter: 'all',
          statusCounts: counts,
        ),
      );
    } catch (e, stackTrace) {
      print("🔥 THE REAL ERROR: $e");
      print("🚨 STACK TRACE: $stackTrace");
      emit(MyApplicationsError(e.toString()));
    }
  }

  // 2️⃣ تغيير الفلتر لما تضغط على Chip
  void filterApplications(String status) {
    if (state is MyApplicationsLoaded) {
      final currentState = state as MyApplicationsLoaded;
      final filtered = status == 'all'
          ? currentState.allApplications
          : currentState.allApplications
                .where((e) => e.status == status)
                .toList();

      emit(
        MyApplicationsLoaded(
          allApplications: currentState.allApplications,
          filteredApplications: filtered,
          activeFilter: status,
          statusCounts: currentState.statusCounts,
        ),
      );
    }
  }

  // 🎯 3️⃣ دالة البحث الاحترافية الجديدة
  void searchApplications(String query) {
    if (state is MyApplicationsLoaded) {
      final currentState = state as MyApplicationsLoaded;

      if (query.isEmpty) {
        // لو السيرش تمسح، نرجع نفلتر بالتابة المفتوحة حالياً فوراً
        filterApplications(currentState.activeFilter);
      } else {
        // 1. تحديد لستة الجامعات المتاحة للبحث جواها بناءً على التابة الحالية
        final baseList = currentState.activeFilter == 'all'
            ? currentState.allApplications
            : currentState.allApplications
                  .where((e) => e.status == currentState.activeFilter)
                  .toList();

        // 2. فلترة اللستة دي بناءً على الاسم أو اسم البرنامج
        final searched = baseList.where((app) {
          final matchesName = app.name.toLowerCase().contains(
            query.toLowerCase(),
          );
          final matchesProgram = app.program.toLowerCase().contains(
            query.toLowerCase(),
          );
          return matchesName || matchesProgram;
        }).toList();

        // 3. تحديث الـ State بقائمة البحث الجديدة باستخدام الـ copyWith
        emit(currentState.copyWith(filteredApplications: searched));
      }
    }
  }

  Future<void> deleteApplication(String universityId) async {
    await repository.removeSavedUniversity(universityId);
    final newList = await repository.getMyApplications();

    emit(MyApplicationsLoading());
    await Future.delayed(const Duration(milliseconds: 100));

    emit(
      MyApplicationsLoaded(
        allApplications: newList,
        filteredApplications: newList,
        activeFilter: 'all',
        statusCounts: _calculateCounts(newList),
      ),
    );
  }

  Map<String, int> _calculateCounts(List<dynamic> apps) {
    return {
      'all': apps.length,
      'saved': apps.where((e) => e.status == 'saved').length,
      'preparing': apps.where((e) => e.status == 'preparing').length,
      'applied': apps.where((e) => e.status == 'applied').length,
      'waiting': apps.where((e) => e.status == 'waiting').length,
      'accepted': apps.where((e) => e.status == 'accepted').length,
      'rejected': apps.where((e) => e.status == 'rejected').length,
    };
  }

  //  تحديث النوتس محلياً في اللستة فوراً بعد نجاح السيرفر
  Future<void> updateNotesInList(String universityId, String newNotes) async {
    if (state is MyApplicationsLoaded) {
      final currentState = state as MyApplicationsLoaded;

      // 1. تحديث السيرفر أولاً
      await repository.updateApplicationNotes(
        universityId: universityId,
        newNotes: newNotes,
      );

      // 2. تحديث اللستة المحلية
      final updatedList = currentState.allApplications.map((uni) {
        return uni.id == universityId ? uni.copyWith(notes: newNotes) : uni;
      }).toList();

      emit(
        currentState.copyWith(
          allApplications: updatedList,
          filteredApplications: currentState.activeFilter == 'all'
              ? updatedList
              : updatedList
                    .where((e) => e.status == currentState.activeFilter)
                    .toList(),
        ),
      );
    }
  }

  // تحديث أي خانة في الـ Checklist محلياً فوراً (SOP, CV, Transcripts, etc.)
  Future<void> updateChecklistItemInList({
    required String universityId,
    required String columnName,
    required bool newValue,
  }) async {
    if (state is MyApplicationsLoaded) {
      final currentState = state as MyApplicationsLoaded;

      // 1. تحديث السيرفر
      await repository.updateApplicationDocument(
        universityId: universityId,
        columnName: columnName,
        newValue: newValue,
      );

      // 2. تحديث اللستة المحلية بذكاء بناءً على اسم الكولوم المحدث
      final updatedList = currentState.allApplications.map((uni) {
        if (uni.id == universityId) {
          switch (columnName) {
            case 'has_cv':
              return uni.copyWith(hasCv: newValue);
            case 'has_sop':
              return uni.copyWith(hasSop: newValue);
            case 'has_transcripts':
              return uni.copyWith(hasTranscripts: newValue);
            case 'has_bachelor_cert':
              return uni.copyWith(hasBachelorCert: newValue);
            default:
              return uni;
          }
        }
        return uni;
      }).toList();

      emit(
        currentState.copyWith(
          allApplications: updatedList,
          filteredApplications: currentState.activeFilter == 'all'
              ? updatedList
              : updatedList
                    .where((e) => e.status == currentState.activeFilter)
                    .toList(),
        ),
      );
    }
  }
}
