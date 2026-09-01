import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:zoeira_car/models/vehicle_model.dart';

class VehicleService {
  final FirebaseFirestore _firestore;
  final http.Client _client;

  static const String _collection = 'vehicles';

  VehicleService({
    FirebaseFirestore? firestore,
    http.Client? client,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client();

  // ─────────────────────────────────────────────
  // FIRESTORE
  // ─────────────────────────────────────────────

  /// Busca veículos por termo (busca em brand + model)
  Future<List<VehicleModel>> searchVehicles(String query) async {
    if (query.trim().isEmpty) return [];

    final normalized = query.trim().toLowerCase();

    // Firestore não suporta full-text search nativo.
    // Usamos array de tokens gerados no campo 'search_tokens'.
    final snapshot = await _firestore
        .collection(_collection)
        .where('search_tokens', arrayContains: normalized)
        .limit(20)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    }

    // Fallback: busca por prefixo no campo 'brand_model_lower'
    final fallback = await _firestore
        .collection(_collection)
        .orderBy('brand_model_lower')
        .startAt([normalized])
        .endAt(['$normalized\uf8ff'])
        .limit(20)
        .get();

    return fallback.docs
        .map((doc) => VehicleModel.fromFirestore(doc))
        .toList();
  }

  /// Busca um veículo pelo ID
  Future<VehicleModel?> getVehicleById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return VehicleModel.fromFirestore(doc);
  }

  /// Busca os veículos em destaque: os mais buscados (mais views).
  /// Fallback para `featured == true` se ainda não houver views.
  Future<List<VehicleModel>> getFeaturedVehicles({int limit = 6}) async {
    try {
      final mostViewed = await _firestore
          .collection(_collection)
          .orderBy('views', descending: true)
          .limit(limit)
          .get();

      final hasViews = mostViewed.docs.any((d) => (d.data()['views'] ?? 0) > 0);
      if (hasViews) {
        return mostViewed.docs
            .map((doc) => VehicleModel.fromFirestore(doc))
            .toList();
      }
    } catch (_) {
      // views ainda sem índice ou sem dados — cai no fallback
    }

    final snapshot = await _firestore
        .collection(_collection)
        .where('featured', isEqualTo: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => VehicleModel.fromFirestore(doc))
        .toList();
  }

  /// Incrementa o contador de visualizações (usado para "mais buscados")
  Future<void> incrementViews(String vehicleId) async {
    try {
      await _firestore.collection(_collection).doc(vehicleId).update({
        'views': FieldValue.increment(1),
      });
    } catch (_) {
      // documento pode não existir ou offline — ignora
    }
  }

  /// Stream para atualizações em tempo real de um veículo
  Stream<VehicleModel?> vehicleStream(String id) {
    return _firestore
        .collection(_collection)
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? VehicleModel.fromFirestore(doc) : null);
  }

  // ─────────────────────────────────────────────
  // FIPE API (parallelum.com.br — API pública)
  // ─────────────────────────────────────────────

  static const String _fipeBase = 'https://parallelum.com.br/fipe/api/v1';

  /// Busca marcas de carros na FIPE
  Future<List<Map<String, String>>> getFipeBrands() async {
    final response = await _client.get(Uri.parse('$_fipeBase/carros/marcas'));
    _assertOk(response, 'marcas FIPE');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => {
              'codigo': e['codigo'].toString(),
              'nome': e['nome'].toString(),
            })
        .toList();
  }

  /// Busca modelos de uma marca na FIPE
  Future<List<Map<String, String>>> getFipeModels(String brandCode) async {
    final response = await _client
        .get(Uri.parse('$_fipeBase/carros/marcas/$brandCode/modelos'));
    _assertOk(response, 'modelos FIPE');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final modelos = data['modelos'] as List<dynamic>;

    return modelos
        .map((e) => {
              'codigo': e['codigo'].toString(),
              'nome': e['nome'].toString(),
            })
        .toList();
  }

  /// Busca o preço FIPE de um veículo pelo código
  Future<FipeResult?> getFipePrice({
    required String brandCode,
    required String modelCode,
    required String yearCode,
  }) async {
    final url =
        '$_fipeBase/carros/marcas/$brandCode/modelos/$modelCode/anos/$yearCode';
    final response = await _client.get(Uri.parse(url));
    _assertOk(response, 'preço FIPE');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FipeResult.fromJson(data);
  }

  /// Busca preço FIPE direto pelo código FIPE (ex: "001004-9") usando BrasilAPI
  Future<FipeResult?> getFipePriceByCode(String fipeCode) async {
    final cleanCode = fipeCode.replaceAll(RegExp(r'[^0-9\-]'), '').trim();
    if (cleanCode.isEmpty) return null;

    try {
      final url = 'https://brasilapi.com.br/api/fipe/preco/v1/$cleanCode';
      final response = await _client.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return FipeResult.fromJson(decoded.first as Map<String, dynamic>);
        } else if (decoded is Map<String, dynamic>) {
          return FipeResult.fromJson(decoded);
        }
      }
    } catch (_) {
      // Fallback em caso de erro na BrasilAPI
    }
    return null;
  }

  void _assertOk(http.Response response, String context) {
    if (response.statusCode != 200) {
      throw VehicleServiceException(
          'Erro ao buscar $context: ${response.statusCode}');
    }
  }

  void dispose() => _client.close();
}

/// Resultado de uma consulta FIPE
class FipeResult {
  final String valor;
  final String marca;
  final String modelo;
  final String anoModelo;
  final String combustivel;
  final String codigoFipe;
  final String mesReferencia;
  final String tipoVeiculo;
  final String siglaCombustivel;

  const FipeResult({
    required this.valor,
    required this.marca,
    required this.modelo,
    required this.anoModelo,
    required this.combustivel,
    required this.codigoFipe,
    required this.mesReferencia,
    required this.tipoVeiculo,
    required this.siglaCombustivel,
  });

  /// Converte valor formatado ("R$ 45.000,00" ou "45000") para double numérico
  double get valorNumerico {
    final digits = valor.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    return double.tryParse(digits) ?? 0.0;
  }

  factory FipeResult.fromJson(Map<String, dynamic> json) {
    return FipeResult(
      valor: (json['valor'] ?? json['Valor'] ?? '').toString(),
      marca: (json['marca'] ?? json['Marca'] ?? '').toString(),
      modelo: (json['modelo'] ?? json['Modelo'] ?? '').toString(),
      anoModelo: (json['anoModelo'] ?? json['AnoModelo'] ?? '').toString(),
      combustivel: (json['combustivel'] ?? json['Combustivel'] ?? '').toString(),
      codigoFipe: (json['codigoFipe'] ?? json['CodigoFipe'] ?? '').toString(),
      mesReferencia:
          (json['mesReferencia'] ?? json['MesReferencia'] ?? '').toString(),
      tipoVeiculo:
          (json['tipoVeiculo'] ?? json['TipoVeiculo'] ?? '').toString(),
      siglaCombustivel:
          (json['siglaCombustivel'] ?? json['SiglaCombustivel'] ?? '').toString(),
    );
  }
}

class VehicleServiceException implements Exception {
  final String message;
  const VehicleServiceException(this.message);

  @override
  String toString() => 'VehicleServiceException: $message';
}
