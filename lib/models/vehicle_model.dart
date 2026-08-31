import 'package:cloud_firestore/cloud_firestore.dart';

/// Nível do veredito zoeiro do veículo
enum VehicleVerdict {
  /// Zoeira Car Recomenda! Pocotós garantidos e oficina longe
  recommended,

  /// Ok, mas só se estiver barato
  okIfCheap,

  /// Corre que é Cilada! Prepare o bolso e o guincho
  runAway,

  /// Exclusivo pra poucos — só se o bolso aguenta
  exclusive,
}

extension VehicleVerdictExtension on VehicleVerdict {
  String get label {
    switch (this) {
      case VehicleVerdict.recommended:
        return 'Zoeira Car Recomenda!';
      case VehicleVerdict.okIfCheap:
        return 'Ok, mas só se tiver barato';
      case VehicleVerdict.runAway:
        return 'Corre que é Cilada!';
      case VehicleVerdict.exclusive:
        return 'Exclusivo pra Poucos!';
    }
  }

  String get subtitle {
    switch (this) {
      case VehicleVerdict.recommended:
        return 'Pocotós garantidos e oficina longe 🚀';
      case VehicleVerdict.okIfCheap:
        return 'Negocia bem e talvez valha a pena 🤔';
      case VehicleVerdict.runAway:
        return 'Prepare o bolso e o guincho 🚨';
      case VehicleVerdict.exclusive:
        return 'Só se o bolso aguenta o tranco 👑';
    }
  }

  String get emoji {
    switch (this) {
      case VehicleVerdict.recommended:
        return '✅';
      case VehicleVerdict.okIfCheap:
        return '⚠️';
      case VehicleVerdict.runAway:
        return '🚨';
      case VehicleVerdict.exclusive:
        return '👑';
    }
  }
}

class VehicleModel {
  final String id;
  final String brand;
  final String model;
  final String version;
  final int yearStart;
  final int yearEnd; // 0 = ainda fabricado
  final String priceRange; // ex: "R$ 15.000 - R$ 35.000"
  final VehicleVerdict verdict;

  // Dados gratuitos
  final String verdictSummary; // Resumo zoeiro curto (público)
  final String thumbnailUrl;
  final String bodyType; // hatch | sedan | suv | pickup | classic

  // Dados premium (bloqueados para não assinantes)
  final String? chronicProblems; // Onde o bicho pega de verdade
  final String? whyBuy; // Por que comprar
  final String? whyAvoid; // Por que passar longe
  final String? technicalSpecs; // Ficha técnica completa
  final String? fipeCode; // Código FIPE para busca
  final double? fipePrice; // Preço FIPE atualizado
  final DateTime? fipeUpdatedAt;

  // Metadados
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VehicleModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.version,
    required this.yearStart,
    required this.yearEnd,
    required this.priceRange,
    required this.verdict,
    required this.verdictSummary,
    required this.thumbnailUrl,
    this.bodyType = 'hatch',
    this.chronicProblems,
    this.whyBuy,
    this.whyAvoid,
    this.technicalSpecs,
    this.fipeCode,
    this.fipePrice,
    this.fipeUpdatedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Nome completo formatado para exibição
  String get fullName => '$brand $model $version';

  /// Anos de produção formatado
  String get yearsFormatted =>
      yearEnd == 0 ? '$yearStart - atual' : '$yearStart - $yearEnd';

  /// Converte snapshot do Firestore para VehicleModel
  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      version: data['version'] ?? '',
      yearStart: data['year_start'] ?? 0,
      yearEnd: data['year_end'] ?? 0,
      priceRange: data['price_range'] ?? '',
      verdict: _verdictFromString(data['verdict'] ?? 'ok_if_cheap'),
      verdictSummary: data['verdict_summary'] ?? '',
      thumbnailUrl: data['thumbnail_url'] ?? '',
      bodyType: data['body_type'] ?? 'hatch',
      chronicProblems: data['chronic_problems'],
      whyBuy: data['why_buy'],
      whyAvoid: data['why_avoid'],
      technicalSpecs: data['technical_specs'],
      fipeCode: data['fipe_code'],
      fipePrice: (data['fipe_price'] as num?)?.toDouble(),
      fipeUpdatedAt: (data['fipe_updated_at'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'brand': brand,
      'model': model,
      'version': version,
      'year_start': yearStart,
      'year_end': yearEnd,
      'price_range': priceRange,
      'verdict': verdict.name,
      'verdict_summary': verdictSummary,
      'thumbnail_url': thumbnailUrl,
      'body_type': bodyType,
      'chronic_problems': chronicProblems,
      'why_buy': whyBuy,
      'why_avoid': whyAvoid,
      'technical_specs': technicalSpecs,
      'fipe_code': fipeCode,
      'fipe_price': fipePrice,
      'fipe_updated_at':
          fipeUpdatedAt != null ? Timestamp.fromDate(fipeUpdatedAt!) : null,
      'created_at':
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  static VehicleVerdict _verdictFromString(String value) {
    switch (value) {
      case 'recommended':
        return VehicleVerdict.recommended;
      case 'run_away':
        return VehicleVerdict.runAway;
      case 'exclusive':
        return VehicleVerdict.exclusive;
      default:
        return VehicleVerdict.okIfCheap;
    }
  }

  VehicleModel copyWith({
    String? id,
    String? brand,
    String? model,
    String? version,
    int? yearStart,
    int? yearEnd,
    String? priceRange,
    VehicleVerdict? verdict,
    String? verdictSummary,
    String? thumbnailUrl,
    String? bodyType,
    String? chronicProblems,
    String? whyBuy,
    String? whyAvoid,
    String? technicalSpecs,
    String? fipeCode,
    double? fipePrice,
    DateTime? fipeUpdatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      version: version ?? this.version,
      yearStart: yearStart ?? this.yearStart,
      yearEnd: yearEnd ?? this.yearEnd,
      priceRange: priceRange ?? this.priceRange,
      verdict: verdict ?? this.verdict,
      verdictSummary: verdictSummary ?? this.verdictSummary,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      bodyType: bodyType ?? this.bodyType,
      chronicProblems: chronicProblems ?? this.chronicProblems,
      whyBuy: whyBuy ?? this.whyBuy,
      whyAvoid: whyAvoid ?? this.whyAvoid,
      technicalSpecs: technicalSpecs ?? this.technicalSpecs,
      fipeCode: fipeCode ?? this.fipeCode,
      fipePrice: fipePrice ?? this.fipePrice,
      fipeUpdatedAt: fipeUpdatedAt ?? this.fipeUpdatedAt,
    );
  }
}
