import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart'; // has the DateFormat class

import '../models/chron.dart';

String dbName = 'echoprof_chrons_2024_09_07_v01';

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
              languageCombo TEXT,
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
      // print('rawChron: $rawChron');
      final newChron = Chron(
        id: rawChron['id'],
        date: rawChron['date'],
        languageCombo: rawChron['languageCombo'],
        timeStudied: rawChron['timeStudied'],
      );

      // Check if a matching date and languageCombo already exists in the chrons list
      final exists =
          chronsList.any((chron) => chron.date == newChron.date && chron.languageCombo == newChron.languageCombo);

      // Add the newChron only if it doesn't already exist
      if (!exists) {
        chronsList.add(newChron);
      }
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

  static Future<Chron?> getChronByDate(String date, String? languageCombo) async {
    final db = await DbChrons.database();
    Chron chron;

    List<Map<String, dynamic>> rawChronsList;

    if (languageCombo == null) {
      rawChronsList = await db.query(
        dbName,
        where: 'date = ?',
        whereArgs: [date],
      );

      // no lang combo was specified, so calc total time studied that day...
      int totalTimeStudied = 0;
      for (var chron in rawChronsList) {
        totalTimeStudied += chron['timeStudied'] as int;
      }

      if (rawChronsList.isEmpty) return null;

      chron = Chron(
        id: rawChronsList[0]['id'],
        date: rawChronsList[0]['date'],
        languageCombo: 'all',
        timeStudied: totalTimeStudied,
      );
    } else {
      rawChronsList = await db.query(
        dbName,
        where: 'date = ? AND languageCombo = ?',
        whereArgs: [date, languageCombo],
      );

      if (rawChronsList.isEmpty) return null;

      chron = Chron(
        id: rawChronsList[0]['id'],
        date: rawChronsList[0]['date'],
        languageCombo: rawChronsList[0]['languageCombo'],
        timeStudied: rawChronsList[0]['timeStudied'],
      );
    }

    return chron;
  }

  static Future<List<Chron>> getChronsByDate(String date) async {
    final db = await DbChrons.database();
    List<Chron> chrons = [];

    List<Map<String, dynamic>> rawChronsList;

    rawChronsList = await db.query(
      dbName,
      where: 'date = ?',
      whereArgs: [date],
    );

    for (var x = 0; x < rawChronsList.length; x++) {
      final newChron = Chron(
        id: rawChronsList[x]['id'],
        date: rawChronsList[x]['date'],
        languageCombo: rawChronsList[x]['languageCombo'],
        timeStudied: rawChronsList[x]['timeStudied'],
      );

      // Check if a matching date and languageCombo already exists in the chrons list
      final exists =
          chrons.any((chron) => chron.date == newChron.date && chron.languageCombo == newChron.languageCombo);

      // Add the newChron only if it doesn't already exist
      if (!exists) {
        chrons.add(newChron);
      }
    }

    return chrons;
  }

  static Future<int> setToday(String date, int timeStudied, String languageCombo) async {
    final db = await DbChrons.database();

    String query = """UPDATE $dbName
      SET
        timeStudied=?
      WHERE
        date=? AND
        languageCombo=?
    """;

    int amntUpdated = await db.rawUpdate(query, [timeStudied, date, languageCombo]);

    if (amntUpdated == 0) {
      newDay(date, languageCombo);
    }

    return amntUpdated;
  }

  static Future<int> deleteDay(String date) async {
    final db = await DbChrons.database();

    return db.delete(
      dbName,
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  static Future<void> newDay(String date, String languageCombo) async {
    final db = await DbChrons.database();

    // look for chrons that already have this date and language combo
    Chron? chron = await getChronByDate(date, languageCombo);
    // if there's already a chron there, don't insert another one (leave the function)
    if (chron != null) return;

    db.insert(dbName, {'date': date, 'timeStudied': 0, 'languageCombo': languageCombo});
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

      List<Chron> chronForDateStated = await getChronsByDate(formattedDate);
      if (chronForDateStated.fold(0, (sum, chron) => sum + chron.timeStudied) > 60 * 5) {
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
