import 'package:flutter/cupertino.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:seatlock_simulator/core/extension/request_state.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_model.dart';
import 'package:seatlock_simulator/features/ui/home/domain/model/seat_status.dart';

class UsersData {
  static const List<UserModel> defaultUsers = [
    UserModel(id: '1', name: 'Me'),
    UserModel(id: '2', name: 'Bot 1'),
    UserModel(id: '3', name: 'Bot 2'),
  ];

  static UserModel getUserById(String id) {
    return defaultUsers.firstWhere(
          (user) => user.id == id,
      orElse: () => UserModel(id: id, name: 'Unknown User'),
    );
  }

  static final UserModel currentUser = defaultUsers[0];
}

class SeatDatabase {
  static const String tableName = 'seats';
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'seatlock_simulator.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY,
            status TEXT NOT NULL,
            lockedBy TEXT
          )
          ''');
      },
    );
  }

  Future<RequestState<void>> insertSeat(SeatModel seat) async {
    try {
      final db = await database;
      await db.insert(
        tableName,
        _seatToMap(seat),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return RequestStateSuccessWithoutData();
    } catch (e) {
      return RequestStateFailed('Failed to insert seat: ${e.toString()}');
    }
  }

  Future<RequestState<List<SeatModel>>> getAllActiveSeats() async {
    final db = await database;
    final maps = await db.query(tableName);

    return RequestStateSuccessWithData(
      List.generate(maps.length, (i) => _mapToSeat(maps[i])),
    );
  }

  Future<RequestState<void>> updateSeat(SeatModel seat) async {
    try {
      final db = await database;
      await db.update(
        tableName,
        _seatToMap(seat),
        where: 'id = ?',
        whereArgs: [seat.id],
      );
      return RequestStateSuccessWithoutData();
    } catch (e) {
      return RequestStateFailed('Failed to update seat: ${e.toString()}');
    }
  }

  Future<RequestState<void>> deleteSeat(String id) async {
    try {
      final db = await database;
      await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
      return RequestStateSuccessWithoutData();
    } catch (e) {
      return RequestStateFailed('Failed to delete seat: ${e.toString()}');
    }
  }

  Future<RequestState<void>> deleteAllSeats() async {
    try {
      final db = await database;
      await db.delete(tableName);
      return RequestStateSuccessWithoutData();
    } catch (e) {
      return RequestStateFailed('Failed to delete seats: ${e.toString()}');
    }
  }

  Map<String, dynamic> _seatToMap(SeatModel seat) {
    return {
      'id': seat.id,
      'status': seat.status.toString(),
      'lockedBy': seat.lockedBy!.id,
    };
  }

  SeatModel _mapToSeat(Map<String, dynamic> map) {
    debugPrint(map.toString());
    return SeatModel(
      id: map['id'] as int,
      status: _statusFromString(map['status'] as String),
      lockedBy: map['lockedBy'] != null
          ? UsersData.getUserById(map['lockedBy'] as String)
          : null,
    );
  }

  SeatStatus _statusFromString(String status) {
    return SeatStatus.values.firstWhere(
          (e) => e.toString() == status,
      orElse: () => SeatStatus.available,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
