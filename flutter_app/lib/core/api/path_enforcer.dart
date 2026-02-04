class PathEnforcer {
  static const String appId = "agripulse_v2";

  /// Builds a Firestore path for a hierarchical activity record
  static String activityPath({
    required String userId,
    required String fieldId,
    required String cycleId,
    required String activityId,
    String? category = 'general',
  }) {
    return 'artifacts/$appId/users/$userId/fields/$fieldId/cycles/$cycleId/activities/$activityId';
  }

  /// Builds a local composite key for Hive storage
  /// Format: userId_fieldId_cycleId_activityId
  static String localCompositeKey({
    required String userId,
    required String fieldId,
    required String cycleId,
    required String activityId,
  }) {
    return '${userId}_${fieldId}_${cycleId}_$activityId';
  }

  /// Checks if a local key belongs to a specific user, field and cycle
  static bool matchesContext(String key, String userId, String fieldId, String cycleId) {
    return key.startsWith('${userId}_${fieldId}_${cycleId}_');
  }

  /// Special path for "Unassigned" legacy data
  static const String unassignedFieldId = "unassigned_field";
  static const String defaultCycleId = "initial_cycle";
}
