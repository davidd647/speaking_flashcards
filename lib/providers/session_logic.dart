import 'dart:async'; // has the Timer class
import 'dart:math'; // access to Random function, and "pow" function
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // has the DateFormat class
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
// import 'package:confetti/confetti.dart';

// audio in/out
import 'package:speaking_flashcards/models/lang.dart';
import 'package:speaking_flashcards/models/lang_combo.dart';
import 'package:speaking_flashcards/models/spoken_word.dart';
import 'package:speaking_flashcards/models/added_batch.dart';
import 'package:speaking_flashcards/models/chron.dart';
import 'package:speaking_flashcards/helpers/placeholder_lang_combo.dart';
import 'package:speaking_flashcards/helpers/placeholder_question.dart';
import 'package:speaking_flashcards/helpers/get_cat_of_previous_session.dart';
import 'package:speaking_flashcards/helpers/get_todays_date.dart';
import 'package:speaking_flashcards/helpers/get_language_combo_string.dart';
import 'package:speaking_flashcards/session_logic/synth.dart';
import 'package:speaking_flashcards/session_logic/recog.dart';
import 'package:speaking_flashcards/session_logic/get_unified_langs.dart';
import 'package:speaking_flashcards/session_logic/get_common_langs.dart';

// questions / databases
import 'package:speaking_flashcards/databases/history.dart';
import 'package:speaking_flashcards/databases/chrons.dart';
import 'package:speaking_flashcards/databases/questions.dart';
import 'package:speaking_flashcards/helpers/reduce_flags.dart';
import 'package:speaking_flashcards/models/question.dart';
import 'package:speaking_flashcards/models/session_task.dart';

class ProviderSessionLogic with ChangeNotifier {
  // general
  TextEditingController questionController = TextEditingController(); // for adding Q's
  TextEditingController answerController = TextEditingController(); // for adding A's and A's in study sessions
  List<SessionTask> delegationStack = [];
  List<SessionTask> delegationHistory = [];
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Function? _showToast;
  int totalUnderThresh = 1;
  String dateLastOpenedAppDefault = '';

  // audio in/out
  Synth synth = Synth();
  Recog recog = Recog();
  List<Lang> allLangs = [];
  List<Lang> synthLangs = [];
  List<Lang> recogLangs = [];
  List<Lang> commonLangs = [];
  bool isSynthing = false;
  bool isRecoging = false;
  bool isRecogingQuestion = false;
  bool isRecogingAnswer = false;
  LangCombo selectedLangCombo = placeholderLangCombo;
  int currentQuestionIndex = 0;
  bool skipped = false;
  bool sfxPlaying = false;
  String sfxFeedbackBad = 'sounds/feedback-bad.mp3';
  String sfxFeedbackGood = 'sounds/feedback-good.mp3';
  String sfxFeedbackGreat = 'sounds/feedback-great.mp3';
  int recogDuration = 5000;
  List<SpokenWord> recogRes = [];
  String recogStatus = '👍';
  String synthStatus = '👍';
  String sfxStatus = '👍';

  // questions / databases
  int dueInitially = 0;
  int due = 0;
  String qDisplayFlags = '';
  String aDisplayFlags = '';
  List<LangCombo> allLangCombosWithQuestions = [];
  List<Question> questionsList = [];
  bool firstRecogGuessHintPlayed = false;
  List<AddedBatch> batchHistoryList = [];
  Question questionForHint = placeholderQuestion;

  // to reset every time there's an answer submitted
  Question? prevQuestion;
  String prevGuess = '';
  Question hintInfo = placeholderQuestion;

  // timer logic
  int secondsPassed = 0;
  int whenUserLastActed = 0;
  bool userIsActive = false;
  String todaysDate = '';
  int dailyStreak = 0;
  bool timerIsInitialized = false;
  Timer? timer;
  bool runCongratsAsap = false;

  // stats logic
  // STATS LOGIC
  List<Chron> studyChronList = [];
  double totalHoursStudied = 0;
  List<Map<String, dynamic>> chartBars = [];
  String earliestDate = '     ';
  String mostRecentDate = '     ';
  Map<DateTime, int> chronsAndValues = {};
  double minDoY = 999;
  double maxDoY = 0;
  double minMins = 999;
  double maxMins = 0;
  int numOfDays = 30;
  int debuggingTodaySetUpdated = 0;

  // rewards system
  // ConfettiController confettiControllerCenter = ConfettiController(
  //   duration: const Duration(seconds: 10),
  // );

  void throwConfetti() async {
    // print('START throwing confetti (10 seconds)');
    // confettiControllerCenter.play();
    // await Future.delayed(const Duration(seconds: 10));
    // print('STOP throwing confetti!');
    // confettiControllerCenter.stop();
  }

  void setIsSynthing(bool synthingState) {
    isSynthing = synthingState;
    notifyListeners();
  }

  void setIsRecoging(bool recogingState) {
    isRecoging = recogingState;
    isBusy = recogingState;
    notifyListeners();
  }

  Future<void> initLangs() async {
    // INIT SYNTH LANGS
    await synth.init(setIsSynthing);
    synthLangs = synth.getLangs(); //get synthLangs first because recog langs are more likely to mess up and
    // this makes it clearer that recog langs messed up (because I can turn on debug mode
    // and see that synth langs are available)

    // INIT RECOG LANGS
    await recog.init(setIsRecoging);
    recogLangs = recog.getLangs();

    allLangs = await getUnifiedLangs(recogLangs, synthLangs);

    // sort all langauges alphabetically by code...
    allLangs.sort((a, b) => '${a.name}${a.code}'.compareTo('${b.name}${b.code}'));

    // not sure why I do this, but seems harmless?
    synthLangs = allLangs.where((lang) => (lang.origin.contains(CodeOrigin.synth))).toList();
    recogLangs = allLangs.where((lang) => (lang.origin.contains(CodeOrigin.recog))).toList();

    selectedLangCombo = await getLangComboOfPreviousSession();

    commonLangs = getCommonLangs(allLangs, recogLangs, synthLangs);

    resetAmountsDue();

    updateDisplayFlags();
    getAllLangCombosWithQuestions();
    notifyListeners();
  }

  Future<void> resetAmountsDue() async {
    due = await DbQuestions.getQAmntDueInLangCombo(
      selectedLangCombo.sqLang,
      selectedLangCombo.rqLang,
      selectedLangCombo.saLang,
      selectedLangCombo.raLang,
    );
    dueInitially = due;
  }

  void updateDisplayFlags() {
    qDisplayFlags = reduceFlags(selectedLangCombo.sqLang, selectedLangCombo.rqLang);
    aDisplayFlags = reduceFlags(selectedLangCombo.saLang, selectedLangCombo.raLang);
    notifyListeners();
  }

  void getAllLangCombosWithQuestions() async {
    allLangCombosWithQuestions = await DbQuestions.getAllLangCombosWithQuestions();
    notifyListeners();
  }

  Future<void> changeSALang(val) async {
    selectedLangCombo.saLang = val;
    await saveString('saLang', val, saLangDefault);
    await updateSessionLangs();
    notifyListeners();
    return;
  }

  Future<void> changeRALang(val) async {
    selectedLangCombo.raLang = val;
    await saveString('raLang', val, raLangDefault);
    await updateSessionLangs();
    notifyListeners();
    return;
  }

  Future<void> changeSQLang(val) async {
    selectedLangCombo.sqLang = val;
    await saveString('sqLang', val, sqLangDefault);
    await updateSessionLangs();
    notifyListeners();
    return;
  }

  Future<void> changeRQLang(val) async {
    selectedLangCombo.rqLang = val;
    await saveString('rqLang', val, rqLangDefault);
    await updateSessionLangs();
    notifyListeners();
    return;
  }

  Future<void> langsQuickSwitch(LangCombo langCombo) async {
    await changeSQLang(langCombo.sqLang);
    await changeRQLang(langCombo.rqLang);
    await changeSALang(langCombo.saLang);
    await changeRALang(langCombo.raLang);

    // get the appropriate quesitons for selected language
    questionsList = [];
    getUrgentQuestions();

    // set initial due!
    await resetAmountsDue();

    // get new time studied...
    checkNewDaySequence();

    notifyListeners();
    return;
  }

  Future<void> updateSessionLangs() async {
    await getUrgentQuestions();
    updateDisplayFlags();
    notifyListeners();
    return;
  }

  // saves a string to preferences - but used here specifically for remembering previous q/a langs:
  Future<String> saveString(
    String toSetName,
    String newSetting,
    String defaultSetting,
  ) async {
    // get an up-to-date version of prefs...
    final SharedPreferences prefs = await _prefs;

    return await prefs.setString(toSetName, newSetting).then((bool success) {
      return newSetting;
    });
  }

  Future<bool> toggleBool(String toToggleName, bool defaultSetting) async {
    // get an up-to-date version of prefs...
    final SharedPreferences prefs = await _prefs;

    // get state of specific setting
    final bool tmpBool = (prefs.getBool(toToggleName) ?? defaultSetting);

    return await prefs.setBool(toToggleName, !tmpBool).then((bool success) {
      return !tmpBool;
    });
  }

  bool allowAutoRecog = true;
  void toggleallowAutoRecog() async {
    allowAutoRecog = await toggleBool('allowAutoRecog', allowAutoRecog);
    notifyListeners();
  }

  Future<Chron?> getToday() async {
    var now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    todaysDate = formatter.format(now);

    String languageCombo = getLanguageComboString(selectedLangCombo);
    Chron? todayChron = await DbChrons.getChronByDate(todaysDate, languageCombo);

    return todayChron;
  }

  List<Chron> todaysChrons = [];
  Future<List<Chron>> getTodaysChrons() async {
    var now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    todaysDate = formatter.format(now);

    List<Chron> tmpTodaysChrons = await DbChrons.getChronsByDate(todaysDate);
    todaysChrons = tmpTodaysChrons;

    // ensure that there's at least one chron for today - and if there's not, start a new day
    if (todaysChrons.isEmpty) startNewDay();

    return tmpTodaysChrons;
  }

  Future<void> startNewDay() async {
    delegationHistory.add(SessionTask(taskName: TaskName.debug, value: 'startNewDay called', language: ''));

    //don't make records of a new day unless languages are set...
    if (selectedLangCombo.raLang != '' &&
        selectedLangCombo.rqLang != '' &&
        selectedLangCombo.sqLang != '' &&
        selectedLangCombo.saLang != '') {
      String languageCombo = getLanguageComboString(selectedLangCombo);

      await DbChrons.newDay(todaysDate, languageCombo);
    }
    secondsPassed = 0;
  }

  Future<void> reduceAllLevels() async {
    List<Question> completeQsCollection = await DbQuestions.getAllQuestions();

    for (Question question in completeQsCollection) {
      if (question.level >= 1) question.level--;
      await DbQuestions.updateQuestion(question);
    }

    int qTotal = await DbQuestions.getAmountOfQuestions();

    delegationHistory.add(SessionTask(
      taskName: TaskName.debug,
      value: '‼️‼️‼️reduceAllLevels‼️‼️‼️ called',
      language: '',
    ));
    delegationHistory.add(SessionTask(
      taskName: TaskName.debug,
      value: '(${completeQsCollection.length} assessed/updated of $qTotal)...',
      language: '',
    ));

    await resetAmountsDue();

    return;
  }

  String todaysDateString() {
    var now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    todaysDate = formatter.format(now);
    return todaysDate;
  }

  Future<void> checkNewDaySequence() async {
    delegationHistory.add(SessionTask(taskName: TaskName.debug, value: 'checkNewDaySequence called', language: ''));
    Chron? todayChron = await getTodaysChron();

    String dateLastOpenedApp = '';
    dateLastOpenedApp = await _prefs.then((SharedPreferences prefs) {
      return prefs.getString('dateLastOpenedApp') ?? sqLangDefault;
    });

    String dateStringToday = todaysDateString();
    debugPrint('dateStringToday: $dateStringToday, dateLastOpenedApp: $dateLastOpenedApp');

    // if (todayChron == null) {
    if (dateLastOpenedApp != dateStringToday) {
      await saveString('dateLastOpenedApp', dateStringToday, dateLastOpenedAppDefault);
      debugPrint('IS A NEW DAY');
      debugPrint('todaysDate: $todaysDate');
      await startNewDay();
      secondsPassed = 0;
      // if there's more than one language, then levels have already been reduced for today
      await getTodaysChrons();
      // if (todaysChrons.length < 2) {
      await reduceAllLevels();
      // }

      // update levels of all questions (lvl>0) in the currently visible questionsList...
      for (var x = 0; x < questionsList.length; x++) {
        if (questionsList[x].level > 0) questionsList[x].level--;

        // putting 'notifyListeners()' inside this loop ensures that even the very last questionsList
        // changes are reflected on screen... 🤞
        notifyListeners();
      }
    } else {
      debugPrint('IS NOT A NEW DAY');
      if (todayChron != null) {
        secondsPassed = todayChron.timeStudied;
      }
    }

    // update streak from history...
    dailyStreak = await DbChrons.updateStreak();
    // update streak for today...
    if (secondsPassed > 300) dailyStreak++;

    notifyListeners();

    return;
  }

  bool isUserActive(currentTime, lastTimeUserActed, seconds) {
    return currentTime - lastTimeUserActed < seconds ? true : false;
  }

  void incrementTimer() async {
    // if the user is active, count the seconds studied
    bool tmpUserIsActive = isUserActive(
      secondsPassed,
      whenUserLastActed,
      20,
    );

    userIsActive = tmpUserIsActive;
    notifyListeners();

    if (!userIsActive) return;

    String languageCombo = getLanguageComboString(selectedLangCombo);
    if (questionsList.isNotEmpty) {
      // get secondsPassed from database (so we don't override it by making some sort of coding mistake...)
      Chron? tmpTodayChron = await DbChrons.getChronByDate(todaysDate, languageCombo);
      //tmpTodayChron
      // delegationHistory.add(SessionTask(
      //     taskName: TaskName.debug, value: 'increment timer if tmpTodayChron is not null...', language: ''));

      if (tmpTodayChron != null) {
        // delegationHistory.add(SessionTask(
        //   taskName: TaskName.debug,
        //   value: 'tmpTodayChron: ${tmpTodayChron.languageCombo}',
        //   language: '',
        // ));

        debuggingTodaySetUpdated = await DbChrons.setToday(todaysDate, tmpTodayChron.timeStudied + 1, languageCombo);
        secondsPassed = tmpTodayChron.timeStudied;
      } else {
        // (we have questions, but we don't have a chron for today...)
        // create a chron for today...
        startNewDay();
      }
    }

    // congrats:
    if (secondsPassed > 0 && secondsPassed % (60 * 5) == 0) {
      runCongratsAsap = true;
      if (questionsList.isNotEmpty) {
        dailyStreak = await DbChrons.updateStreak();
      }
      // since updateStreak only uses data from yesterday and back,
      // we should add one for today (because seconds passed > 60*5)
      dailyStreak++;
    }

    // secondsPassed++;
    notifyListeners();
  }

  getHistory() async {
    studyChronList = await DbChrons.getHistory(numOfDays);
    totalHoursStudied = await DbChrons.getHoursStudied();

    DateFormat formatter = DateFormat('yyyy-MM-dd');

    chartBars = []; //initialize in case already has data
    var pastSomeDays = [];

    var today = DateTime.now();

    // generate a list of dates stretching from now, back 30 days
    for (var x = 0; x < numOfDays; x++) {
      var newDate = DateTime(today.year, today.month, today.day - x);
      // I think this will create yyyy-MM-dd for whatever day we've got...
      pastSomeDays.add(formatter.format(newDate));
    }

    earliestDate = pastSomeDays[numOfDays - 1];
    mostRecentDate = pastSomeDays[0];

    // loop through the list
    var itterator = 0;
    for (var dayOfDays in pastSomeDays) {
      var studyChronIndex = studyChronList.indexWhere((Chron studyChron) {
        return studyChron.date == dayOfDays;
      });

      //  - if there's a record, then add the amount of time to the chartBars list
      if (studyChronIndex >= 0) {
        chartBars.add({
          'y': num.parse((studyChronList[studyChronIndex].timeStudied.toDouble() / 60).toStringAsFixed(2)),
          'x': dayOfDays,
          'i': itterator,
        });
        //  - if there's no record, then add ZERO minutes to the chartBars list
      } else {
        chartBars.add({
          'y': 0.0,
          'x': dayOfDays,
          'i': itterator,
        });
      }
      itterator++;
    }

    // make chronsAndValues into a List holding all the dates and values...
    for (var chron in studyChronList) {
      var dateOfStudy = formatter.parse(chron.date);
      chronsAndValues[dateOfStudy] = chron.timeStudied;

      int dayOfYear = int.parse(DateFormat("D").format(dateOfStudy));
      if (dayOfYear > maxDoY) maxDoY = dayOfYear.toDouble();
      if (dayOfYear < minDoY) minDoY = dayOfYear.toDouble();
      if (chron.timeStudied / 60 > maxMins) {
        maxMins = (chron.timeStudied / 60) + 10;
      }
      if (chron.timeStudied / 60 < minMins) {
        minMins = chron.timeStudied / 60;
      }
    }

    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getMultibarHistory() async {
    studyChronList = await DbChrons.getHistory(numOfDays);

    List<Map<String, dynamic>> multiChartBars = [];

    // generate a list of dates stretching from now, back 30 days
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    var pastSomeDays = [];
    var today = DateTime.now();
    for (var x = 0; x < numOfDays; x++) {
      var newDate = DateTime(today.year, today.month, today.day - x);
      // create yyyy-MM-dd for whatever day we've got...
      pastSomeDays.add(formatter.format(newDate));
    }

    int itterator = 0;
    for (var dayOfDays in pastSomeDays) {
      // find all chrons with 'dayOfDays'
      List<Chron> matchingChrons = studyChronList.where((Chron chron) => chron.date == dayOfDays).toList();

      if (matchingChrons.isEmpty) {
        multiChartBars.add({
          'y': [BarChartRodData(toY: 0.5, width: 6)],
          'x': dayOfDays,
          'i': itterator,
        });
      } else {
        List<BarChartRodData> rods = [];

        for (Chron matchingChron in matchingChrons) {
          // get all the rods...
          rods.add(
            BarChartRodData(
              toY: (matchingChron.timeStudied.toDouble() / 60).toDouble(),
              width: 6,
            ),
          );
        }

        multiChartBars.add({
          'y': rods,
          'x': dayOfDays,
          'i': itterator,
        });
      }

      itterator++;
    }

    return multiChartBars;
  }

  // TIMER:
  Future<void> initTimer() async {
    // print('initTimer');
    await checkNewDaySequence();

    if (timerIsInitialized) return;

    delegationHistory.add(SessionTask(taskName: TaskName.debug, value: 'timer initialized', language: ''));

    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      incrementTimer();
    });
    timerIsInitialized = true;

    getHistory();
  }

  // INIT:
  void init(Function? showToast) async {
    allowAutoRecog = await _prefs.then((SharedPreferences prefs) {
      return prefs.getBool('allowAutoRecog') ?? allowAutoRecog;
    });
    await initLangs();
    await getUrgentQuestions();
    await initTimer();
    if (showToast != null) _showToast = showToast;
  }

  double screenMaxWidth = 0;
  double screenMaxHeight = 0; // used for dropdowns so they don't build too tall
  void setSize(maxWidth, maxHeight) {
    screenMaxWidth = maxWidth;
    screenMaxHeight = maxHeight;
  }

  // queue

  void queueSynthQuestion() {
    if (questionsList.isEmpty || isSynthing || isRecoging) return;

    Question currentQ = getCurrentQuestion();

    sessionTaskDelegator(
      appendTask: SessionTask(taskName: TaskName.synth, value: currentQ.q, language: currentQ.sqLang),
    );
  }

  void queueSynthInputForQuestion() {
    if (questionsList.isEmpty || isSynthing || isRecoging) return;

    final userInput = questionController.text;
    if (userInput == '') return;
    Question currentQ = getCurrentQuestion();

    sessionTaskDelegator(
      appendTask: SessionTask(taskName: TaskName.synth, value: userInput, language: currentQ.sqLang),
    );
  }

  void queueSynthInput() {
    if (questionsList.isEmpty || isSynthing || isRecoging) return;

    final userInput = answerController.text;
    if (userInput == '') return;
    Question currentQ = getCurrentQuestion();

    sessionTaskDelegator(
      appendTask: SessionTask(taskName: TaskName.synth, value: userInput, language: currentQ.saLang),
    );
  }

  void queueNonSubmitRecog(String questionOrAnswer) {
    if (checkIsBusy()) return;

    sessionTaskDelegator(
      appendTask: SessionTask(
        taskName: TaskName.nonSubmitRecog,
        value: questionOrAnswer,
        language: selectedLangCombo.raLang,
      ),
    );
  }

  void queueRecog() {
    if (checkIsBusy()) return;

    Question currentQ = getCurrentQuestion();

    sessionTaskDelegator(
      appendTask: SessionTask(
        taskName: TaskName.recog,
        value: '',
        language: currentQ.raLang,
      ),
    );
  }

  void queueSubmitTyped() {
    if (checkIsBusy()) return;

    // if there's already submitByText or recog queued, then exit this method
    // (lastIndexWhere should return a -1 if the searched-for thing isn't found)
    if (delegationStack.lastIndexWhere((task) => task.taskName == TaskName.submitByText) != -1) return;
    if (delegationStack.lastIndexWhere((task) => task.taskName == TaskName.recog) != -1) return;

    final userInput = answerController.text;
    sessionTaskDelegator(
      // language is not important here because just submitting via text...
      appendTask: SessionTask(taskName: TaskName.submitByText, value: userInput, language: ''),
    );

    if (runCongratsAsap && secondsPassed ~/ 60 != 0) {
      sessionTaskDelegator(
        appendTask: SessionTask(
            taskName: TaskName.congrats,
            language: 'en-US',
            value: 'You\'ve studied ${secondsPassed ~/ 60} minutes, congrats!'),
      );
      runCongratsAsap = false;
    }

    answerController.text = '';
  }

  void queueGetHint() {
    if (checkIsBusy()) return;

    Question currentQ = getCurrentQuestion();

    sessionTaskDelegator(
      appendTask: SessionTask(
        taskName: TaskName.giveHint,
        value: currentQ.a,
        language: currentQ.saLang,
      ),
    );
  }

  Question getCurrentQuestion() {
    updateCurrentQuestionIndex();
    return questionsList[currentQuestionIndex];
  }

  addInputAsAnswer() async {
    getCurrentQuestion();
    String oldA = questionsList[currentQuestionIndex].a;
    // make necessary addition to current list...
    questionsList[currentQuestionIndex].a = '${getCurrentQuestion().a}/${answerController.text}';
    // save to database...
    int success = await DbQuestions.updateQuestion(questionsList[currentQuestionIndex]);

    notifyListeners();

    if (_showToast != null && success != 0) {
      Widget grandChild = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Question Updated:'),
          Text('Q: ${questionsList[currentQuestionIndex].q}\n'),
          Text('Old A: $oldA'),
          Text('New A: ${questionsList[currentQuestionIndex].a}'),
        ],
      );
      Widget child = Container(
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.greenAccent,
        ),
        child: grandChild,
      );
      _showToast!(child, 3);
    } else if (_showToast != null) {
      Widget grandChild = const Text('Error: No rows updated');
      Widget child = Container(
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.greenAccent,
        ),
        child: grandChild,
      );
      _showToast!(child, 3);
    }
  }

  void showPreviousGuessInfo() {
    if (_showToast != null) {
      Widget grandChild = const Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('No guesses yet'),
        ],
      );

      if (prevQuestion != null) {
        grandChild = SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Question:'),
              Text('${prevQuestion!.q}\n'),
              const Text('Guess:', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
              Text(prevGuess, style: const TextStyle(fontSize: 20)),
              const Text('Answer:', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
              Text(prevQuestion!.a, style: const TextStyle(fontSize: 20)),
            ],
          ),
        );
      }

      Widget child = Container(
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.greenAccent,
        ),
        child: grandChild,
      );

      _showToast!(child, 10);
    }

    notifyListeners();
  }

  void updateCurrentQuestionIndex() => currentQuestionIndex = questionsList.indexWhere((q) => q.order == 0);

  Future<void> getUrgentQuestions() async {
    // lowerBounds is the lowest ordered question that's allowed to be replaced by a higher-urgency question
    var lowerBounds = 10;

    ///////
    // 1. query database for 50 of the lowest ranking questions
    // 2. remove all questions that are already in the active questions list
    //      (this leaves only the lowest-ranking Q's that aren't in the active list)
    // 3. loop through active questions
    //     4. if one is above or at lvl 3
    //       5. replace it with a question from the filtered query,
    //       6. remove that question from the filtered query
    ///////

    var freshlyQueriedQuestions = await DbQuestions.getSessionQuestions(
      sqLang: selectedLangCombo.sqLang,
      rqLang: selectedLangCombo.rqLang,
      saLang: selectedLangCombo.saLang,
      raLang: selectedLangCombo.raLang,
      limit: 50,
    );

    // if questionsList is empty, then it's because we just opened the app - just assign all q's and exit the function...
    if (questionsList.isEmpty) {
      questionsList = freshlyQueriedQuestions;
      notifyListeners();
      return;
    }

    // print('maybe we should remove all sub-spiritLevel-3 questions that are in questionsList, but have an "oder"');
    // print(' value > 5 and make sure when they are added back into questionsList, ');
    // print('that they have an "order" value incrementing from > 5');

    // remove all questions from fresh that are already in questions (reduce workload)
    for (var q in questionsList) {
      freshlyQueriedQuestions.removeWhere((freshQ) => freshQ.id == q.id);
    }

    if (questionsList.length > lowerBounds) {
      // go through current questions above lowerBounds (don't swap too many visible ones - might look janky)
      for (var i = lowerBounds; i < questionsList.length; i++) {
        // if the question is lower than THRESH
        Question qAtOrder = questionsList.firstWhere((q) => q.order == i);
        //  get its index
        if (qAtOrder.level >= 3 && freshlyQueriedQuestions.isNotEmpty) {
          var indexOfQAtOrder = questionsList.indexWhere((q) => q.id == qAtOrder.id);

          // assign the fresh q to the address of the Q under thresh
          questionsList[indexOfQAtOrder] = Question(
            id: freshlyQueriedQuestions[0].id,
            q: freshlyQueriedQuestions[0].q,
            a: freshlyQueriedQuestions[0].a,
            cat: freshlyQueriedQuestions[0].cat,
            sqLang: freshlyQueriedQuestions[0].sqLang,
            rqLang: freshlyQueriedQuestions[0].rqLang,
            saLang: freshlyQueriedQuestions[0].saLang,
            raLang: freshlyQueriedQuestions[0].raLang,
            dateCreated: freshlyQueriedQuestions[0].dateCreated,
            level: freshlyQueriedQuestions[0].level,
            spiritLevel: freshlyQueriedQuestions[0].spiritLevel,
            history: freshlyQueriedQuestions[0].history,
            note: freshlyQueriedQuestions[0].note,
            order: questionsList[indexOfQAtOrder].order,
          );

          freshlyQueriedQuestions.removeAt(0);
        }
      }
    }

    updateCurrentQuestionIndex();

    notifyListeners();
  }

  Future<void> updateCorrectQuestionState() async {
    Question currentQuestion = questionsList[currentQuestionIndex];

    currentQuestion.history = 'o${currentQuestion.history}';
    if (currentQuestion.level < 3) {
      currentQuestion.spiritLevel++;
      currentQuestion.level = currentQuestion.spiritLevel;

      if (currentQuestion.spiritLevel > 3) {
        currentQuestion.level = (pow(2, (currentQuestion.spiritLevel - 4)) as int) + 4;
      }
    }

    await DbQuestions.updateQuestion(currentQuestion);
  }

  void increaseQuestionOrder() {
    int newOrderVal = 0;
    var currentQuestion = questionsList.firstWhere((q) => q.order == 0);

    if (currentQuestion.spiritLevel == 0) newOrderVal = 3;
    if (currentQuestion.spiritLevel == 1) newOrderVal = 5;
    if (currentQuestion.spiritLevel == 2) newOrderVal = 7;
    if (currentQuestion.spiritLevel == 3) newOrderVal = 50;
    if (currentQuestion.spiritLevel == 4) newOrderVal = 50;
    if (currentQuestion.spiritLevel == 5) newOrderVal = 50;

    if (currentQuestion.spiritLevel > 5) {
      newOrderVal = currentQuestion.spiritLevel * currentQuestion.spiritLevel;
    }

    // add illusion of a bit of randomness
    Random random = Random();
    int randomNumber = random.nextInt(3) - 2;

    newOrderVal += randomNumber;

    // be doubly sure that newOrderVal isn't a number that will crash the session:
    if (newOrderVal >= 50) newOrderVal = 49;

    if (newOrderVal >= questionsList.length) {
      newOrderVal = questionsList.length - 1;
    }

    for (var i = 0; i < questionsList.length; i++) {
      if (questionsList[i].order <= newOrderVal) {
        questionsList[i].order--;
      }
    }

    currentQuestion.order = newOrderVal;
    notifyListeners();
    updateTotalUnderThresh();
  }

  Future<void> updateTotalUnderThresh() async {
    // make sure to use the language combo...
    totalUnderThresh = await DbQuestions.getAmountUnderThresh(
      selectedLangCombo.sqLang,
      selectedLangCombo.rqLang,
      selectedLangCombo.saLang,
      selectedLangCombo.raLang,
    );

    return;
  }

  Future<void> userCorrect(SessionTask taskDetails) async {
    await updateCorrectQuestionState();

    sessionTaskDelegator(
      appendTask: SessionTask(taskName: TaskName.sfx, value: 'good', language: ''),
    );

    if (taskDetails.taskName == TaskName.submitByText) {
      sessionTaskDelegator(
          appendTask: SessionTask(
              taskName: TaskName.synth, value: prevQuestion!.a.split('/')[0], language: prevQuestion!.saLang));
    }

    int previouslyDue = due;

    // update questions due:
    due = await DbQuestions.getQAmntDueInLangCombo(
      selectedLangCombo.sqLang,
      selectedLangCombo.rqLang,
      selectedLangCombo.saLang,
      selectedLangCombo.raLang,
    );

    if (due == 0 && previouslyDue > 0) {
      sessionTaskDelegator(
        appendTask: SessionTask(
            taskName: TaskName.congrats,
            language: 'en-US',
            value: 'All questions are at the top level for today. Add more with the plus button on the top left!'),
      );
    }

    notifyListeners();

    increaseQuestionOrder();

    Question currentQ = getCurrentQuestion();

    // if we just gave the "all questions are at top level today" message,
    // then we don't want to say the next one or auto-record the answer
    if (due == 0 && previouslyDue > 0) {
      notifyListeners();
      return;
    }

    sessionTaskDelegator(
      appendTask: SessionTask(taskName: TaskName.synth, value: currentQ.q, language: currentQ.sqLang),
    );

    // auto-record again if used recog and got it right... (if setting is on)
    if (allowAutoRecog && taskDetails.taskName == TaskName.recog) {
      sessionTaskDelegator(
        appendTask: SessionTask(taskName: TaskName.recog, value: '', language: currentQ.raLang),
      );
    }

    notifyListeners();
    return;
  }

  bool assessAnswer(List<SpokenWord> spokenWords) {
    if (spokenWords.isEmpty) return false;

    List<String> splitAnswerTerms = getCurrentQuestion().a.toLowerCase().replaceAll('?', '').split('/');

    // remove each answer that has no content (because if there's a "" answer, it'll accept any answer at all!)
    // debugPrint('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    // debugPrint(
    //     'remove each answer that has no content (because if there\'s a "" answer, it\'ll accept any answer at all!)');
    // debugPrint('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');

    // for each of the words spoken (or inputted)
    for (SpokenWord spokenWord in spokenWords) {
      // check against each term in the answer
      for (String term in splitAnswerTerms) {
        // success if matches BEFORE the comment indicator

        String termBeforeComments = term.split('#')[0];

        // if word is 100% matched in speech string, show the first of passable answers (which is usually kanji, and not a homonym)
        if (spokenWord.words.toLowerCase().trim() == termBeforeComments.toLowerCase().trim()) {
          answerController.text = splitAnswerTerms[0];

          return true;
        }

        // check if word is contained in speech string
        if (spokenWord.words.toLowerCase().contains(termBeforeComments.toLowerCase().trim())) {
          answerController.text = spokenWord.words;

          return true;
        }

        // also success if matches AFTER the comment indicator
        String termAfterComments = term.split('#').length > 1 ? term.split('#')[1] : '';
        if (termAfterComments != '' && spokenWord.words.contains(termAfterComments.toLowerCase().trim())) {
          return true;
        }
      }
    }

    return false;
  }

  String hasAMatch(spokenWords) {
    // if spoken words aren't heard yet, just leave function
    if (spokenWords == '') return '';

    List<String> splitAnswerTerms = getCurrentQuestion().a.toLowerCase().replaceAll('?', '').split('/');
    for (String answerTerm in splitAnswerTerms) {
      // if spoken words exactly match any answer term, return the first answer term
      // (which is typically the nicest looking writing of the answer)
      if (spokenWords == answerTerm) {
        return splitAnswerTerms[0];
      }
    }

    // if no exact matches were found, return an empty string
    return '';
  }

  Future<Chron?> getTodaysChron() async {
    var now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    todaysDate = formatter.format(now);

    String languageCombo = getLanguageComboString(selectedLangCombo);
    Chron? todayChron = await DbChrons.getChronByDate(todaysDate, languageCombo);

    return todayChron;
  }

  // BATCH HISTORY:
  void addBatchToHistory(String category, String name) async {
    // add "Batch" to _db_history
    await getTodaysChron();
    DBHistory.addBatch(
      todaysDate,
      '$category-$name',
      category,
    );

    batchHistoryList.insert(
      0,
      AddedBatch(
        id: 0,
        date: todaysDate,
        name: '$category-$name',
        category: category,
      ),
    );

    notifyListeners();
  }

  void getBatchHistory() async {
    // fetch "Batchs" from the _db_history
    List<AddedBatch> tmpHistory = await DBHistory.getHistory();
    for (var datum in tmpHistory) {
      batchHistoryList.add(datum);
    }
    notifyListeners();
  }

  String addQErrorMsg = '';
  // check that there is content in the question/answer fields, and add it to the questions list
  Future<bool> addQuestion(String q, String a) async {
    if (q == '') {
      addQErrorMsg = 'Please fill the Question field before submitting';
      notifyListeners();
      return false;
    }
    if (a == '') {
      addQErrorMsg = 'Please fill the Answer field before submitting';
      notifyListeners();
      return false;
    }
    addQErrorMsg = '';

    Question newQuestion = Question(
      id: 0,
      q: q,
      a: a,
      cat: '',
      sqLang: selectedLangCombo.sqLang,
      rqLang: selectedLangCombo.rqLang,
      saLang: selectedLangCombo.saLang,
      raLang: selectedLangCombo.raLang,
      dateCreated: getTodaysDate(),
      level: 0,
      spiritLevel: 0,
      history: '',
      note: '',
      order: 0,
    );

    // increase the order of all questions before adding this question to the questions list
    for (var q in questionsList) {
      q.order++;
    }

    int idOfAdded = await DbQuestions.addQuestion(newQuestion);

    Question newQuestionWithId = Question(
      id: idOfAdded,
      q: q,
      a: a,
      cat: '',
      sqLang: selectedLangCombo.sqLang,
      rqLang: selectedLangCombo.rqLang,
      saLang: selectedLangCombo.saLang,
      raLang: selectedLangCombo.raLang,
      dateCreated: getTodaysDate(),
      level: 0,
      spiritLevel: 0,
      history: '',
      note: '',
      order: 0,
    );

    questionsList.add(newQuestionWithId);
    due++;
    dueInitially++;

    notifyListeners();
    return true;
  }

  // EDIT SCREEN STUFF:
  void updateEditedQuestion(Question question) async {
    await DbQuestions.updateQuestion(question);
    notifyListeners();
  }

  Future<void> delete(id) async {
    int deletingIndex = questionsList.indexWhere((q) => q.id == id);
    var orderNo = questionsList[deletingIndex].order;

    await DbQuestions.deleteQuestion(id);
    questionsList.removeAt(deletingIndex);

    // reduce order of all questions above order of deleted note:
    for (var i = 0; i < questionsList.length; i++) {
      if (questionsList[i].order > orderNo) {
        questionsList[i].order--;
      }
    }

    List<Question> questionsForReplenishment = await DbQuestions.getSessionQuestions(
      sqLang: selectedLangCombo.sqLang,
      rqLang: selectedLangCombo.rqLang,
      saLang: selectedLangCombo.saLang,
      raLang: selectedLangCombo.raLang,
      limit: 50,
    );

    for (var i = 0; i < questionsForReplenishment.length; i++) {
      var inQuestionsList = false;
      for (var j = 0; j < questionsList.length; j++) {
        if (questionsList[j].id == questionsForReplenishment[i].id) {
          inQuestionsList = true;
        }
      }
      if (!inQuestionsList) {
        questionsList.add(questionsForReplenishment[i]);
        questionsList[questionsList.length - 1].order = questionsList.length - 1;
      }
    }
    resetAmountsDue();
    notifyListeners();
  }

  // store isBusy value for the edit screen...
  bool isBusy = false;
  bool checkIsBusy() {
    if (isSynthing || isRecoging || sfxPlaying) {
      isBusy = true;
      notifyListeners();
      return isBusy;
    }
    isBusy = false;
    notifyListeners();
    return isBusy;
  }

  void runRecogNonSubmit(SessionTask taskDetails) async {
    delegationStack.removeAt(0);

    // keep track of what's recording (to show little spinner)
    isRecoging = true; // make sure logic is maintained
    isBusy = true;
    // keep track for individual spinners:
    if (taskDetails.value == 'question') {
      isRecogingQuestion = true;
    } else if (taskDetails.value == 'answer') {
      isRecogingAnswer = true;
      isBusy = true;
    }
    notifyListeners();

    recog.startListening(
      recogDuration: recogDuration,
      localeId: taskDetails.language,
      finalResCallback: (List<SpokenWord> res) async {
        for (var spokenWord in res) {
          if (spokenWord.words != '') collectedRes.add(spokenWord);
        }

        if (collectedRes.isEmpty) {
          collectedRes = [SpokenWord('No speech heard...', 1)];
        }

        recogRes = collectedRes; // keep record of recog for displaying all possible interpretations of input

        // get whichever answer is the longest, and put that into the answerController.text
        SpokenWord longestResult = collectedRes.reduce((a, b) => a.words.length > b.words.length ? a : b);

        if (taskDetails.value == 'question') {
          questionController.text = longestResult.words;
        } else if (taskDetails.value == 'answer') {
          answerController.text = longestResult.words;
        }

        // keep track of what's recording (to show little spinner)
        isRecoging = false; // make sure logic is maintained
        isBusy = false;
        // keep track for individual spinners:
        if (taskDetails.value == 'question') {
          isRecogingQuestion = false;
        } else if (taskDetails.value == 'answer') {
          isRecogingAnswer = false;
        }

        if (runCongratsAsap) {
          sessionTaskDelegator(
            appendTask: SessionTask(
                taskName: TaskName.congrats,
                language: 'en-US',
                value: 'You\'ve studied ${secondsPassed ~/ 60} minutes, congrats!'),
          );
          runCongratsAsap = false;
        }

        // isRecoging = false;
        notifyListeners();
      },
      intermittentResCallback: (List<SpokenWord> res) {
        if (res.isEmpty) return;

        for (var resThing in res) {
          collectedRes.add(resThing);
        }

        recogRes = res; // keep record of recog for displaying all possible interpretations of input
        if (res[0].words != '') {
          if (taskDetails.value == 'question') {
            questionController.text = res[0].words; // put a result into the QUESTION text field
          } else if (taskDetails.value == 'answer') {
            answerController.text = res[0].words; // put a result into the ANSWER text field
          }
        }

        notifyListeners();
      },
    );
  }

  List<SpokenWord> collectedRes = [];

  void runRecogSubmitAnswer(SessionTask taskDetails) async {
    delegationStack.removeAt(0);

    isRecoging = true;
    isBusy = true;
    notifyListeners();
    collectedRes = [];

    recog.startListening(
      recogDuration: recogDuration,
      localeId: taskDetails.language,
      finalResCallback: (List<SpokenWord> res) async {
        // checking for finalResCallback response having a non-empty string (just for debugging logging)
        delegationHistory.add(SessionTask(
            taskName: TaskName.debug, value: 'finalResCallback results length: ${res.length}', language: ''));
        if (res.isNotEmpty) {
          delegationHistory.add(
              SessionTask(taskName: TaskName.debug, value: 'finalResCallback[0].words: ${res[0].words}', language: ''));
        }

        // for debugging finalResCallback stuff:
        // print('finalResCallback:');
        // for (SpokenWord spokenWord in res) {
        //   print('${(spokenWord.confidence * 100)} ${spokenWord.words} ');
        // }

        // print('collectedRes:');
        // for (SpokenWord spokenWord in collectedRes) {
        //   print('${(spokenWord.confidence * 100)} ${spokenWord.words} ');
        // }

        // add any non-blank responses to the collected responses
        for (var spokenWord in res) {
          if (spokenWord.words != '') collectedRes.add(spokenWord);
        }

        if (collectedRes.isEmpty) {
          collectedRes = [SpokenWord('No speech heard...', 1)];
        }

        recogRes = collectedRes; // keep record of recog for displaying all possible interpretations of input

        // get whichever answer is the longest, and put that into the answerController.text
        SpokenWord longestResult = collectedRes.reduce((a, b) => a.words.length > b.words.length ? a : b);

        answerController.text = longestResult.words; // put a result into the ansewr text field

        prevQuestion = getCurrentQuestion();
        prevGuess = answerController.text;

        // IF VOICE SUBMISSION IS CORRECT:
        if (assessAnswer(collectedRes)) {
          if (_showToast != null && prevQuestion != null) {
            Widget child = Container(
              constraints: const BoxConstraints(minHeight: 150),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: Colors.greenAccent.withValues(alpha: 0.9),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✔️'),
                  Text(prevQuestion!.a),
                ],
              ),
            );

            _showToast!(child, 3);
          }

          firstRecogGuessHintPlayed = false;

          await userCorrect(taskDetails);
          answerController.text = '';
        } else {
          // IF VOICE SUBMISSION IS WRONG:
          // print('user was wrong, sending sfx task...');
          sessionTaskDelegator(
            appendTask: SessionTask(taskName: TaskName.sfx, value: 'bad', language: ''),
          );

          if (!firstRecogGuessHintPlayed) {
            Question currentQ = getCurrentQuestion();
            if (currentQ.spiritLevel == 0) {
              questionForHint = currentQ; // hint also needs spiritLevel info to know if should resist giving hint
              sessionTaskDelegator(
                appendTask: SessionTask(taskName: TaskName.giveHint, value: currentQ.a, language: currentQ.saLang),
              );

              firstRecogGuessHintPlayed = true;
              if (allowAutoRecog) {
                sessionTaskDelegator(
                  appendTask: SessionTask(taskName: TaskName.recog, value: '', language: currentQ.saLang),
                );
                // showUserRecordIsQueuedUp = true;
              }
              notifyListeners();
            }
          }
        }

        isRecoging = false;
        isBusy = false;

        if (runCongratsAsap) {
          sessionTaskDelegator(
            appendTask: SessionTask(
                taskName: TaskName.congrats,
                language: 'en-US',
                value: 'You\'ve studied ${secondsPassed ~/ 60} minutes, congrats!'),
          );
          runCongratsAsap = false;
        }

        notifyListeners();
        sessionTaskDelegator(appendTask: null);
      },
      intermittentResCallback: (List<SpokenWord> res) {
        if (res.isEmpty) return;

        for (var resThing in res) {
          collectedRes.add(resThing);
        }

        recogRes = res; // keep record for display if requested...

        if (res[0].words != '') {
          answerController.text = res[0].words;
        }
        String intermittentMatch = hasAMatch(answerController.text);
        if (intermittentMatch != '') answerController.text = intermittentMatch;
        notifyListeners();
      },
    );
  }

  Future<void> updateWrongQuestionState() async {
    Question currentQuestion = questionsList[currentQuestionIndex];

    currentQuestion.history = 'x${currentQuestion.history}';

    currentQuestion.spiritLevel = 0;
    currentQuestion.level = 0;

    await DbQuestions.updateQuestion(currentQuestion);
  }

  void runSubmitByText(SessionTask taskDetails) async {
    delegationStack.removeAt(0);

    List<SpokenWord> userInput = [SpokenWord(answerController.text, 1)];

    prevQuestion = getCurrentQuestion();
    prevGuess = answerController.text;

    if (assessAnswer(userInput)) {
      await userCorrect(taskDetails);
      if (_showToast != null && prevQuestion != null) {
        Widget child = Container(
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            color: Colors.greenAccent.withValues(alpha: 0.9),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✔️', style: TextStyle(fontSize: 42)),
              Text(prevQuestion!.a.split('/')[0]),
            ],
          ),
        );

        _showToast!(child, 3);
      }
    } else {
      sessionTaskDelegator(
        appendTask: SessionTask(taskName: TaskName.sfx, value: 'bad', language: ''),
      );

      // assign the level of current question to 0
      updateWrongQuestionState();

      // tell the user the answer
      Question currentQ = getCurrentQuestion();
      showHintInfo();
      sessionTaskDelegator(
          appendTask: SessionTask(taskName: TaskName.synth, value: currentQ.a, language: currentQ.saLang));

      due = await DbQuestions.getQAmntDueInLangCombo(
        selectedLangCombo.sqLang,
        selectedLangCombo.rqLang,
        selectedLangCombo.saLang,
        selectedLangCombo.raLang,
      );

      notifyListeners();
      increaseQuestionOrder();

      Question newQ = getCurrentQuestion();
      sessionTaskDelegator(
          appendTask: SessionTask(
        taskName: TaskName.synth,
        value: newQ.q,
        language: newQ.sqLang,
      ));

      if (skipped && allowAutoRecog) {
        Question currentQ = getCurrentQuestion();
        sessionTaskDelegator(
            appendTask: SessionTask(
          taskName: TaskName.recog,
          value: '',
          language: currentQ.raLang,
        ));
        skipped = false;
      }
    }
  }

  void runSfx(currentTask) async {
    delegationStack.removeAt(0);

    sfxPlaying = true;
    isBusy = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300), () {});
    final player = AudioPlayer();

    if (currentTask.value == 'bad') {
      player.play(AssetSource(sfxFeedbackBad));
    }

    try {
      if (currentTask.value == 'good') {
        if (due != 0) {
          player.play(AssetSource(sfxFeedbackGood));
        } else {
          player.play(AssetSource(sfxFeedbackGreat));
        }
      }
    } catch (e) {
      sfxStatus = 'Error playing sfx: $e';
      throw 'Error playing sfx: $e';
    }

    await Future.delayed(const Duration(milliseconds: 800), () {});
    sfxPlaying = false;
    isBusy = false;
    player.dispose();
    // print('finished sfxing...');
    notifyListeners();

    sessionTaskDelegator(appendTask: null);
  }

  void runSynth(SessionTask taskDetails) {
    synthStatus = synth.status;
    // synth.isSpeaking SHOULD be handled by the flutterTts library... we'll see...
    // synth doesn't start up quickly enough to halt the next task, so we need to set 'isSpeaking' to true
    // ASAP:
    isSynthing = true;
    isBusy = true;

    delegationStack.removeAt(0);

    //alter the answer so that everything after the '#' isn't played...
    List<String> answers = taskDetails.value.split('/');
    taskDetails.value = answers.map((answer) => answer.split('#')[0]).join('/');

    synth.synth(
      msg: taskDetails.value,
      language: taskDetails.language,
      callback: () {
        isSynthing = false;
        checkIsBusy();
        sessionTaskDelegator(appendTask: null);
      },
    ); // play question/answer/hint/congrats
  }

  void showHintInfo() async {
    // get the current question
    hintInfo = getCurrentQuestion();
    if (_showToast != null) {
      Widget child = Container(
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.greenAccent.withValues(alpha: 0.9),
        ),
        // alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const Text('✔️'),
            Text('Question:\n${hintInfo.q}\n\nAnswer:\n${hintInfo.a}\n\nHistory: ${hintInfo.history}'),
          ],
        ),
      );

      _showToast!(child, 3);
    }
    notifyListeners();
  }

  // TASK DELEGATOR:
  void sessionTaskDelegator({SessionTask? appendTask}) async {
    recogStatus = recog.status; // always update the recogStatus, bc it often has errors...
    notifyListeners();

    if (appendTask != null) {
      // print('attempting to run task: ${appendTask.taskName}');
    }
    whenUserLastActed = secondsPassed;

    if (appendTask != null) {
      delegationStack.add(appendTask);
      delegationHistory.add(appendTask);
      notifyListeners();
    }

    if (delegationStack.isEmpty || checkIsBusy()) return;

    SessionTask currentTask = delegationStack[0];

    if (currentTask.taskName == TaskName.nonSubmitRecog) {
      runRecogNonSubmit(currentTask);
    }

    if (currentTask.taskName == TaskName.recog) {
      //   // print('runRecord bieng run...');
      runRecogSubmitAnswer(currentTask);
    }

    if (currentTask.taskName == TaskName.sfx) {
      runSfx(currentTask);
    }

    // congrats needs its own conditional because it uses both synth AND an SQL query
    if (currentTask.taskName == TaskName.congrats && !checkIsBusy()) {
      throwConfetti();
      runSynth(currentTask);

      getUrgentQuestions();
    }

    if (currentTask.taskName == TaskName.synth && !checkIsBusy()) {
      runSynth(currentTask);
    }

    if (currentTask.taskName == TaskName.submitByText && !checkIsBusy()) {
      runSubmitByText(currentTask);
    }

    if (currentTask.taskName == TaskName.giveHint && !checkIsBusy()) {
      if (questionForHint.spiritLevel > 0) {
        runSynth(
          SessionTask(taskName: TaskName.giveHint, language: 'en-US', value: 'You were right last time. No hint.'),
        );
      } else {
        showHintInfo();
        runSynth(currentTask);
      }
    }

    // .synth,          ✔️
    // .recog,          ✔️
    // .nonSubmitRecog, ✔️
    // .submitByText,
    // .sfx,            ✔️
    // .congrats,       ✔️
    // .giveHint,
    // .sayAnswer,
  }
}
