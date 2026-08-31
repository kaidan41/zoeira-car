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

  /// Atualiza o preço FIPE se o veículo tiver código FIPE cadastrado
  Future<void> refreshFipePrice() async {
    final fipeCode = _vehicle?.fipeCode;
    if (fipeCode == null || fipeCode.isEmpty) return;

    _loadingFipe = true;
    _fipeError = null;
    notifyListeners();

    try {
      final result = await _vehicleService.getFipePriceByCode(fipeCode);
      if (result != null && _vehicle != null) {
        _vehicle = _vehicle!.copyWith(
          fipePrice: double.tryParse(
            result.valor
                .replaceAll('R\$ ', '')
                .replaceAll('.', '')
                .replaceAll(',', '.'),
          ),
          fipeUpdatedAt: DateTime.now(),
        );
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
