import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

import 'package:speaking_flashcards/models/lang_combo.dart';
import 'package:speaking_flashcards/models/question.dart';

String dbName = 'echoprof_questions_2023_03_22';

class DbQuestions {
  static Future<Database> database() async {
    final dbPath = await sql.getDatabasesPath();

    // ignore: avoid_print
    // print('dbPath: $dbPath');

    return sql.openDatabase(path.join(dbPath, '$dbName.db'), version: 1, onCreate: (Database db, int version) async {
      // int id;
      // String q;
      // String a;
      // String sqLang;
      // String rqLang;
      // String saLang;
      // String raLang;
      // String dateCreated;
      // int level;
      // int spiritLevel;
      // String history;
      // String note;
      // int order; // don't wanna put this in the DB (session use only)

      await db.execute('''
          CREATE TABLE $dbName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            q TEXT,
            a TEXT,
            cat TEXT,
            sqLang TEXT,
            rqLang TEXT,
            saLang TEXT,
            raLang TEXT,
            dateCreated TEXT,
            level INTEGER,
            spiritLevel INTEGER,
            history TEXT,
            note TEXT
          )''');
    });
  }

  static Future<int> addQuestion(Question question) async {
    final db = await DbQuestions.database();

    return db.insert(
      dbName,
      {
        // 'id': question.id,
        'q': question.q,
        'a': question.a,
        'cat': question.cat,
        'sqLang': question.sqLang,
        'rqLang': question.rqLang,
        'saLang': question.saLang,
        'raLang': question.raLang,
        'dateCreated': question.dateCreated,
        'level': question.level,
        'spiritLevel': question.spiritLevel,
        'history': question.history,
        'note': question.note,
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<int> deleteQuestion(int id) async {
    final db = await DbQuestions.database();

    return db.delete(
      dbName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> updateQuestion(Question question) async {
    if (question.q == '' || question.a == '') return 0;
    final db = await DbQuestions.database();

    return db.update(
      dbName,
      {
        'q': question.q,
        'a': question.a,
        'level': question.level,
        'spiritLevel': question.spiritLevel,
        'history': question.history,
      },
      where: 'id == ?',
      whereArgs: [question.id],
    );
  }

  static Future<List<LangCombo>> getAllLangCombosWithQuestions() async {
    final db = await DbQuestions.database();

    List<Map<String, dynamic>> rawLangCombos;
    List<LangCombo> langCombos = [];

    rawLangCombos = await db.query(
      dbName,
      distinct: true,
      columns: [
        'sqLang',
        'rqLang',
        'saLang',
        'raLang',
      ],
    );

    for (var rawLangCombo in rawLangCombos) {
      // query for num of questions here:
      var x = await db.rawQuery(
        '''SELECT COUNT (*) from $dbName 
          WHERE 
            sqLang = ? AND
            rqLang = ? AND
            saLang = ? AND
            raLang = ?
        ''',
        [
          rawLangCombo['sqLang'],
          rawLangCombo['rqLang'],
          rawLangCombo['saLang'],
          rawLangCombo['raLang'],
        ],
      );

      int numOfQuestions = sql.Sqflite.firstIntValue(x) ?? 0;

      var y = await db.rawQuery(
        '''SELECT COUNT (*) from $dbName 
          WHERE 
            sqLang = ? AND
            rqLang = ? AND
            saLang = ? AND
            raLang = ? AND
            level < 3
        ''',
        [
          rawLangCombo['sqLang'],
          rawLangCombo['rqLang'],
          rawLangCombo['saLang'],
          rawLangCombo['raLang'],
        ],
      );

      int numOfQuestionsDue = sql.Sqflite.firstIntValue(y) ?? 0;

      // int numOfQuestionsDue = sql.Sqflite.

      langCombos.add(LangCombo(
        sqLang: rawLangCombo['sqLang'],
        rqLang: rawLangCombo['rqLang'],
        saLang: rawLangCombo['saLang'],
        raLang: rawLangCombo['raLang'],
        amountOfQuestions: numOfQuestions,
        amountOfQuestionsDue: numOfQuestionsDue,
      ));
    }

    return langCombos;
  }

  static Future<List<Question>> getAllQuestions() async {
    final db = await DbQuestions.database();

    List<Map<String, dynamic>> rawQuestionsList;
    List<Question> questionsList = [];

    rawQuestionsList = await db.query(
      dbName,
      orderBy: 'level',
    );

    for (var question in rawQuestionsList) {
      questionsList.add(Question(
        id: question['id'],
        q: question['q'],
        a: question['a'],
        cat: question['cat'],
        sqLang: question['sqLang'],
        rqLang: question['rqLang'],
        saLang: question['saLang'],
        raLang: question['raLang'],
        dateCreated: question['dateCreated'],
        level: question['level'],
        spiritLevel: question['spiritLevel'],
        history: question['history'],
        note: question['note'],
        order: question['order'] ?? 0,
      ));
    }

    return questionsList;
  }

  static Future<List<Question>> getSessionQuestions({
    String sqLang = '',
    String rqLang = '',
    String saLang = '',
    String raLang = '',
    int limit = 50,
  }) async {
    final db = await DbQuestions.database();

    List<Map<String, dynamic>> rawQuestionsList;
    List<Question> questionsList = [];

    // return [];

    rawQuestionsList = await db.query(
      dbName,
      orderBy: 'level',
      limit: limit,
      where: '''
            sqLang = ? AND
            rqLang = ? AND
            saLang = ? AND
            raLang = ? AND
            spiritLevel > 0 AND level < 3''',
      whereArgs: [
        sqLang,
        rqLang,
        saLang,
        raLang,
      ],
    );

    for (var question in rawQuestionsList) {
      questionsList.add(Question(
        id: question['id'],
        q: question['q'],
        a: question['a'],
        cat: question['cat'],
        sqLang: question['sqLang'],
        rqLang: question['rqLang'],
        saLang: question['saLang'],
        raLang: question['raLang'],
        dateCreated: question['dateCreated'],
        level: question['level'],
        spiritLevel: question['spiritLevel'],
        history: question['history'],
        note: question['note'],
        order: question['order'] ?? 0,
      ));
    }

    // if we already have <limit> amount of questions, then we don't need to look in the DB for questions > level 3
    if (limit != -1 && questionsList.length >= limit) {
      for (var i = 0; i < questionsList.length; i++) {
        questionsList[i].order = i;
      }
      return questionsList;
    }

    // okay, now look into database for questions > level 3...

    rawQuestionsList = await db.query(
      dbName,
      orderBy: 'level',
      limit: limit,
      where: '''
            sqLang = ? AND
            rqLang = ? AND
            saLang = ? AND
            raLang = ?''',
      whereArgs: [
        sqLang,
        rqLang,
        saLang,
        raLang,
      ],
    );

    // for each question from the query...
    for (var question in rawQuestionsList) {
      // check if there are any matches in the questionsList already
      var match = false;
      for (var tmpQ in questionsList) {
        if (tmpQ.id == question['id']) match = true;
      }

      // if there are no matches, then we should build the question and add it to the questionsList!
      if (!match) {
        var tmpQuestion = Question(
          id: question['id'],
          q: question['q'],
          a: question['a'],
          cat: question['cat'],
          sqLang: question['sqLang'],
          rqLang: question['rqLang'],
          saLang: question['saLang'],
          raLang: question['raLang'],
          dateCreated: question['dateCreated'],
          level: question['level'],
          spiritLevel: question['spiritLevel'],
          history: question['history'],
          note: question['note'],
          order: question['order'] ?? 0,
        );
        questionsList.add(tmpQuestion);
      }
    }

    for (var i = 0; i < questionsList.length; i++) {
      questionsList[i].order = i;
    }

    return questionsList;
  }

  static Future<int> getQAmntDueInLangCombo(
    String sqLang,
    String rqLang,
    String saLang,
    String raLang,
  ) async {
    final db = await DbQuestions.database();

    int totalQuestions = 0;

    var x = await db.rawQuery(
      '''SELECT COUNT (*) from $dbName 
        WHERE 
          sqLang = ? AND
          rqLang = ? AND
          saLang = ? AND
          raLang = ? AND
          level < 3
      ''',
      [
        sqLang,
        rqLang,
        saLang,
        raLang,
      ],
    );
    totalQuestions = sql.Sqflite.firstIntValue(x) ?? 0;
    return totalQuestions;
  }

  static Future<int> getQAmntInLangCombo({
    String sqLang = '',
    String rqLang = '',
    String saLang = '',
    String raLang = '',
  }) async {
    final db = await DbQuestions.database();

    int totalQuestions = 0;

    var x = await db.rawQuery(
      '''SELECT COUNT (*) from $dbName
        WHERE
            sqLang = ? AND
            rqLang = ? AND
            saLang = ? AND
            raLang = ?
      ''',
      [
        sqLang,
        rqLang,
        saLang,
        raLang,
      ],
    );
    totalQuestions = sql.Sqflite.firstIntValue(x) ?? 0;
    return totalQuestions;
  }

  static Future<int> getAmountOfQuestions() async {
    final db = await DbQuestions.database();

    int totalQuestions = 0;

    var x = await db.rawQuery(
      'SELECT COUNT (*) from $dbName',
    );
    totalQuestions = sql.Sqflite.firstIntValue(x) ?? 0;

    return totalQuestions;
  }

  static Future<int> getAmountUnderThresh(String sqLang, String rqLang, String saLang, String raLang,
      [levelThreshold = 3]) async {
    final db = await DbQuestions.database();

    int totalUnderThresh = 0;

    var x = await db.rawQuery(
      '''SELECT COUNT (*) from $dbName 
        WHERE 
          sqLang = ? AND
          rqLang = ? AND
          saLang = ? AND
          raLang = ? AND
          level < ?
      ''',
      [levelThreshold, sqLang, rqLang, saLang, raLang],
    );

    totalUnderThresh = sql.Sqflite.firstIntValue(x) ?? 0;

    return totalUnderThresh;
  }
}
