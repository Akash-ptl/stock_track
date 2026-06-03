import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../stock_model.dart';
import '../stock_repository.dart';

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockRepository _stockRepository;

  StockBloc({required StockRepository stockRepository})
      : _stockRepository = stockRepository,
        super(StockInitial()) {
    on<LoadStockRequested>(_onLoadStockRequested);
    on<QuantityChanged>(_onQuantityChanged);
    on<SyncRequested>(_onSyncRequested);
    on<BusinessChanged>(_onBusinessChanged);
    on<LocationChanged>(_onLocationChanged);
    on<DetailedCountSaved>(_onDetailedCountSaved);
  }

  Future<void> _onLoadStockRequested(
    LoadStockRequested event,
    Emitter<StockState> emit,
  ) async {
    final currentState = state;
    final bool shouldUseDemo = event.useDemo || (currentState is StockLoaded && currentState.selectedBusinessId == 'biz_pizza_house');

    if (currentState is StockLoaded) {
      emit(currentState.copyWith(isLoadingNewData: true));
    } else {
      emit(StockLoading());
    }
    try {
      if (shouldUseDemo) {
        final businesses = [
          {'id': 'biz_pizza_house', 'name': 'Demo Pizza House'}
        ];
        final defaultBusinessId = 'biz_pizza_house';
        final locations = [
          {'id': 'loc_main_wh', 'name': 'Main Warehouse (Demo)'}
        ];
        final defaultLocationId = 'loc_main_wh';
        
        final items = await _stockRepository.fetchStockItems(
          businessId: defaultBusinessId,
          locationId: defaultLocationId,
          authToken: event.authToken,
        );

        emit(StockLoaded(
          items: items,
          businesses: businesses,
          locations: locations,
          selectedBusinessId: defaultBusinessId,
          selectedLocationId: defaultLocationId,
        ));
        return;
      }

      final businesses = await _stockRepository.fetchBusinesses(event.authToken);
      if (businesses.isEmpty) {
        emit(const StockLoaded(
          items: [],
          businesses: [],
          locations: [],
          selectedBusinessId: '',
          selectedLocationId: '',
        ));
        return;
      }
      
      final defaultBusinessId = businesses.first['id'] ?? '';
      final locations = await _stockRepository.fetchLocations(defaultBusinessId, event.authToken);
      final defaultLocationId = locations.isEmpty ? '' : (locations.first['id'] ?? '');
      final items = locations.isEmpty
          ? <StockItem>[]
          : await _stockRepository.fetchStockItems(
              businessId: defaultBusinessId,
              locationId: defaultLocationId,
              authToken: event.authToken,
            );

      emit(StockLoaded(
        items: items,
        businesses: businesses,
        locations: locations,
        selectedBusinessId: defaultBusinessId,
        selectedLocationId: defaultLocationId,
      ));
    } catch (e) {
      emit(StockFailure(e.toString()));
    }
  }

  Future<void> _onQuantityChanged(
    QuantityChanged event,
    Emitter<StockState> emit,
  ) async {
    final currentState = state;
    if (currentState is StockLoaded) {
      try {
        final updatedItems = await _stockRepository.saveLocalQuantity(
          itemId: event.itemId,
          quantity: event.quantity,
          businessId: currentState.selectedBusinessId,
          locationId: currentState.selectedLocationId,
        );
        emit(currentState.copyWith(items: updatedItems, syncError: null));
      } catch (e) {
        emit(currentState.copyWith(syncError: 'Failed to save local quantity: $e'));
      }
    }
  }

  Future<void> _onSyncRequested(
    SyncRequested event,
    Emitter<StockState> emit,
  ) async {
    final currentState = state;
    if (currentState is StockLoaded) {
      emit(currentState.copyWith(isSyncing: true, syncError: null));
      try {
        final syncedItems = await _stockRepository.syncPendingRecords(
          businessId: currentState.selectedBusinessId,
          locationId: currentState.selectedLocationId,
          authToken: event.authToken,
        );
        emit(currentState.copyWith(items: syncedItems, isSyncing: false));
      } catch (e) {
        emit(currentState.copyWith(
          isSyncing: false,
          syncError: 'Sync failed: Make sure the server is online and try again.',
        ));
      }
    }
  }

  Future<void> _onBusinessChanged(
    BusinessChanged event,
    Emitter<StockState> emit,
  ) async {
    final currentState = state;
    if (currentState is StockLoaded) {
      emit(currentState.copyWith(isLoadingNewData: true));
      try {
        final locations = await _stockRepository.fetchLocations(event.businessId, event.authToken);
        final defaultLocationId = locations.isEmpty ? '' : (locations.first['id'] ?? '');
        final items = locations.isEmpty
            ? <StockItem>[]
            : await _stockRepository.fetchStockItems(
                businessId: event.businessId,
                locationId: defaultLocationId,
                authToken: event.authToken,
              );

        emit(StockLoaded(
          items: items,
          businesses: currentState.businesses,
          locations: locations,
          selectedBusinessId: event.businessId,
          selectedLocationId: defaultLocationId,
        ));
      } catch (e) {
        emit(StockFailure(e.toString()));
      }
    }
  }

  Future<void> _onLocationChanged(
    LocationChanged event,
    Emitter<StockState> emit,
  ) async {
    final currentState = state;
    if (currentState is StockLoaded) {
      emit(currentState.copyWith(isLoadingNewData: true));
      try {
        final items = await _stockRepository.fetchStockItems(
          businessId: currentState.selectedBusinessId,
          locationId: event.locationId,
          authToken: event.authToken,
        );

        emit(StockLoaded(
          items: items,
          businesses: currentState.businesses,
          locations: currentState.locations,
          selectedBusinessId: currentState.selectedBusinessId,
          selectedLocationId: event.locationId,
          isLoadingNewData: false,
        ));
      } catch (e) {
        emit(StockFailure(e.toString()));
      }
    }
  }

  Future<void> _onDetailedCountSaved(
    DetailedCountSaved event,
    Emitter<StockState> emit,
  ) async {
    final currentState = state;
    if (currentState is StockLoaded) {
      try {
        final updatedItems = await _stockRepository.saveDetailedLocalCount(
          itemId: event.itemId,
          cartons: event.cartons,
          pieces: event.pieces,
          notes: event.notes,
          countType: event.countType,
          countDate: event.countDate,
          countedBy: event.countedBy,
          businessId: currentState.selectedBusinessId,
          locationId: currentState.selectedLocationId,
        );
        emit(currentState.copyWith(items: updatedItems, syncError: null));
      } catch (e) {
        emit(currentState.copyWith(syncError: 'Failed to save detailed count: $e'));
      }
    }
  }
}
