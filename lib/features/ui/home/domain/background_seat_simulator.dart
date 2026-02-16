import 'dart:async';
import 'dart:math';
import 'package:seatlock_simulator/core/extension/request_state.dart';
import 'package:seatlock_simulator/core/storage/seat_database.dart';
import 'package:seatlock_simulator/features/ui/home/domain/home_repository.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_model.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_status.dart';
import 'model/user_model.dart';

class BackgroundSeatSimulator {
  final HomeRepository repository;

  Timer? _simulationTimer;
  final Random _random = Random();

  final List<SeatModel> _latestSeats = [];
  StreamSubscription<List<SeatModel>>? _seatSubscription;

  final List<SeatModel> _simulatedLockedSeats = [];

  final List<UserModel> _botUsers = [
    UsersData.defaultUsers[1],
    UsersData.defaultUsers[2],
  ];

  bool _isRunning = false;

  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  BackgroundSeatSimulator({required this.repository});

  Stream<String> get logStream => _logController.stream;

  void _emitLog(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T').join(' ');
    _logController.add('[$timestamp] $message');
  }

  Future<void> start({
    int minDelaySeconds = 3,
    int maxDelaySeconds = 5,
  }) async {
    if (_isRunning) return;
    _isRunning = true;

    final response = await repository.loadSeats();
    if (response.isSuccess) {
      final stream = response.dataOrNull;
      if (stream != null) {
        _seatSubscription = stream.listen((seats) {
          _latestSeats
            ..clear()
            ..addAll(seats);
        });
      }
    }

    _simulationTimer = Timer.periodic(
      Duration(seconds: minDelaySeconds + _random.nextInt(maxDelaySeconds - minDelaySeconds + 1)),
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
      if (_latestSeats.isEmpty) return;

      _cleanupExpiredSeats();

      final availableSeats = _latestSeats
          .where((seat) => seat.status == SeatStatus.available)
          .toList();

      if (availableSeats.isEmpty) {
        return;
      }

      final randomSeat = availableSeats[_random.nextInt(availableSeats.length)];
      final bot = _botUsers[_random.nextInt(_botUsers.length)];

      _emitLog('${bot.name} locked seat S${randomSeat.id + 1}');

      final lockResponse = await repository.lockSeat(randomSeat, user: bot);

      if (lockResponse.isSuccess && lockResponse.dataOrNull != null) {
        final lockedSeat = lockResponse.dataOrNull as SeatModel;
        _simulatedLockedSeats.add(lockedSeat);

        if (_random.nextBool()) {
          await Future.delayed(const Duration(milliseconds: 500));
          await repository.confirmReservation(lockedSeat, user: bot);
          _simulatedLockedSeats.removeWhere((s) => s.id == lockedSeat.id);
          _emitLog('${bot.name} confirmed seat S${lockedSeat.id + 1}');
        } else {
          _emitLog('${bot.name} let seat S${lockedSeat.id + 1} timeout');
        }
      }
    } catch (e) {
      _emitLog('Error: ${e.toString()}');
    }
  }

  void _cleanupExpiredSeats() {
    final now = DateTime.now();
    final expiredSeats = _simulatedLockedSeats
        .where((seat) => seat.lockExpirationTime != null && now.isAfter(seat.lockExpirationTime!))
        .toList();

    for (final seat in expiredSeats) {
      repository.cancelLock(seat, user: seat.lockedBy);
      _simulatedLockedSeats.remove(seat);
    }
  }



  bool get isRunning => _isRunning;

  int get simulatedLockedSeatsCount => _simulatedLockedSeats.length;

  void dispose() {
    stop();
    _logController.close();
  }
}
