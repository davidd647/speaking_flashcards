import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

import '../models/added_batch.dart';

String dbName = 'echoprof_history_2022_08_29';

class DBHistory {
  static Future<Database> database() async {
    final dbPath = await sql.getDatabasesPath();

    return sql.openDatabase(
      path.join(dbPath, '$dbName.db'),
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
            CREATE TABLE $dbName (
              id INTEGER PRIMARY KEY AUTOINCREMENT, 
              date TEXT,
              name STRING,
              category STRING
            )
            ''');
      },
    );
  }

  static Future<List<AddedBatch>> getHistory([int daysPassed = 0]) async {
    final db = await DBHistory.database();

    List<Map<String, dynamic>> rawBatchsList;
    final List<AddedBatch> batchsList = [];

    if (daysPassed == 0) {
      rawBatchsList = await db.query(
        dbName,
        orderBy: 'date DESC',
        // limit: daysPassed,
      );
    } else {
      rawBatchsList = await db.query(
        dbName,
        orderBy: 'date DESC',
        limit: daysPassed,
      );
    }

    for (var rawBatch in rawBatchsList) {
      batchsList.add(AddedBatch(
        id: rawBatch['id'] as int,
        date: rawBatch['date'] as String,
        name: rawBatch['name'] as String,
        category: rawBatch['category'] as String,
      ));
    }

    return batchsList;
  }

  static Future<dynamic> removeBatch(String name, String category) async {
    final db = await DBHistory.database();

    return db.delete(
      dbName,
      where: 'name = ? AND category = ?',
      whereArgs: [name, category],
    );
  }

  static Future<dynamic> addBatch(String date, String name, String category) async {
    final db = await DBHistory.database();

    return db.insert(
      dbName,
      {
        'date': date,
        'name': name,
        'category': category,
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }
}
