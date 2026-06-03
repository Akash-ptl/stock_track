import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../stock_repository.dart';

// Events
abstract class TenantEvent extends Equatable {
  const TenantEvent();
  @override
  List<Object?> get props => [];
}

class LoadTenantsRequested extends TenantEvent {
  final String? authToken;
  const LoadTenantsRequested({this.authToken});
  @override
  List<Object?> get props => [authToken];
}

class BusinessChanged extends TenantEvent {
  final String businessId;
  final String? authToken;
  const BusinessChanged({required this.businessId, this.authToken});
  @override
  List<Object?> get props => [businessId, authToken];
}

class LocationChanged extends TenantEvent {
  final String locationId;
  const LocationChanged({required this.locationId});
  @override
  List<Object?> get props => [locationId];
}

// States
class TenantState extends Equatable {
  final List<Map<String, String>> businesses;
  final List<Map<String, String>> locations;
  final String selectedBusinessId;
  final String selectedLocationId;
  final bool isLoading;
  final String? error;

  const TenantState({
    required this.businesses,
    required this.locations,
    required this.selectedBusinessId,
    required this.selectedLocationId,
    this.isLoading = false,
    this.error,
  });

  factory TenantState.initial() => const TenantState(
        businesses: [],
        locations: [],
        selectedBusinessId: '',
        selectedLocationId: '',
      );

  TenantState copyWith({
    List<Map<String, String>>? businesses,
    List<Map<String, String>>? locations,
    String? selectedBusinessId,
    String? selectedLocationId,
    bool? isLoading,
    String? error,
  }) {
    return TenantState(
      businesses: businesses ?? this.businesses,
      locations: locations ?? this.locations,
      selectedBusinessId: selectedBusinessId ?? this.selectedBusinessId,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [businesses, locations, selectedBusinessId, selectedLocationId, isLoading, error];
}

// Bloc
class TenantBloc extends Bloc<TenantEvent, TenantState> {
  final StockRepository _stockRepository;

  TenantBloc({required StockRepository stockRepository})
      : _stockRepository = stockRepository,
        super(TenantState.initial()) {
    on<LoadTenantsRequested>(_onLoadTenantsRequested);
    on<BusinessChanged>(_onBusinessChanged);
    on<LocationChanged>(_onLocationChanged);
  }

  Future<void> _onLoadTenantsRequested(LoadTenantsRequested event, Emitter<TenantState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final businesses = await _stockRepository.fetchBusinesses(event.authToken);
      if (businesses.isEmpty) {
        emit(state.copyWith(businesses: [], locations: [], selectedBusinessId: '', selectedLocationId: '', isLoading: false));
        return;
      }
      final defaultBusinessId = businesses.first['id'] ?? '';
      final locations = await _stockRepository.fetchLocations(defaultBusinessId, event.authToken);
      final defaultLocationId = locations.isEmpty ? '' : (locations.first['id'] ?? '');

      emit(state.copyWith(
        businesses: businesses,
        locations: locations,
        selectedBusinessId: defaultBusinessId,
        selectedLocationId: defaultLocationId,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onBusinessChanged(BusinessChanged event, Emitter<TenantState> emit) async {
    emit(state.copyWith(isLoading: true, error: null, selectedBusinessId: event.businessId));
    try {
      final locations = await _stockRepository.fetchLocations(event.businessId, event.authToken);
      final defaultLocationId = locations.isEmpty ? '' : (locations.first['id'] ?? '');

      emit(state.copyWith(
        locations: locations,
        selectedLocationId: defaultLocationId,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onLocationChanged(LocationChanged event, Emitter<TenantState> emit) {
    emit(state.copyWith(selectedLocationId: event.locationId));
  }
}
