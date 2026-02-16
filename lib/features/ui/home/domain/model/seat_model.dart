import 'package:seatlock_simulator/features/ui/home/domain/model/seat_status.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/user_model.dart';

class SeatModel {
  final int id;
  final SeatStatus status;
  final UserModel? lockedBy;
  final DateTime? lockExpirationTime;

  const SeatModel({
    required this.id,
    required this.status,
    this.lockedBy,
    this.lockExpirationTime,

  });

  SeatModel copyWith({SeatStatus? status, UserModel? lockedBy, DateTime? lockExpirationTime}) {
    return SeatModel(
      id: id,
      status: status ?? this.status,
      lockedBy: lockedBy ?? this.lockedBy,
      lockExpirationTime: lockExpirationTime ?? this.lockExpirationTime,
    );
  }
}