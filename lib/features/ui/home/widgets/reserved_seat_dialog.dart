import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seatlock_simulator/core/constants/app_constants.dart';
import 'package:seatlock_simulator/core/storage/seat_database.dart';
import 'package:seatlock_simulator/features/ui/home/bloc/home_bloc.dart';
import 'package:seatlock_simulator/features/ui/home/bloc/home_event.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_model.dart';
import 'package:seatlock_simulator/features/ui/home/widgets/user_info_card.dart';

class ReservedSeatDialog extends StatelessWidget {
  final SeatModel seat;

  const ReservedSeatDialog({super.key, required this.seat});

  bool get _isCurrentUserSeat =>
      seat.lockedBy?.id == UsersData.currentUser.id;

  String get _seatNumber =>
      '${AppConstants.seatNumberFormat}${(seat.id + 1).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        '$_seatNumber - Reserved',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserInfoCard(
              title: 'Reserved by:',
              user: seat.lockedBy ?? UsersData.defaultUsers.first,
              borderColor: Colors.red,
              backgroundColor: Colors.redAccent.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.dialogBorderRadius),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This seat is permanently reserved',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            UserInfoCard(
              title: 'Current user:',
              user: UsersData.currentUser,
              borderColor: Colors.green,
              backgroundColor: Colors.green.withOpacity(0.1),
            ),
          ],
        ),
      ),
      actions: [
        if (_isCurrentUserSeat)
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
                horizontal: 16,
              ),
            ),
            onPressed: () {
              context.read<HomePageBloc>().add(CancelLockEvent(seat));
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel Reservation',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      ],
    );
  }
}
