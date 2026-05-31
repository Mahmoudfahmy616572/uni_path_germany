import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/applications_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'my_applications_states.dart';

class MyApplicationsCubit extends Cubit<MyApplicationsState> {
  final ApplicationsRepository repository;
  final AuthRepository
  authRepository; // 👈 إضافة الـ HomeCubit هنا للربط اللحظي

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

  Future<void> deleteApplication(String universityId) async {
    // 1. احذف من السيرفر
    await repository.removeSavedUniversity(universityId);

    // 2. هات البيانات الجديدة من السيرفر (تأكد إن دي بتجيب آخر تحديث)
    final newList = await repository.getMyApplications();

    // 3. الحركة "الخسيسة" عشان نجبر الـ UI يصحى:
    // ابعت حالة Empty أولاً، وبعدين Loaded
    emit(MyApplicationsLoading());
    await Future.delayed(
      const Duration(milliseconds: 100),
    ); // استنى جزء من الثانية

    emit(
      MyApplicationsLoaded(
        allApplications: newList,
        filteredApplications: newList, // أو منطق الفلترة بتاعك
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
}
