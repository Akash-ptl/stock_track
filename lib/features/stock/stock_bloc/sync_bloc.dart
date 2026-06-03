import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../stock_model.dart';
import '../stock_repository.dart';

// Events
abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class SyncRequested extends SyncEvent {
  final String businessId;
  final String locationId;
  final String? authToken;
  final Function(List<StockItem>)? onSyncCompleted;

  const SyncRequested({
    required this.businessId,
    required this.locationId,
    this.authToken,
    this.onSyncCompleted,
  });

  @override
  List<Object?> get props => [businessId, locationId, authToken];
}

// States
class SyncState extends Equatable {
  final bool isSyncing;
  final String? syncError;
  final bool syncSuccess;

  const SyncState({
    this.isSyncing = false,
    this.syncError,
    this.syncSuccess = false,
  });

  factory SyncState.initial() => const SyncState();

  SyncState copyWith({
    bool? isSyncing,
    String? syncError,
    bool? syncSuccess,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError,
      syncSuccess: syncSuccess ?? this.syncSuccess,
    );
  }

  @override
  List<Object?> get props => [isSyncing, syncError, syncSuccess];
}

// Bloc
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final StockRepository _stockRepository;

  SyncBloc({required StockRepository stockRepository})
      : _stockRepository = stockRepository,
        super(SyncState.initial()) {
    on<SyncRequested>(_onSyncRequested);
  }

  Future<void> _onSyncRequested(SyncRequested event, Emitter<SyncState> emit) async {
    emit(state.copyWith(isSyncing: true, syncError: null, syncSuccess: false));
    try {
      final syncedItems = await _stockRepository.syncPendingRecords(
        businessId: event.businessId,
        locationId: event.locationId,
        authToken: event.authToken,
      );
      emit(state.copyWith(isSyncing: false, syncSuccess: true));
      if (event.onSyncCompleted != null) {
        event.onSyncCompleted!(syncedItems);
      }
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        syncError: 'Sync failed: Make sure the server is online and try again.',
      ));
    }
  }
}
