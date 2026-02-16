import 'package:flutter/material.dart';
import 'package:seatlock_simulator/core/constants/app_constants.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_model.dart';
import 'package:seatlock_simulator/features/ui/home/widgets/seat_grid_item.dart';

class SeatGridWidget extends StatelessWidget {
  final List<SeatModel> seats;
  final Function(SeatModel) onSeatTap;

  const SeatGridWidget({
    required this.seats,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.seatGridPadding),
      itemCount: seats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.seatGridSize,
        mainAxisSpacing: AppConstants.seatGridSpacing,
        crossAxisSpacing: AppConstants.seatGridSpacing,
      ),
      itemBuilder: (context, index) {
        final seat = seats[index];
        return SeatGridItem(
          seat: seat,
          onTap: () => onSeatTap(seat),
        );
      },
    );
  }
}
