import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/profile/domain/entities/field.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_app/core/api/path_enforcer.dart';
import 'package:flutter_app/core/services/local_vault.dart';
import 'package:flutter/foundation.dart';

class ProfileState {
  final List<Field> fields;
  final String? selectedFieldId;
  final String? activeCycleId;
  final bool isLoading;

  const ProfileState({
    this.fields = const [],
    this.selectedFieldId,
    this.activeCycleId,
    this.isLoading = false,
  });

  Field? get selectedField {
    if (selectedFieldId == null) return null;
    return fields.firstWhere((f) => f.id == selectedFieldId, orElse: () => fields.first);
  }

  ProfileState copyWith({
    List<Field>? fields,
    String? selectedFieldId,
    String? activeCycleId,
    bool? isLoading,
  }) {
    return ProfileState(
      fields: fields ?? this.fields,
      selectedFieldId: selectedFieldId ?? this.selectedFieldId,
      activeCycleId: activeCycleId ?? this.activeCycleId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileController(this._ref) : super(const ProfileState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    final authState = _ref.read(authStateProvider);
    if (authState.value == null) {
      state = state.copyWith(isLoading: false, fields: []);
      return;
    }

    final vault = LocalVault();
    final String userId = authState.value!.id;
    final storedFields = vault.getFields(userId);
    
    if (storedFields.isNotEmpty) {
      final List<Field> fields = storedFields;
      final savedId = vault.getSelectedFieldId(userId);
      
      state = state.copyWith(
        fields: fields,
        selectedFieldId: savedId ?? (fields.isNotEmpty ? fields.first.id : null),
        activeCycleId: PathEnforcer.defaultCycleId,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(
      fields: [],
      selectedFieldId: null,
      activeCycleId: PathEnforcer.defaultCycleId,
      isLoading: false,
    );
  }


  Future<void> addField({
    required String name,
    required String soilType,
    required double acreage,
    required String irrigationType,
  }) async {
    state = state.copyWith(isLoading: true);
    
    final newFieldId = 'field_${DateTime.now().millisecondsSinceEpoch}';
    
    final newField = Field(
      id: newFieldId, 
      name: name, 
      soilType: soilType, 
      acreage: acreage,
      irrigationType: irrigationType,
    );

    final updatedFields = [
      ...state.fields,
      newField,
    ];

    final vault = LocalVault();
    final authState = _ref.read(authStateProvider);
    final String? userId = authState.value?.id;
    
    if (userId != null) {
      await vault.saveFields(userId, updatedFields);
      await vault.saveSelectedFieldId(userId, newFieldId);
    }

    state = state.copyWith(
      fields: updatedFields,
      selectedFieldId: newFieldId,
      activeCycleId: PathEnforcer.defaultCycleId,
      isLoading: false,
    );
  }

  Future<void> removeField(String fieldId) async {
    // 1. Filter out the field
    final updatedFields = state.fields.where((f) => f.id != fieldId).toList();
    
    // 2. Determine new selection if we deleted the active one
    String? newSelectedId = state.selectedFieldId;
    if (state.selectedFieldId == fieldId) {
      if (updatedFields.isNotEmpty) {
        newSelectedId = updatedFields.first.id;
      } else {
        newSelectedId = null; 
      }
    }

    state = state.copyWith(isLoading: true);

    // 3. Persist Changes
    final vault = LocalVault();
    final authState = _ref.read(authStateProvider);
    final String? userId = authState.value?.id;

    if (userId != null) {
      await vault.saveFields(userId, updatedFields);
      if (newSelectedId != null) {
        await vault.saveSelectedFieldId(userId, newSelectedId);
      }
      
      // Cleanup orphaned history
      await vault.clearHistory(
        userId: userId, 
        fieldId: fieldId, 
        cycleId: PathEnforcer.defaultCycleId 
      );
    }

    // 4. Update State
    state = state.copyWith(
      fields: updatedFields,
      selectedFieldId: newSelectedId,
      isLoading: false,
    );
  }

  void selectField(String fieldId) {
    final authState = _ref.read(authStateProvider);
    final String? userId = authState.value?.id;
    if (userId != null) {
      LocalVault().saveSelectedFieldId(userId, fieldId);
    }
    state = state.copyWith(selectedFieldId: fieldId);
  }

  /// Migration Bridge: Move 'unassigned' records to the currently active field
  Future<void> migrateLegacyData() async {
    final activeFieldId = state.selectedFieldId;
    final activeCycleId = state.activeCycleId;
    
    if (activeFieldId == null || activeCycleId == null || activeFieldId == PathEnforcer.unassignedFieldId) {
      debugPrint("⏭️ Migration skipped: No valid target field selected.");
      return;
    }

    state = state.copyWith(isLoading: true);
    
    final vault = LocalVault();
    final authState = _ref.read(authStateProvider);
    final userId = authState.value?.id;
    
    if (userId == null) {
      debugPrint("⏭️ Migration skipped: No authenticated user.");
      state = state.copyWith(isLoading: false);
      return;
    }

    final legacyRecords = vault.getHistory(
      userId: userId,
      fieldId: PathEnforcer.unassignedFieldId, 
      cycleId: PathEnforcer.defaultCycleId
    );

    int migratedCount = 0;
    for (final record in legacyRecords) {
      final oldKey = PathEnforcer.localCompositeKey(
        userId: userId,
        fieldId: PathEnforcer.unassignedFieldId, 
        cycleId: PathEnforcer.defaultCycleId, 
        activityId: record.id
      );
      await vault.rehomeRecord(
        oldKey, 
        userId: userId, 
        fieldId: activeFieldId, 
        cycleId: activeCycleId
      );
      migratedCount++;
    }

    debugPrint("✅ Migrated $migratedCount records to $activeFieldId");
    state = state.copyWith(isLoading: false);
  }
}

final profileProvider = StateNotifierProvider<ProfileController, ProfileState>((ref) {
  // Watch auth state - this ensures that if a user logs in (or out), 
  // the ProfileController is recreated and re-initializes its fields.
  ref.watch(authStateProvider);
  return ProfileController(ref);
});
