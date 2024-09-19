import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;

import 'package:speaking_flashcards/models/lang.dart';

class Synth {
  FlutterTts flutterTts = FlutterTts();
  List<dynamic> languagesTtsFormat = [];
  Function? _setIsSynthing;
  Function? _callback;

  String status = '👍';

  Future<void> init(setIsSynthing) async {
    _setIsSynthing = setIsSynthing;
    languagesTtsFormat = await flutterTts.getLanguages;

    flutterTts.setStartHandler(() {
      if (_setIsSynthing != null) {
        _setIsSynthing!(true);
      }
    });

    flutterTts.setCompletionHandler(() {
      if (_setIsSynthing != null) {
        _setIsSynthing!(false);
      }

      if (_callback != null) {
        _callback!();
      }
    });

    if (Platform.isIOS) {
      flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        // this should play through phone speaker instead of bluetooth, but doesn't seem to work...
        // anyways, it doesn't seem to impact anything? "If it ain't broke don't fix it"?
        [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
      );
    }
  }

  List<Lang> getLangs() {
    // transpile to Lang objects:
    List<Lang> langs = [];
    for (var language in languagesTtsFormat) {
      langs.add(
        Lang(
          name: '',
          code: language,
          flag: '',
          origin: [CodeOrigin.synth],
        ),
      );
    }

    return langs;
  }

  Future<void> synth({msg, language, callback}) async {
    _callback = callback;

    try {
      await flutterTts.setLanguage(language);
    } catch (e) {
      status = 'Error setting language: $e';
      throw 'Error setting language: $e';
    }

    try {
      await flutterTts.speak(msg);
    } catch (e) {
      status = 'Error during speech synthesis: $e';
      throw 'Error during speech synthesis: $e';
    }
  }
}
