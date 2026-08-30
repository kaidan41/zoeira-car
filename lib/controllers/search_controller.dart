import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:zoeira_car/models/vehicle_model.dart';
import 'package:zoeira_car/services/vehicle_service.dart';

enum SearchState { idle, loading, loaded, error, empty }

class VehicleSearchController extends ChangeNotifier {
  final VehicleService _vehicleService;

  VehicleSearchController({VehicleService? vehicleService})
      : _vehicleService = vehicleService ?? VehicleService();

  SearchState _state = SearchState.idle;
  List<VehicleModel> _results = [];
  String _query = '';
  String? _errorMessage;
  Timer? _debounce;

  // ── Getters ──
  SearchState get state => _state;
  List<VehicleModel> get results => _results;
  String get query => _query;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == SearchState.loading;
  bool get hasResults => _state == SearchState.loaded && _results.isNotEmpty;
  bool get isEmpty => _state == SearchState.empty;
  bool get isIdle => _state == SearchState.idle;
  bool get hasError => _state == SearchState.error;

  /// Dispara a busca com debounce de 400ms
  void onQueryChanged(String value) {
    _query = value.trim();
    _debounce?.cancel();

    if (_query.isEmpty) {
      _state = SearchState.idle;
      _results = [];
      notifyListeners();
      return;
    }

    _state = SearchState.loading;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 400), () => _search());
  }

  /// Executa a busca imediatamente (ex: ao pressionar Enter)
  Future<void> searchNow() async {
    if (_query.isEmpty) return;
    _debounce?.cancel();
    await _search();
  }

  Future<void> _search() async {
    try {
      final results = await _vehicleService.searchVehicles(_query);
      _results = results;
      _state = results.isEmpty ? SearchState.empty : SearchState.loaded;
      _errorMessage = null;
    } catch (e) {
      _state = SearchState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void clearSearch() {
    _debounce?.cancel();
    _query = '';
    _results = [];
    _state = SearchState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _vehicleService.dispose();
    super.dispose();
  }
}
