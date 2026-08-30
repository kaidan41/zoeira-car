/// Acesso do usuário a conteúdos pagos: consultas avulsas, créditos e a
/// consulta grátis diária.
///
/// Persistido em Firestore em `users/{uid}`.
class UserAccessModel {
  final List<String> unlockedVehicleIds;
  final int consultaCredits;
  final String? lastFreeDate; // formato yyyy-MM-dd
  final String? lastFreeVehicleId;

  const UserAccessModel({
    this.unlockedVehicleIds = const [],
    this.consultaCredits = 0,
    this.lastFreeDate,
    this.lastFreeVehicleId,
  });

  static const UserAccessModel empty = UserAccessModel();

  /// A consulta grátis de hoje já foi usada?
  bool get hasUsedFreeConsultToday {
    return lastFreeDate == _todayKey();
  }

  /// Esse veículo já está desbloqueado (avulsa grátis ou paga)?
  bool isUnlocked(String vehicleId) => unlockedVehicleIds.contains(vehicleId);

  static String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  factory UserAccessModel.fromFirestore(Map<String, dynamic> data) {
    return UserAccessModel(
      unlockedVehicleIds: (data['unlocked_vehicle_ids'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      consultaCredits: data['consulta_credits'] ?? 0,
      lastFreeDate: data['last_free_date'] as String?,
      lastFreeVehicleId: data['last_free_vehicle_id'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'unlocked_vehicle_ids': unlockedVehicleIds,
      'consulta_credits': consultaCredits,
      'last_free_date': lastFreeDate,
      'last_free_vehicle_id': lastFreeVehicleId,
    };
  }

  UserAccessModel copyWith({
    List<String>? unlockedVehicleIds,
    int? consultaCredits,
    String? lastFreeDate,
    String? lastFreeVehicleId,
  }) {
    return UserAccessModel(
      unlockedVehicleIds: unlockedVehicleIds ?? this.unlockedVehicleIds,
      consultaCredits: consultaCredits ?? this.consultaCredits,
      lastFreeDate: lastFreeDate ?? this.lastFreeDate,
      lastFreeVehicleId: lastFreeVehicleId ?? this.lastFreeVehicleId,
    );
  }
}