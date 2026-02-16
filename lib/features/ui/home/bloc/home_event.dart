import 'package:seatlock_simulator/features/ui/home/domain/model/seat_model.dart';

sealed class HomePageEvent {
  const HomePageEvent();
}

class LoadSeatsEvent extends HomePageEvent {
  const LoadSeatsEvent();
}

class LockSeatEvent extends HomePageEvent {
  final SeatModel model;

  const LockSeatEvent(this.model);
}

class ConfirmReservationEvent extends HomePageEvent {
  final SeatModel seat;

  const ConfirmReservationEvent(this.seat);
}

class CancelLockEvent extends HomePageEvent {
  final SeatModel seat;

  const CancelLockEvent(this.seat);
}

class SeatsStreamEvent extends HomePageEvent {
  final List<SeatModel> seats;

  const SeatsStreamEvent(this.seats);
}

class BotLogEvent extends HomePageEvent {
  final String log;

  const BotLogEvent(this.log);
}

class ClearAllDataEvent extends HomePageEvent {
  const ClearAllDataEvent();
}
