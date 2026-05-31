class UserEntity {
  final String id;
  final String email;
  final String name;
  final double maxGpa; // 👈 الحقل الجديد
  final double minGpa; // 👈 الحقل الجديد
  final bool hasMoi; // 👈 الحقل الجديد

  UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.maxGpa = 4.0, // قيمة افتراضية لأمان الـ UI
    this.minGpa = 1.0, // قيمة افتراضية لأمان الـ UI
    this.hasMoi = false, // قيمة افتراضية لأمان الـ UI
  });
}
