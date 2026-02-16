import 'package:flutter/material.dart';
import 'package:seatlock_simulator/core/constants/app_constants.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_model.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_status.dart';

class SeatGridItem extends StatelessWidget {
  final SeatModel seat;
  final VoidCallback onTap;

  const SeatGridItem({
    required this.seat,
    required this.onTap,
  });

  Color _seatColor(SeatStatus status) {
    switch (status) {
      case SeatStatus.available:
        return Colors.green;
      case SeatStatus.locked:
        return Colors.orange;
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
          color: _seatColor(seat.status),
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
