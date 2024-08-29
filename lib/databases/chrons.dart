import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart'; // has the DateFormat class

import '../models/chron.dart';
import '../helpers/placeholder_chron.dart';

String dbName = 'echoprof_chrons_2023_03_30';

class DbChrons {
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
              timeStudied INTEGER
            )
            ''');
      },
    );
  }

  static Future<List<Chron>> getHistory(int daysPassed) async {
    final db = await DbChrons.database();

    List<Map<String, dynamic>> rawChronsList;
    final List<Chron> chronsList = [];

    rawChronsList = await db.query(
      dbName,
      orderBy: 'date DESC',
      limit: daysPassed,
    );

    // not sure if this is the right syntax for accessing the
    // elements inside the forEach method... we'll see! 🤷‍♂️
    for (var rawChron in rawChronsList) {
      chronsList.add(Chron(
        id: rawChron['id'] as int,
        date: rawChron['date'] as String,
        timeStudied: rawChron['timeStudied'] as int,
      ));
    }

    return chronsList;
  }

  static Future<double> getHoursStudied() async {
    final db = await DbChrons.database();
    var totalHoursStudied = 0.0;
    List<Map<String, dynamic>> rawChronsList;

    rawChronsList = await db.query(dbName);
    for (var rawChron in rawChronsList) {
      totalHoursStudied += (rawChron['timeStudied'] / 60) / 60;
    }
    return totalHoursStudied;
  }

  static Future<Chron?> getTodaysChron(String date) async {
    final db = await DbChrons.database();
    Chron chron;

    List<Map<String, dynamic>> rawChronsList;
    rawChronsList = await db.query(dbName, where: 'date = ?', whereArgs: [date]);

    if (rawChronsList.isEmpty) {
      return null;
    }

    chron = Chron(
      id: rawChronsList[0]['id'],
      date: rawChronsList[0]['date'],
      timeStudied: rawChronsList[0]['timeStudied'],
    );

    return chron;
  }

  static Future<void> setToday(String date, int timeStudied) async {
    final db = await DbChrons.database();

    String query = """UPDATE $dbName
      SET
        timeStudied=?
      WHERE
        date=?
    """;

    await db.rawUpdate(query, [timeStudied, date]);
  }

  static Future<int> deleteDay(String date) async {
    final db = await DbChrons.database();

    return db.delete(
      dbName,
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  static Future<void> newDay(String date) async {
    final db = await DbChrons.database();

    db.insert(dbName, {'date': date, 'timeStudied': 0});
  }

  static Future<int> updateStreak() async {
    // print('updating streak, probably');
    var dailyStreak = 0;

    // get today's date in nice format:
    var now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    // var todaysDate = formatter.format(now);

    // studied today yet?
    // Chron today = await getDay(todaysDate);
    // // timeStudied is in seconds - so 5 minutes required to maintain streak
    // if (today.timeStudied > 300) {
    //   dailyStreak = 1;
    //   // print('today > 600s, so dailyStreak: $dailyStreak');
    // } else {
    //   // print('today < 600s, so dailyStreak: $dailyStreak is 0');
    // }

    // recursively check if previous day was in database
    Future<int> checkPrevDayInDb(DateTime date) async {
      // was date above added to database?
      var dayBefore = date.subtract(const Duration(days: 1));
      var formattedDate = formatter.format(dayBefore);

      Chron chronForDateStated = await getTodaysChron(formattedDate) ?? placeholderChron;
      // timeStudied is in seconds - so 5 minutes required to maintain streak
      if (chronForDateStated.timeStudied > 300) {
        // print(
        //     'studied for >600s on $formattedDate, so dailyStreak: $dailyStreak');
        // yes? add to streak number, recurse
        dailyStreak++;
        // dayBefore.subtract(const Duration(days: 1));
        dailyStreak = await checkPrevDayInDb(dayBefore);
      } else {
        // print('didn\'t study for >600s on $formattedDate');
      }

      return dailyStreak;
    }

    // call checkPrevDayInDb with yesterday
    // DateTime.now().subtract(Duration(days:1))
    await checkPrevDayInDb(now);

    return dailyStreak;
  }
}
