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

  /// Busca veículos por veredito (para tela de categorias).
  /// Sem orderBy no Firestore de propósito: evita precisar de índice composto
  /// (verdict + brand_model_lower); a ordenação é feita no cliente.
  Future<List<VehicleModel>> getVehiclesByVerdict(String verdictId,
      {int limit = 50}) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('verdict', isEqualTo: verdictId)
        .limit(limit)
        .get();

    final vehicles = snapshot.docs
        .map((doc) => VehicleModel.fromFirestore(doc))
        .toList();

    vehicles.sort((a, b) =>
        '${a.brand} ${a.model} ${a.version}'.toLowerCase().compareTo(
            '${b.brand} ${b.model} ${b.version}'.toLowerCase()));
    return vehicles;
  }

  /// Busca veículos por carroceria (body_type). Sem orderBy no Firestore de
  /// propósito: evita índice composto; a ordenação é feita no cliente.
  Future<List<VehicleModel>> getVehiclesByBodyType(List<String> bodyTypes,
      {int limit = 200}) async {
    if (bodyTypes.isEmpty) return [];
    final snapshot = await _firestore
        .collection(_collection)
        .where('body_type', whereIn: bodyTypes)
        .limit(limit)
        .get();

    final vehicles = snapshot.docs
        .map((doc) => VehicleModel.fromFirestore(doc))
        .toList();

    vehicles.sort((a, b) =>
        '${a.brand} ${a.model} ${a.version}'.toLowerCase().compareTo(
            '${b.brand} ${b.model} ${b.version}'.toLowerCase()));
    return vehicles;
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
    final all = await getFipePricesByCode(fipeCode);
    if (all.isEmpty) return null;
    return all.first;
  }

  /// Converte o cache do Firestore (fipe_prices por ano) em FipeResults,
  /// SEM consultar a API. Retorna lista vazia se não houver cache.
  /// Usado pelo app para exibir a FIPE do nosso banco primeiro.
  List<FipeResult> fipeResultsFromCache(VehicleModel vehicle) {
    final prices = vehicle.fipePrices;
    if (prices == null || prices.isEmpty) return const [];

    final ref = vehicle.fipeReference ?? '';
    final list = prices.entries.map((e) {
      return FipeResult(
        valor: e.value.toStringAsFixed(2),
        marca: vehicle.brand,
        modelo: vehicle.model,
        anoModelo: '${e.key}',
        combustivel: '',
        codigoFipe: vehicle.fipeCode ?? '',
        mesReferencia: ref,
        tipoVeiculo: '',
        siglaCombustivel: '',
      );
    }).toList();
    list.sort((a, b) => b.anoModeloInt.compareTo(a.anoModeloInt));
    return list;
  }

  /// Salva o resultado da FIPE no documento do veículo (cache para o app
  /// não depender da API). Chamado pela Action semanal e pelo app quando
  /// consulta a API em primeiro uso.
  Future<void> saveFipeCache(
      String vehicleId, List<FipeResult> results) async {
    if (results.isEmpty) return;

    final map = <String, double>{};
    var ref = '';
    for (final r in results) {
      final ano = r.anoModeloInt;
      if (ano > 1950 && ano < 32000 && r.valorNumerico > 0) {
        map['$ano'] = r.valorNumerico;
      }
      if (ref.isEmpty && r.mesReferencia.isNotEmpty) {
        ref = r.mesReferencia;
      }
    }
    if (map.isEmpty) return;

    try {
      await _firestore.collection(_collection).doc(vehicleId).update({
        'fipe_prices': map,
        'fipe_reference': ref,
        'fipe_updated_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // documento pode não existir ou estar offline — cache fica só local
    }
  }

  /// Busca TODOS os preços FIPE de um código (um por ano/modelo de combustível),
  /// usado pelo seletor de ano da tabela FIPE.
  /// BrasilAPI primeiro; se estiver fora do ar, cai na Parallelum v2.
  Future<List<FipeResult>> getFipePricesByCode(String fipeCode) async {
    final cleanCode = fipeCode.replaceAll(RegExp(r'[^0-9\-]'), '').trim();
    if (cleanCode.isEmpty) return [];

    // 1. BrasilAPI (retorna todos os anos de uma vez)
    try {
      final url = 'https://brasilapi.com.br/api/fipe/preco/v1/$cleanCode';
      final response = await _client.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final list = decoded
              .whereType<Map<String, dynamic>>()
              .map(FipeResult.fromJson)
              .toList();
          if (list.isNotEmpty) return list;
        } else if (decoded is Map<String, dynamic>) {
          return [FipeResult.fromJson(decoded)];
        }
      }
    } catch (_) {
      // BrasilAPI fora do ar — tenta o fallback
    }

    // 2. Fallback Parallelum v2 (fipe.parallelum.com.br)
    try {
      return await _fetchFipeParallelumV2(cleanCode);
    } catch (_) {
      return [];
    }
  }

  /// Fallback: Parallelum v2 por código FIPE.
  /// Fluxo: pega a referência mais recente, lista os anos e busca o preço
  /// de cada ano em paralelo (limite de 15 anos para não estourar a API).
  Future<List<FipeResult>> _fetchFipeParallelumV2(String fipeCode) async {
    const v2Base = 'https://fipe.parallelum.com.br/api/v2';

    // Referência mais recente
    final refRes = await _client
        .get(Uri.parse('$v2Base/references'))
        .timeout(const Duration(seconds: 8));
    final refs = jsonDecode(refRes.body) as List<dynamic>;
    final refCode = refs.isEmpty ? '' : (refs.first['code'] as String? ?? '');

    final refQuery = refCode.isEmpty ? '' : '?reference=$refCode';

    // Anos disponíveis para o código
    final yearsRes = await _client
        .get(Uri.parse('$v2Base/cars/$fipeCode/years$refQuery'))
        .timeout(const Duration(seconds: 8));
    if (yearsRes.statusCode != 200) return [];
    final years = jsonDecode(yearsRes.body) as List<dynamic>;

    // Busca o preço de cada ano em paralelo
    final futures = years.take(15).map((y) async {
      final yearCode = (y as Map<String, dynamic>)['code'] as String? ?? '';
      if (yearCode.isEmpty) return null;
      try {
        final res = await _client
            .get(Uri.parse('$v2Base/cars/$fipeCode/years/$yearCode$refQuery'))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) return null;
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return FipeResult(
          valor: (data['price'] ?? '').toString(),
          marca: (data['brand'] ?? '').toString(),
          modelo: (data['model'] ?? '').toString(),
          anoModelo: (data['modelYear'] ?? '').toString(),
          combustivel: (data['fuel'] ?? '').toString(),
          codigoFipe: (data['codeFipe'] ?? '').toString(),
          mesReferencia: (data['referenceMonth'] ?? '').toString(),
          tipoVeiculo: (data['vehicleType'] ?? '').toString(),
          siglaCombustivel: (data['fuelAcronym'] ?? '').toString(),
        );
      } catch (_) {
        return null;
      }
    });

    final results = (await Future.wait(futures))
        .whereType<FipeResult>()
        .toList();
    return results;
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

  /// Ano do modelo como inteiro (ex: "2022" -> 2022).
  /// Código 32000 é o marcador FIPE de "Zero KM" — normaliza para 0
  /// para a UI exibir "Zero KM" em vez do número cru.
  int get anoModeloInt {
    final parsed = int.tryParse(anoModelo) ?? 0;
    return parsed >= 32000 ? 0 : parsed;
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
