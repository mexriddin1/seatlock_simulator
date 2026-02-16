import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:seatlock_simulator/core/constants/app_constants.dart';
import 'package:seatlock_simulator/core/extension/request_state.dart';
import 'package:seatlock_simulator/core/storage/seat_database.dart';
import 'model/seat_model.dart';
import 'model/seat_status.dart';
import 'model/user_model.dart';

abstract class HomeRepository {
  Future<RequestState<Stream<List<SeatModel>>>> loadSeats();

  Future<RequestState<SeatModel>> lockSeat(SeatModel model, {UserModel? user});

  Future<RequestState<SeatModel>> confirmReservation(
    SeatModel model, {
    UserModel? user,
  });

  Future<RequestState<SeatModel>> cancelLock(
    SeatModel model, {
    UserModel? user,
  });

  Future<RequestState<void>> clearAllSeats();
}

class HomeRepositoryImpl extends HomeRepository {
  final SeatDatabase _database = SeatDatabase();
  final _seatController = BehaviorSubject<List<SeatModel>>();
  final List<SeatModel> _seats = [];
  bool _initialized = false;

  List<SeatModel> _generateDefaultSeats() {
    return List.generate(
      AppConstants.seatGridSize * AppConstants.seatGridSize,
      (index) => SeatModel(id: index, status: SeatStatus.available),
    );
  }

  @override
  Future<RequestState<Stream<List<SeatModel>>>> loadSeats() async {
    try {
      if (_initialized) {
        return RequestStateSuccessWithData(_seatController.stream);
      }

      final seatsResponse = await _database.getAllActiveSeats();

      if (seatsResponse is RequestStateSuccessWithData<List<SeatModel>>) {
        final defaultSeats = _generateDefaultSeats();
        final seats = seatsResponse.data;

        final allSeats = [
          for (var defaultSeat in defaultSeats)
            seats.firstWhere(
              (s) => s.id == defaultSeat.id,
              orElse: () => defaultSeat,
            ),
        ];

        _seats.clear();
        _seats.addAll(allSeats);
        _seatController.add(allSeats);
        _initialized = true;

        return RequestStateSuccessWithData(_seatController.stream);
      }

      return RequestStateFailed(seatsResponse.errorOrNull ?? 'Unknown error');
    } catch (e) {
      return RequestStateFailed('Error loading seats: ${e.toString()}');
    }
  }

  @override
  Future<RequestState<SeatModel>> lockSeat(
    SeatModel model, {
    UserModel? user,
  }) async {
    try {
      final actor = user ?? UsersData.currentUser;
      int index = model.id;

      if (index < 0 || index >= _seats.length) {
        return RequestStateFailed('Invalid seat ID: $index');
      }

      final seat = _seats[index];

      if (seat.status == SeatStatus.locked) {
        return RequestStateFailed('Seat is already locked');
      }

      if (seat.status != SeatStatus.available) {
        return RequestStateFailed('Seat is not available');
      }

      final lockedSeat = seat.copyWith(
        status: SeatStatus.locked,
        lockedBy: actor,
        lockExpirationTime: DateTime.now().add(
          Duration(seconds: AppConstants.seatLockDurationSeconds),
        ),
      );

      _seats[index] = lockedSeat;
      _seatController.add(_seats);

      return RequestStateSuccessWithData(lockedSeat);
    } catch (e) {
      return RequestStateFailed('Error locking seat: ${e.toString()}');
    }
  }

  @override
  Future<RequestState<SeatModel>> confirmReservation(
    SeatModel model, {
    UserModel? user,
  }) async {
    try {
      final actor = user ?? UsersData.currentUser;
      int index = model.id;

      if (index < 0 || index >= _seats.length) {
        return RequestStateFailed('Invalid seat ID: $index');
      }

      if (_seats[index].id != model.id) {
        return RequestStateFailed('Seat is not for this reservation');
      }

      if (model.lockedBy != null && model.lockedBy!.id != actor.id) {
        return RequestStateFailed(
          'Cannot confirm reservation for a seat locked by another user',
        );
      }

      if (model.lockExpirationTime != null &&
          DateTime.now().isAfter(model.lockExpirationTime!)) {
        return RequestStateFailed('Lock timeout! The seat lock has expired.');
      }

      final reservedSeat = model.copyWith(
        status: SeatStatus.reserved,
        lockExpirationTime: null,
      );

      await _database.insertSeat(reservedSeat);

      _seats[index] = reservedSeat;
      _seatController.add(_seats);

      return RequestStateSuccessWithData(reservedSeat);
    } catch (e) {
      return RequestStateFailed(
        'Error confirming reservation: ${e.toString()}',
      );
    }
  }

  @override
  Future<RequestState<SeatModel>> cancelLock(
    SeatModel model, {
    UserModel? user,
  }) async {
    try {
      final actor = user ?? UsersData.currentUser;
      int index = model.id;

      if (index < 0 || index >= _seats.length) {
        return RequestStateFailed('Invalid seat ID: $index');
      }

      final seat = _seats[index];

      if (seat.lockedBy != null && seat.lockedBy!.id != actor.id) {
        return RequestStateFailed('Cannot cancel lock held by another user');
      }

      final unlockedSeat = seat.copyWith(
        status: SeatStatus.available,
        lockedBy: null,
        lockExpirationTime: null,
      );

      await _database.deleteSeat(unlockedSeat.id.toString());
      _seats[index] = unlockedSeat;
      _seatController.add(_seats);

      return RequestStateSuccessWithData(unlockedSeat);
    } catch (e) {
      return RequestStateFailed('Error canceling lock: ${e.toString()}');
    }
  }

  @override
  Future<RequestState<void>> clearAllSeats() async {
    try {
      await _database.deleteAllSeats();
      final defaultSeats = _generateDefaultSeats();
      _seats.clear();
      _seats.addAll(defaultSeats);
      _seatController.add(defaultSeats);
      _initialized = false;
      return const RequestStateSuccessWithData(null);
    } catch (e) {
      return RequestStateFailed('Error clearing seats: ${e.toString()}');
    }
  }

  void dispose() {
    _seatController.close();
  }
}
