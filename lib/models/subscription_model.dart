import 'package:cloud_firestore/cloud_firestore.dart';

/// Status da assinatura do usuário
enum SubscriptionStatus {
  /// Assinatura ativa e válida
  active,

  /// Período de teste gratuito ativo
  trial,

  /// Assinatura expirada / cancelada
  expired,

  /// Nunca assinou
  none,
}

extension SubscriptionStatusExtension on SubscriptionStatus {
  bool get isActive =>
      this == SubscriptionStatus.active || this == SubscriptionStatus.trial;

  String get label {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Capivara da Sua Nave ativa 🚀';
      case SubscriptionStatus.trial:
        return 'Período de Teste';
      case SubscriptionStatus.expired:
        return 'Assinatura Expirada';
      case SubscriptionStatus.none:
        return 'Sem Assinatura';
    }
  }
}

class SubscriptionModel {
  final String userId;
  final SubscriptionStatus status;
  final String? purchaseToken; // Token do Google Play
  final String? productId; // ID do produto na Play Store
  final DateTime? startDate;
  final DateTime? expiryDate;
  final bool autoRenewing;

  const SubscriptionModel({
    required this.userId,
    required this.status,
    this.purchaseToken,
    this.productId,
    this.startDate,
    this.expiryDate,
    this.autoRenewing = false,
  });

  /// Assinatura está válida agora?
  bool get isValid {
    if (!status.isActive) return false;
    if (expiryDate == null) return false;
    return expiryDate!.isAfter(DateTime.now());
  }

  /// Dias restantes na assinatura
  int get daysRemaining {
    if (expiryDate == null) return 0;
    final diff = expiryDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Assinatura vence em breve (menos de 3 dias)?
  bool get expiringSoon => isValid && daysRemaining <= 3;

  /// Modelo padrão para usuário sem assinatura
  static SubscriptionModel empty(String userId) => SubscriptionModel(
        userId: userId,
        status: SubscriptionStatus.none,
      );

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      userId: doc.id,
      status: _statusFromString(data['status'] ?? 'none'),
      purchaseToken: data['purchase_token'] as String?,
      productId: data['product_id'] as String?,
      startDate: (data['start_date'] as Timestamp?)?.toDate(),
      expiryDate: (data['expiry_date'] as Timestamp?)?.toDate(),
      autoRenewing: data['auto_renewing'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'status': status.name,
      'purchase_token': purchaseToken,
      'product_id': productId,
      'start_date':
          startDate != null ? Timestamp.fromDate(startDate!) : null,
      'expiry_date':
          expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'auto_renewing': autoRenewing,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  static SubscriptionStatus _statusFromString(String value) {
    switch (value) {
      case 'active':
        return SubscriptionStatus.active;
      case 'trial':
        return SubscriptionStatus.trial;
      case 'expired':
        return SubscriptionStatus.expired;
      default:
        return SubscriptionStatus.none;
    }
  }

  SubscriptionModel copyWith({
    SubscriptionStatus? status,
    String? purchaseToken,
    String? productId,
    DateTime? startDate,
    DateTime? expiryDate,
    bool? autoRenewing,
  }) {
    return SubscriptionModel(
      userId: userId,
      status: status ?? this.status,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      productId: productId ?? this.productId,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      autoRenewing: autoRenewing ?? this.autoRenewing,
    );
  }
}

/// Plano de assinatura disponível na Play Store
class SubscriptionPlan {
  static const String productId = 'zoeira_car_mensal';
  static const String displayName = 'Puxe agora a Capivara da Sua Nave';
  static const String price = 'R\$ 14,99/mês';
  static const String description =
      'Destrave o raio-x completo de qualquer nave!';

  static const List<String> benefits = [
    '🔍 Problemas crônicos detalhados',
    '✅ Por que comprar (ou não)',
    '📋 Ficha técnica completa',
    '💰 Tabela FIPE atualizada',
    '🚀 Acesso ilimitado a todos os veículos',
    '📺 Conteúdo exclusivo do canal',
  ];
}

/// Consulta avulsa (produto one-time na Play Store)
class ConsultationPlan {
  static const String productId = 'zoeira_consulta';
  static const String displayName = 'Consulta Avulsa de 1 Nave';
  static const String price = 'R\$ 7,90';
  static const String description =
      'Desbloqueia o raio-x completo de 1 veículo para sempre.';
}
