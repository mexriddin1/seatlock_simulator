import 'dart:async';
import 'dart:math';
import 'package:seatlock_simulator/core/extension/request_state.dart';
import 'package:seatlock_simulator/core/storage/seat_database.dart';
import 'package:seatlock_simulator/features/ui/home/domain/home_repository.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_model.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_status.dart';
import 'model/user_model.dart';

/// Simulates background users taking actions on seats.
///
/// The simulator keeps its own copy of the latest seat list by subscribing
/// to the repository stream once. It does **not** repeatedly call
/// [repository.loadSeats] because that would wipe unconfirmed user locks.
/// Instead each tick it selects a random available seat and attempts to
/// lock/confirm/cancel using a randomly chosen bot user (Bot 1 or Bot 2).
///
/// Log messages are exposed via [logStream] so the UI can display realtime
/// activity. The simulator can be started/stopped and disposed properly.
class BackgroundSeatSimulator {
  final HomeRepository repository;

  Timer? _simulationTimer;
  final Random _random = Random();

  /// Current copy of seats, updated by the repository stream once at start.
  final List<SeatModel> _latestSeats = [];
  StreamSubscription<List<SeatModel>>? _seatSubscription;

  /// Seats locked by the simulator (so we can cleanup expirations).
  final List<SeatModel> _simulatedLockedSeats = [];

  /// Bots that participate in the simulation.
  final List<UserModel> _botUsers = [
    UsersData.defaultUsers[1],
    UsersData.defaultUsers[2],
  ];

  bool _isRunning = false;

  /// Emits human-readable log strings for each action.
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  BackgroundSeatSimulator({required this.repository});

  Stream<String> get logStream => _logController.stream;

  void _emitLog(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    final logMessage = '[$timestamp] $message';
    _logController.add(logMessage);
  }

  Future<void> start({int minDelaySeconds = 3, int maxDelaySeconds = 5}) async {
    if (_isRunning) return;
    _isRunning = true;

    _simulationTimer = Timer.periodic(
      Duration(
        seconds:
            minDelaySeconds +
            _random.nextInt(maxDelaySeconds - minDelaySeconds + 1),
      ),
      (_) async {
        await _simulateUserAction();
      },
    );
  }

  void stop() {
    _isRunning = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _simulatedLockedSeats.clear();
    _seatSubscription?.cancel();
    _seatSubscription = null;
  }

  Future<void> _simulateUserAction() async {
    try {
      final response = await repository.loadSeats();

      if (response.isSuccess) {
        final stream = response.dataOrNull as Stream?;
        if (stream == null) return;

        final seats = await stream.first as List<SeatModel>;

        final availableSeats = seats
            .where((seat) => seat.status == SeatStatus.available)
            .toList();

        if (availableSeats.isEmpty) {
          _cleanupExpiredSeats();
          return;
        }

        final randomSeat =
            availableSeats[_random.nextInt(availableSeats.length)];

        _emitLog('${_botUser.name} locked seat S${randomSeat.id}');

        final lockResponse = await repository.lockSeat(randomSeat);

        if (lockResponse.isSuccess && lockResponse.dataOrNull != null) {
          final lockedSeat = lockResponse.dataOrNull as SeatModel;
          _simulatedLockedSeats.add(lockedSeat);

          if (_random.nextBool()) {
            await Future.delayed(const Duration(milliseconds: 500));
            await repository.confirmReservation(lockedSeat);
            _simulatedLockedSeats.removeWhere((s) => s.id == lockedSeat.id);
            _emitLog(
              '${_botUser.name} confirmed reservation for seat S${lockedSeat.id}',
            );
          } else {
            _emitLog('${_botUser.name} let seat S${lockedSeat.id} timeout');
          }
        }
      }
    } catch (e) {
      _emitLog('Error: ${e.toString()}');
    }
  }

  void _cleanupExpiredSeats() {
    final now = DateTime.now();
    final expiredSeats = _simulatedLockedSeats
        .where(
          (seat) =>
              seat.lockExpirationTime != null &&
              now.isAfter(seat.lockExpirationTime!),
        )
        .toList();

    for (final seat in expiredSeats) {
      repository.cancelLock(seat);
      _simulatedLockedSeats.remove(seat);
    }
  }

  bool get isRunning => _isRunning;

  int get simulatedLockedSeatsCount => _simulatedLockedSeats.length;

  UserModel get botUser => _botUser;

  void changeBotUser(int userIndex) {
    if (userIndex >= 1 && userIndex < UsersData.defaultUsers.length) {
      _botUser = UsersData.defaultUsers[userIndex];
    }
  }

  void dispose() {
    stop();
    _logController.close();
  }
}
