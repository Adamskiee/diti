import 'package:flutter/material.dart';
import 'package:diti_database/diti_database.dart';

class ManualSessionState {
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int durationMinutes;
  final String routineName;
  final String? routineId;
  final String? planBlockId;
  final List<ActivityUsageSummaryRecord> detectedAppUsages;
  final bool isLoadingUsage;
  final bool isSaving;
  final String? errorMessage;

  const ManualSessionState({
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.routineName = '',
    this.routineId,
    this.planBlockId,
    this.detectedAppUsages = const [],
    this.isLoadingUsage = false,
    this.isSaving = false,
    this.errorMessage,
  });

  ManualSessionState copyWith({
    DateTime? selectedDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? durationMinutes,
    String? routineName,
    String? routineId,
    bool clearRoutineId = false,
    String? planBlockId,
    bool clearPlanBlockId = false,
    List<ActivityUsageSummaryRecord>? detectedAppUsages,
    bool? isLoadingUsage,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ManualSessionState(
      selectedDate: selectedDate ?? this.selectedDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      routineName: routineName ?? this.routineName,
      routineId: clearRoutineId ? null : (routineId ?? this.routineId),
      planBlockId: clearPlanBlockId ? null : (planBlockId ?? this.planBlockId),
      detectedAppUsages: detectedAppUsages ?? this.detectedAppUsages,
      isLoadingUsage: isLoadingUsage ?? this.isLoadingUsage,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualSessionState &&
          runtimeType == other.runtimeType &&
          selectedDate == other.selectedDate &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          durationMinutes == other.durationMinutes &&
          routineName == other.routineName &&
          routineId == other.routineId &&
          planBlockId == other.planBlockId &&
          isLoadingUsage == other.isLoadingUsage &&
          isSaving == other.isSaving &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        selectedDate,
        startTime,
        endTime,
        durationMinutes,
        routineName,
        routineId,
        planBlockId,
        isLoadingUsage,
        isSaving,
        errorMessage,
      );
}
