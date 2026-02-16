import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:seatlock_simulator/core/extension/request_state.dart';
import 'package:seatlock_simulator/core/storage/seat_database.dart';
import 'package:seatlock_simulator/features/ui/home/domain/home_repository.dart';
import 'package:seatlock_simulator/features/ui/home/domain/background_seat_simulator.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_status.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomePageBloc extends Bloc<HomePageEvent, HomePageState> {
  final HomeRepository repository;
  StreamSubscription? _seatsStreamSubscription;
  StreamSubscription? _botLogSubscription;
  late BackgroundSeatSimulator _backgroundSimulator;

  HomePageBloc(this.repository) : super(HomePageState()) {
    _backgroundSimulator = BackgroundSeatSimulator(repository: repository);
    on<LoadSeatsEvent>(_loadSeatsEvent);
    on<LockSeatEvent>(_lockSeatEvent);
    on<ConfirmReservationEvent>(_confirmReservationEvent);
    on<CancelLockEvent>(_cancelLockEvent);
    on<SeatsStreamEvent>(_seatsStreamEvent);
    on<BotLogEvent>(_botLogEvent);
    on<ClearAllDataEvent>(_clearAllDataEvent);
  }

  Future<void> _loadSeatsEvent(
    LoadSeatsEvent event,
    Emitter<HomePageState> emit,
  ) async {
    emit(state.copyWith(seatsStatus: RequestStateLoading()));

    final response = await repository.loadSeats();

    if (response.isSuccess) {
      final stream = response.dataOrNull as Stream;
      _seatsStreamSubscription?.cancel();
      _seatsStreamSubscription = stream.listen(
        (seats) {
          add(SeatsStreamEvent(seats));
        },
        onError: (error) {
          emit(
            state.copyWith(seatsStatus: RequestStateFailed(error.toString())),
          );
        },
      );

      if (!_backgroundSimulator.isRunning) {
        _botLogSubscription?.cancel();
        _botLogSubscription = _backgroundSimulator.logStream.listen((log) {
          add(BotLogEvent(log));
        });
        await _backgroundSimulator.start();
      }
    } else {
      emit(
        state.copyWith(
          seatsStatus: RequestStateFailed(
            response.errorOrNull ?? "Unknown error",
          ),
        ),
      );
    }
  }

  Future<void> _seatsStreamEvent(
    SeatsStreamEvent event,
    Emitter<HomePageState> emit,
  ) async {
    emit(state.copyWith(seatsStatus: RequestStateSuccessWithData(event.seats)));
    final currentPending = state.expirationSeatStatus.dataOrNull ?? [];
    final filtered = currentPending.where((s) {
      final match = event.seats.firstWhere(
        (e) => e.id == s.id,
        orElse: () => s,
      );
      return match.lockedBy?.id == UsersData.currentUser.id &&
          match.status == SeatStatus.locked;
    }).toList();
    if (filtered.length != currentPending.length) {
      emit(
        state.copyWith(
          expirationSeatStatus: RequestStateSuccessWithData(filtered),
        ),
      );
    }
  }

  Future<void> _botLogEvent(
    BotLogEvent event,
    Emitter<HomePageState> emit,
  ) async {
    final updatedLogs = [...state.botLogs, event.log];
    if (updatedLogs.length > 50) {
      updatedLogs.removeAt(0);
    }
    emit(state.copyWith(botLogs: updatedLogs));
  }

  Future<void> _clearAllDataEvent(
    ClearAllDataEvent event,
    Emitter<HomePageState> emit,
  ) async {
    _backgroundSimulator.stop();

    await repository.clearAllSeats();

    emit(
      state.copyWith(
        botLogs: [],
        seatsStatus: RequestStateInitial(),
        expirationSeatStatus: RequestStateInitial(),
      ),
    );

    add(const LoadSeatsEvent());
  }

  Future<void> _lockSeatEvent(
    LockSeatEvent event,
    Emitter<HomePageState> emit,
  ) async {
    final response = await repository.lockSeat(event.model);

    if (response.isSuccess) {
      final data = response.dataOrNull;
      if (data != null) {
        if (data.lockedBy?.id == UsersData.currentUser.id) {
          final seats = (state.expirationSeatStatus.dataOrNull ?? [])
            ..add(data);

          emit(
            state.copyWith(
              expirationSeatStatus: RequestStateSuccessWithData(seats),
            ),
          );
        }
      }
    } else {
      emit(
        state.copyWith(
          seatsStatus: RequestStateFailed(
            response.errorOrNull ?? "Unknown error",
          ),
        ),
      );
    }
  }

  Future<void> _confirmReservationEvent(
    ConfirmReservationEvent event,
    Emitter<HomePageState> emit,
  ) async {
    final response = await repository.confirmReservation(event.seat);

    if (response.isSuccess && state.expirationSeatStatus.isSuccess) {
      final seats = state.expirationSeatStatus.dataOrNull ?? [];
      final updatedSeats = seats.where((s) => s.id != event.seat.id).toList();

      emit(
        state.copyWith(
          expirationSeatStatus: RequestStateSuccessWithData(updatedSeats),
        ),
      );
    } else {
      emit(
        state.copyWith(
          seatsStatus: RequestStateFailed(
            response.errorOrNull ?? "Unknown error",
          ),
        ),
      );
    }
  }

  Future<void> _cancelLockEvent(
    CancelLockEvent event,
    Emitter<HomePageState> emit,
  ) async {
    final response = await repository.cancelLock(event.seat);

    if (response.isSuccess && state.expirationSeatStatus.isSuccess) {
      final seats = state.expirationSeatStatus.dataOrNull ?? [];
      final updatedSeats = seats.where((s) => s.id != event.seat.id).toList();

      emit(
        state.copyWith(
          expirationSeatStatus: RequestStateSuccessWithData(updatedSeats),
        ),
      );
    } else {
      emit(
        state.copyWith(
          seatsStatus: RequestStateFailed(
            response.errorOrNull ?? "Unknown error",
          ),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _seatsStreamSubscription?.cancel();
    _botLogSubscription?.cancel();
    _backgroundSimulator.dispose();
    return super.close();
  }
}
