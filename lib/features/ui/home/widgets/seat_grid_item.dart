import 'package:flutter/material.dart';
import 'package:seatlock_simulator/core/constants/app_constants.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_model.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_status.dart';
import 'package:seatlock_simulator/core/storage/seat_database.dart';

class SeatGridItem extends StatelessWidget {
  final SeatModel seat;
  final VoidCallback onTap;

  const SeatGridItem({super.key, required this.seat, required this.onTap});

  Color _seatColor(SeatModel seat) {
    switch (seat.status) {
      case SeatStatus.available:
        return Colors.green;
      case SeatStatus.locked:
        if (seat.lockedBy?.id == UsersData.currentUser.id) {
          return Colors.orange;
        } else {
          return Colors.orange;
        }
      case SeatStatus.reserved:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.dialogAnimationDuration,
        decoration: BoxDecoration(
          color: _seatColor(seat),
          borderRadius: BorderRadius.circular(AppConstants.dialogBorderRadius),
        ),
        child: Center(
          child: Text(
            '${AppConstants.seatNumberFormat}${(seat.id + 1).toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
