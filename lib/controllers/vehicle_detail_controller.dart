import 'package:flutter/foundation.dart';
import 'package:zoeira_car/models/vehicle_model.dart';
import 'package:zoeira_car/services/vehicle_service.dart';

enum DetailLoadState { idle, loading, loaded, error }

class VehicleDetailController extends ChangeNotifier {
  final VehicleService _vehicleService;
  final String vehicleId;

  VehicleDetailController({
    required this.vehicleId,
    VehicleService? vehicleService,
  }) : _vehicleService = vehicleService ?? VehicleService();

  DetailLoadState _state = DetailLoadState.idle;
  VehicleModel? _vehicle;
  String? _errorMessage;

  // Estado FIPE separado para não bloquear o restante da tela
  bool _loadingFipe = false;
  String? _fipeError;
  List<FipeResult> _fipeResults = [];
  int? _selectedFipeYear;
  String? _fipeReference;

  // Getters
  DetailLoadState get state => _state;
  VehicleModel? get vehicle => _vehicle;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == DetailLoadState.loading;
  bool get hasError => _state == DetailLoadState.error;
  bool get isLoaded => _state == DetailLoadState.loaded;
  bool get loadingFipe => _loadingFipe;
  String? get fipeError => _fipeError;
  String? get fipeReference => _fipeReference;
  int? get selectedFipeYear => _selectedFipeYear;

  /// Anos disponíveis na tabela FIPE (únicos, do mais novo pro mais antigo)
  List<int> get fipeYears {
    final anos = _fipeResults.map((r) => r.anoModeloInt).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return anos;
  }

  FipeResult? get _selectedFipeResult {
    final year = _selectedFipeYear;
    if (year == null) return null;
    for (final r in _fipeResults) {
      if (r.anoModeloInt == year) return r;
    }
    return null;
  }

  Future<void> load() async {
    if (_state == DetailLoadState.loading) return;

    _state = DetailLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final vehicle = await _vehicleService.getVehicleById(vehicleId);
      if (vehicle == null) {
        _state = DetailLoadState.error;
        _errorMessage = 'Nave não encontrada no hangar.';
      } else {
        _vehicle = vehicle;
        _state = DetailLoadState.loaded;
        // Conta para "mais buscados" no banner da Home
        _vehicleService.incrementViews(vehicleId);
        // Carrega os anos FIPE em segundo plano (sem travar a tela)
        _loadFipeData();
      }
    } catch (e) {
      _state = DetailLoadState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Carrega todos os anos FIPE (BrasilAPI) e seleciona o mais novo por padrão
  Future<void> _loadFipeData() async {
    final fipeCode = _vehicle?.fipeCode;
    if (fipeCode == null || fipeCode.isEmpty) return;

    _loadingFipe = true;
    _fipeError = null;
    notifyListeners();

    try {
      final results = await _vehicleService.getFipePricesByCode(fipeCode);
      if (results.isEmpty) {
        _fipeError = 'Preço FIPE em consulta. Tente novamente em instantes.';
      } else {
        _fipeResults = results;
        _selectedFipeYear = results.map((r) => r.anoModeloInt).reduce(
            (a, b) => a > b ? a : b);
        _applySelectedFipe();
      }
    } catch (_) {
      _fipeError = 'Não foi possível carregar a FIPE agora.';
    }

    _loadingFipe = false;
    notifyListeners();
  }

  /// Aplica o preço do ano selecionado ao veículo
  void _applySelectedFipe() {
    final result = _selectedFipeResult;
    final vehicle = _vehicle;
    if (result == null || vehicle == null) return;

    _fipeReference = result.mesReferencia;
    _vehicle = vehicle.copyWith(
      fipePrice: result.valorNumerico,
      fipeUpdatedAt: DateTime.now(),
    );
  }

  /// Troca o ano consultado na tabela FIPE
  void selectFipeYear(int year) {
    if (_selectedFipeYear == year) return;
    _selectedFipeYear = year;
    _fipeError = null;
    _applySelectedFipe();
    notifyListeners();
  }

  /// Atualiza o preço FIPE com BrasilAPI ou estimativa pela faixa de preço
  Future<void> refreshFipePrice() async {
    if (_vehicle == null) return;

    _loadingFipe = true;
    _fipeError = null;
    notifyListeners();

    try {
      final fipeCode = _vehicle!.fipeCode;
      FipeResult? result;

      if (fipeCode != null && fipeCode.isNotEmpty) {
        final results = await _vehicleService.getFipePricesByCode(fipeCode);
        if (results.isNotEmpty) {
          _fipeResults = results;
          // Mantém o ano selecionado se ainda existir; senão volta pro mais novo
          final current = _selectedFipeYear;
          if (results.any((r) => r.anoModeloInt == current)) {
            _applySelectedFipe();
          } else {
            _selectedFipeYear = results
                .map((r) => r.anoModeloInt)
                .reduce((a, b) => a > b ? a : b);
            _applySelectedFipe();
          }
          result = _selectedFipeResult;
        }
      }

      double? finalPrice;
      if (result != null && result.valorNumerico > 0) {
        finalPrice = result.valorNumerico;
      } else {
        // Fallback: calcula o preço médio da faixa de preço cadastrada (ex: "R$ 20.000 - R$ 40.000" -> 30000)
        final range = _vehicle!.priceRange;
        final matches = RegExp(r'\d+[\d\.]*').allMatches(range);
        if (matches.isNotEmpty) {
          final numbers = matches
              .map((m) => double.tryParse(m.group(0)!.replaceAll('.', '')) ?? 0.0)
              .where((v) => v > 0)
              .toList();
          if (numbers.isNotEmpty) {
            finalPrice = numbers.reduce((a, b) => a + b) / numbers.length;
          }
        }
      }

      if (finalPrice != null && finalPrice > 0) {
        _vehicle = _vehicle!.copyWith(
          fipePrice: finalPrice,
          fipeUpdatedAt: DateTime.now(),
        );
      } else {
        _fipeError = 'Preço FIPE em consulta. Tente novamente em instantes.';
      }
    } catch (e) {
      _fipeError = 'Não foi possível atualizar a FIPE agora.';
    }

    _loadingFipe = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _vehicleService.dispose();
    super.dispose();
  }
}
