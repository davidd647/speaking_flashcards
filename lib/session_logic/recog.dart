import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:speaking_flashcards/models/lang.dart';
import 'package:speaking_flashcards/models/spoken_word.dart';

class Recog {
  SpeechToText stt = SpeechToText();
  bool recogEnabled = false;

  List<dynamic> locales = [];
  Function? _finalResCallback;
  Function? _intermittentResCallback;

  String status = '👍';

  Future<void> init(setIsRecoging) async {
    if (recogEnabled) return;
    recogEnabled = await stt.initialize(
      onStatus: (res) {
        if (res == 'listening') {
          setIsRecoging(true);
        } else if (res == 'done') {
          setIsRecoging(false);
        }
      },
      onError: (SpeechRecognitionError err) {
        status = 'Error: $err';
        if (err.errorMsg == 'error_no_match' && _finalResCallback != null) {
          List<SpokenWord> res = [];
          _finalResCallback!(res);
        }
      },
      debugLogging: true,
    );

    locales = await stt.locales();
  }

  void startListening({recogDuration, localeId, finalResCallback, intermittentResCallback}) async {
    _finalResCallback = finalResCallback;
    _intermittentResCallback = intermittentResCallback;

    if (!recogEnabled) {
      finalResCallback(
        [SpokenWord('Recog error: not enabled', 0.0)],
      );
      return; //catherine
    }

    try {
      await stt.listen(
        onResult: _onRecogResult,
        listenFor: Duration(milliseconds: recogDuration),
        localeId: localeId,
      );
    } catch (e) {
      status = 'Error with stt.listen: $e';
      throw 'Error with stt.listen: $e';
    }
  }

  void _onRecogResult(result) {
    List<SpokenWord> inputList = [];

    for (var alternate in result.alternates) {
      inputList.add(SpokenWord(
        alternate.recognizedWords,
        alternate.confidence,
      ));
    }

    if (result.finalResult == true) {
      _finalResCallback!(inputList);
    } else {
      if (_intermittentResCallback == null) return;
      _intermittentResCallback!(inputList);
    }
  }

  List<Lang> getLangs() {
    List<Lang> langs = [];
    for (var locale in locales) {
      langs.add(
        Lang(
          name: locale.name,
          code: locale.localeId,
          origin: [CodeOrigin.recog],
          flag: '',
        ),
      );
    }
    return langs;
  }
}
