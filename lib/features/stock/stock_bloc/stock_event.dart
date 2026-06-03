part of 'stock_bloc.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();

  @override
  List<Object?> get props => [];
}

class LoadStockRequested extends StockEvent {
  final String? authToken;

  const LoadStockRequested({this.authToken});

  @override
  List<Object?> get props => [authToken];
}

class QuantityChanged extends StockEvent {
  final String itemId;
  final double quantity;

  const QuantityChanged({
    required this.itemId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [itemId, quantity];
}

class SyncRequested extends StockEvent {
  final String? authToken;

  const SyncRequested({this.authToken});

  @override
  List<Object?> get props => [authToken];
}

class BusinessChanged extends StockEvent {
  final String businessId;
  final String? authToken;

  const BusinessChanged({
    required this.businessId,
    this.authToken,
  });

  @override
  List<Object?> get props => [businessId, authToken];
}

class LocationChanged extends StockEvent {
  final String locationId;
  final String? authToken;

  const LocationChanged({
    required this.locationId,
    this.authToken,
  });

  @override
  List<Object?> get props => [locationId, authToken];
}

class DetailedCountSaved extends StockEvent {
  final String itemId;
  final double cartons;
  final double pieces;
  final String notes;
  final String countType;
  final String countDate;
  final String countedBy;

  const DetailedCountSaved({
    required this.itemId,
    required this.cartons,
    required this.pieces,
    required this.notes,
    required this.countType,
    required this.countDate,
    required this.countedBy,
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
      ];
}
