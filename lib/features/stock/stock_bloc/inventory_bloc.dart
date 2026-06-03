import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../stock_model.dart';
import '../stock_repository.dart';

// Events
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadInventoryRequested extends InventoryEvent {
  final String businessId;
  final String locationId;
  final String? authToken;

  const LoadInventoryRequested({
    required this.businessId,
    required this.locationId,
    this.authToken,
  });

  @override
  List<Object?> get props => [businessId, locationId, authToken];
}

class QuantityChanged extends InventoryEvent {
  final String itemId;
  final double quantity;
  final String businessId;
  final String locationId;

  const QuantityChanged({
    required this.itemId,
    required this.quantity,
    required this.businessId,
    required this.locationId,
  });

  @override
  List<Object?> get props => [itemId, quantity, businessId, locationId];
}

class DetailedCountSaved extends InventoryEvent {
  final String itemId;
  final double cartons;
  final double pieces;
  final String notes;
  final String countType;
  final String countDate;
  final String countedBy;
  final String businessId;
  final String locationId;

  const DetailedCountSaved({
    required this.itemId,
    required this.cartons,
    required this.pieces,
    required this.notes,
    required this.countType,
    required this.countDate,
    required this.countedBy,
    required this.businessId,
    required this.locationId,
  });

  @override
  List<Object?> get props => [
        itemId,
        cartons,
        pieces,
        notes,
        countType,
        countDate,
        countedBy,
        businessId,
        locationId,
      ];
}

class LocalItemsUpdated extends InventoryEvent {
  final List<StockItem> items;
  const LocalItemsUpdated({required this.items});
  @override
  List<Object?> get props => [items];
}

// States
abstract class InventoryState extends Equatable {
  const InventoryState();
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<StockItem> items;
  final bool isLoadingNewData;
  final String? error;

  const InventoryLoaded({
    required this.items,
    this.isLoadingNewData = false,
    this.error,
  });

  InventoryLoaded copyWith({
    List<StockItem>? items,
    bool? isLoadingNewData,
    String? error,
  }) {
    return InventoryLoaded(
      items: items ?? this.items,
      isLoadingNewData: isLoadingNewData ?? this.isLoadingNewData,
      error: error,
    );
  }

  @override
  List<Object?> get props => [items, isLoadingNewData, error];
}

class InventoryFailure extends InventoryState {
  final String errorMessage;
  const InventoryFailure(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

// Bloc
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final StockRepository _stockRepository;

  InventoryBloc({required StockRepository stockRepository})
      : _stockRepository = stockRepository,
        super(InventoryInitial()) {
    on<LoadInventoryRequested>(_onLoadInventoryRequested);
    on<QuantityChanged>(_onQuantityChanged);
    on<DetailedCountSaved>(_onDetailedCountSaved);
    on<LocalItemsUpdated>(_onLocalItemsUpdated);
  }

  Future<void> _onLoadInventoryRequested(LoadInventoryRequested event, Emitter<InventoryState> emit) async {
    final currentState = state;
    if (currentState is InventoryLoaded) {
      emit(currentState.copyWith(isLoadingNewData: true));
    } else {
      emit(InventoryLoading());
    }

    try {
      final items = await _stockRepository.fetchStockItems(
        businessId: event.businessId,
        locationId: event.locationId,
        authToken: event.authToken,
      );
      emit(InventoryLoaded(items: items));
    } catch (e) {
      emit(InventoryFailure(e.toString()));
    }
  }

  Future<void> _onQuantityChanged(QuantityChanged event, Emitter<InventoryState> emit) async {
    final currentState = state;
    if (currentState is InventoryLoaded) {
      try {
        final updatedItems = await _stockRepository.saveLocalQuantity(
          itemId: event.itemId,
          quantity: event.quantity,
          businessId: event.businessId,
          locationId: event.locationId,
        );
        emit(currentState.copyWith(items: updatedItems));
      } catch (e) {
        emit(currentState.copyWith(error: e.toString()));
      }
    }
  }

  Future<void> _onDetailedCountSaved(DetailedCountSaved event, Emitter<InventoryState> emit) async {
    final currentState = state;
    if (currentState is InventoryLoaded) {
      try {
        final updatedItems = await _stockRepository.saveDetailedLocalCount(
          itemId: event.itemId,
          cartons: event.cartons,
          pieces: event.pieces,
          notes: event.notes,
          countType: event.countType,
          countDate: event.countDate,
          countedBy: event.countedBy,
          businessId: event.businessId,
          locationId: event.locationId,
        );
        emit(currentState.copyWith(items: updatedItems));
      } catch (e) {
        emit(currentState.copyWith(error: e.toString()));
      }
    }
  }

  void _onLocalItemsUpdated(LocalItemsUpdated event, Emitter<InventoryState> emit) {
    final currentState = state;
    if (currentState is InventoryLoaded) {
      emit(currentState.copyWith(items: event.items));
    }
  }
}
