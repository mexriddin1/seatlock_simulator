import 'package:seatlock_simulator/core/extension/request_state.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_model.dart';

class HomePageState {
  final RequestState<List<SeatModel>> seatsStatus;
  final RequestState<List<SeatModel>> expirationSeatStatus;
  final List<String> botLogs;

  const HomePageState({
    this.seatsStatus = const RequestStateInitial(),
    this.expirationSeatStatus = const RequestStateInitial(),
    this.botLogs = const [],
  });

  HomePageState copyWith({
    RequestState<List<SeatModel>>? seatsStatus,
    RequestState<List<SeatModel>>? expirationSeatStatus,
    List<String>? botLogs,
  }) {
    return HomePageState(
      seatsStatus: seatsStatus ?? this.seatsStatus,
      expirationSeatStatus: expirationSeatStatus ?? this.expirationSeatStatus,
      botLogs: botLogs ?? this.botLogs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomePageState &&
          runtimeType == other.runtimeType &&
          seatsStatus == other.seatsStatus &&
          expirationSeatStatus == other.expirationSeatStatus &&
          botLogs == other.botLogs;

  @override
  int get hashCode =>
      seatsStatus.hashCode ^ expirationSeatStatus.hashCode ^ botLogs.hashCode;
}
