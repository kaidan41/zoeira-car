/// Acesso do usuário a conteúdos pagos: desbloqueios e consultas avulsas.
///
/// Persistido em Firestore em `users/{uid}`.
class UserAccessModel {
  final List<String> unlockedVehicleIds;
  final int consultaCredits;

  const UserAccessModel({
    this.unlockedVehicleIds = const [],
    this.consultaCredits = 0,
  });

  static const UserAccessModel empty = UserAccessModel();

  /// Esse veículo já está desbloqueado (avulsa paga)?
  bool isUnlocked(String vehicleId) => unlockedVehicleIds.contains(vehicleId);

  factory UserAccessModel.fromFirestore(Map<String, dynamic> data) {
    return UserAccessModel(
      unlockedVehicleIds: (data['unlocked_vehicle_ids'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      consultaCredits: data['consulta_credits'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'unlocked_vehicle_ids': unlockedVehicleIds,
      'consulta_credits': consultaCredits,
    };
  }

  UserAccessModel copyWith({
    List<String>? unlockedVehicleIds,
    int? consultaCredits,
  }) {
    return UserAccessModel(
      unlockedVehicleIds: unlockedVehicleIds ?? this.unlockedVehicleIds,
      consultaCredits: consultaCredits ?? this.consultaCredits,
    );
  }
}