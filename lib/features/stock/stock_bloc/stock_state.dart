part of 'stock_bloc.dart';

abstract class StockState extends Equatable {
  const StockState();

  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockLoaded extends StockState {
  final List<StockItem> items;
  final List<Map<String, String>> businesses;
  final List<Map<String, String>> locations;
  final String selectedBusinessId;
  final String selectedLocationId;
  final bool isSyncing;
  final String? syncError;
  final bool isLoadingNewData;

  const StockLoaded({
    required this.items,
    required this.businesses,
    required this.locations,
    required this.selectedBusinessId,
    required this.selectedLocationId,
    this.isSyncing = false,
    this.syncError,
    this.isLoadingNewData = false,
  });

  StockLoaded copyWith({
    List<StockItem>? items,
    List<Map<String, String>>? businesses,
    List<Map<String, String>>? locations,
    String? selectedBusinessId,
    String? selectedLocationId,
    bool? isSyncing,
    String? syncError,
    bool? isLoadingNewData,
  }) {
    return StockLoaded(
      items: items ?? this.items,
      businesses: businesses ?? this.businesses,
      locations: locations ?? this.locations,
      selectedBusinessId: selectedBusinessId ?? this.selectedBusinessId,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError, // resets error if null is passed
      isLoadingNewData: isLoadingNewData ?? this.isLoadingNewData,
    );
  }

  @override
  List<Object?> get props => [
        items,
        businesses,
        locations,
        selectedBusinessId,
        selectedLocationId,
        isSyncing,
        syncError,
        isLoadingNewData,
      ];
}

class StockFailure extends StockState {
  final String errorMessage;

  const StockFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
