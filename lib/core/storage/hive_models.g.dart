// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedUserCredentialsAdapter extends TypeAdapter<CachedUserCredentials> {
  @override
  final int typeId = 0;

  @override
  CachedUserCredentials read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedUserCredentials(
      email: fields[0] as String,
      password: fields[1] as String,
      rememberMe: fields[2] as bool,
      lastUpdated: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedUserCredentials obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.password)
      ..writeByte(2)
      ..write(obj.rememberMe)
      ..writeByte(3)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedUserCredentialsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedUniversityAdapter extends TypeAdapter<CachedUniversity> {
  @override
  final int typeId = 1;

  @override
  CachedUniversity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedUniversity(
      id: fields[0] as String,
      name: fields[1] as String,
      matchPercentage: fields[2] as int,
      logoText: fields[3] as String,
      country: fields[4] as String,
      logoUrl: fields[5] as String,
      imageUrl: fields[6] as String,
      location: fields[7] as String,
      cachedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedUniversity obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.matchPercentage)
      ..writeByte(3)
      ..write(obj.logoText)
      ..writeByte(4)
      ..write(obj.country)
      ..writeByte(5)
      ..write(obj.logoUrl)
      ..writeByte(6)
      ..write(obj.imageUrl)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedUniversityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedProgramAdapter extends TypeAdapter<CachedProgram> {
  @override
  final int typeId = 2;

  @override
  CachedProgram read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedProgram(
      id: fields[0] as String,
      universityId: fields[1] as String,
      programName: fields[2] as String,
      major: fields[3] as String,
      requiredGpa: fields[4] as double,
      requiresIelts: fields[5] as bool,
      minIeltsScore: fields[6] as double,
      acceptsMoi: fields[7] as bool,
      instructionLanguage: fields[8] as String,
      degreeType: fields[9] as String,
      intakeType: fields[10] as String,
      matchScore: fields[11] as int,
      isRecommended: fields[12] as bool,
      cachedAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedProgram obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.universityId)
      ..writeByte(2)
      ..write(obj.programName)
      ..writeByte(3)
      ..write(obj.major)
      ..writeByte(4)
      ..write(obj.requiredGpa)
      ..writeByte(5)
      ..write(obj.requiresIelts)
      ..writeByte(6)
      ..write(obj.minIeltsScore)
      ..writeByte(7)
      ..write(obj.acceptsMoi)
      ..writeByte(8)
      ..write(obj.instructionLanguage)
      ..writeByte(9)
      ..write(obj.degreeType)
      ..writeByte(10)
      ..write(obj.intakeType)
      ..writeByte(11)
      ..write(obj.matchScore)
      ..writeByte(12)
      ..write(obj.isRecommended)
      ..writeByte(13)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedProgramAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
