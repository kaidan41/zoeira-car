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

  // Getters
  DetailLoadState get state => _state;
  VehicleModel? get vehicle => _vehicle;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == DetailLoadState.loading;
  bool get hasError => _state == DetailLoadState.error;
  bool get isLoaded => _state == DetailLoadState.loaded;
  bool get loadingFipe => _loadingFipe;
  String? get fipeError => _fipeError;

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
      }
    } catch (e) {
      _state = DetailLoadState.error;
      _errorMessage = e.toString();
    }

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
        result = await _vehicleService.getFipePriceByCode(fipeCode);
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
