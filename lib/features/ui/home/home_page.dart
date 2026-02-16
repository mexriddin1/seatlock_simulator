import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seatlock_simulator/core/constants/app_constants.dart';
import 'package:seatlock_simulator/core/extension/request_state.dart';
import 'package:seatlock_simulator/features/ui/home/widgets/legend_widget.dart';
import 'package:seatlock_simulator/features/component/request_state_widget.dart';
import 'package:seatlock_simulator/features/ui/home/widgets/reserved_seat_dialog.dart';
import 'package:seatlock_simulator/features/ui/home/widgets/seat_grid.dart';
import 'package:seatlock_simulator/features/ui/home/widgets/pending_reservations_section.dart';
import 'bloc/home_bloc.dart';
import 'bloc/home_event.dart';
import 'bloc/home_state.dart';
import 'domain/model/seat_model.dart';
import 'domain/model/seat_status.dart';
import 'package:seatlock_simulator/core/storage/seat_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomePageBloc>().add(const LoadSeatsEvent());
    });
  }

  void _handleSeatTap(SeatModel seat) {
    if (seat.status == SeatStatus.available) {
      context.read<HomePageBloc>().add(LockSeatEvent(seat));
    } else if (seat.status == SeatStatus.reserved) {
      _showReservedSeatDialog(seat);
    } else if (seat.status == SeatStatus.locked) {
      final owner = seat.lockedBy?.name ?? 'Someone';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$owner has locked this seat'),
          duration: AppConstants.snackBarDuration,
        ),
      );
    }
  }

  void _showReservedSeatDialog(SeatModel seat) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ReservedSeatDialog(seat: seat),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomePageBloc, HomePageState>(
      listener: (context, state) {
        if (state.seatsStatus is RequestStateFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.seatsStatus.errorOrNull ?? "An error occurred",
              ),
              backgroundColor: Colors.red,
              duration: AppConstants.snackBarDuration,
            ),
          );
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Seat Lock Simulator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<HomePageBloc>().add(const ClearAllDataEvent());
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Restart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: requestStateWidget(state.seatsStatus, (seats) {
                        return SeatGridWidget(
                          seats: seats,
                          onSeatTap: _handleSeatTap,
                        );
                      }),
                    ),
                  ),
                ),
                requestStateWidget(state.expirationSeatStatus, (seats) {
                  return PendingReservationsSection(seats: seats);
                }),
                const Legend(),
                const SizedBox(height: 20),
                Container(
                  color: Colors.black87,
                  height: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Bot Activity Log (${state.botLogs.length})',
                          style: const TextStyle(
                            color: Colors.cyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          reverse: true,
                          itemCount: state.botLogs.length,
                          itemBuilder: (context, index) {
                            final logIndex = state.botLogs.length - 1 - index;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0,
                              ),
                              child: Text(
                                state.botLogs[logIndex],
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
