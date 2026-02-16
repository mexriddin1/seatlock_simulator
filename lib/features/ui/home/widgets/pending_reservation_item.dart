import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seatlock_simulator/core/constants/app_constants.dart';
import 'package:seatlock_simulator/features/ui/home/widgets/countdown_widget.dart';
import 'package:seatlock_simulator/features/ui/home/bloc/home_bloc.dart';
import 'package:seatlock_simulator/features/ui/home/bloc/home_event.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_model.dart';

class PendingReservationItem extends StatelessWidget {
  final SeatModel seat;

  const PendingReservationItem({required this.seat});

  String get _seatNumber =>
      '${AppConstants.seatNumberFormat}${(seat.id + 1).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(seat.id),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.dialogBorderRadius),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Text(
            _seatNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          if (seat.lockExpirationTime != null)
            SeatCountdownTimer(
              expiryTime: seat.lockExpirationTime!,
              onTimerEnd: () {
                context.read<HomePageBloc>().add(
                  CancelLockEvent(seat),
                );
              },
            ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 10,
              ),
            ),
            onPressed: () {
              context.read<HomePageBloc>().add(
                CancelLockEvent(seat),
              );
            },
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 10,
              ),
            ),
            onPressed: () {
              context.read<HomePageBloc>().add(
                ConfirmReservationEvent(seat),
              );
            },
            child: const Text(
              'Confirm',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
