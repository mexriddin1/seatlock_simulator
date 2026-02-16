import 'package:flutter/material.dart';
import 'package:seatlock_simulator/core/constants/app_constants.dart';
import 'package:seatlock_simulator/core/storage/seat_database.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_model.dart';
import 'package:seatlock_simulator/features/ui/home/widgets/user_info_card.dart';

class ReservedSeatDialog extends StatelessWidget {
  final SeatModel seat;
  final Function(SeatModel)? onCancel;

  const ReservedSeatDialog({super.key, required this.seat, this.onCancel});

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
              borderColor: Colors.grey,
              backgroundColor: Colors.grey.withOpacity(0.1),
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
            onPressed: () async {
              try {
                onCancel?.call(seat);
              } catch (error) {
                debugPrint('Error cancelling reservation for seat ${error.toString()}');
              } finally {
                Navigator.pop(context);
              }
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
