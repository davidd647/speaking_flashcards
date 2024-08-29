import 'package:speaking_flashcards/models/flag.dart';
import 'package:speaking_flashcards/helpers/list_of_flags.dart';

String codeToFlag(String code) {
  List<Flag> flags = listOfFlags();
  var selectedFlag = '❓';

  for (var flag in flags) {
    if (flag.code == code.replaceAll('_', '-').toLowerCase()) {
      selectedFlag = flag.flag;
    }
  }

  return selectedFlag;
}
