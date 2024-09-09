import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';
import 'package:speaking_flashcards/widgets/wide_button.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});
  static const routeName = '/settings';

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final answerInput = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);
    final providerSettings = Provider.of<ProviderSettings>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          // final maxHeight = constraints.maxHeight;

          return (providerSessionLogic.commonLangs.isEmpty)
              ? const Center(
                  child: Text(
                    'Err: providerSessionLogic.commonLangs is empty',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeColor: Colors.blue,
                        title: const Text('Show Queue'),
                        subtitle: const Text('Shows all questions in the order they will be asked on the main screen.'),
                        value: providerSettings.showQueue,
                        onChanged: (val) {
                          providerSettings.toggleShowQueue();
                        },
                      ),
                      SwitchListTile(
                        activeColor: Colors.blue,
                        title: const Text('Allow Auto Recog'),
                        subtitle: const Text(
                            'When you are correct - after the next question is read, the microphone will start recording the answer immediately.'),
                        value: providerSessionLogic.allowAutoRecog,
                        onChanged: (val) {
                          providerSessionLogic.toggleallowAutoRecog();
                        },
                      ),
                      // const SizedBox(height: 24),
                      // WideButton(
                      //   onTap: () {},
                      //   child: const Row(
                      //     // mainAxisAlignment: MainAxisAlignment.end,
                      //     children: [
                      //       SizedBox(width: 10),
                      //       Icon(Icons.arrow_forward_ios_sharp),
                      //       SizedBox(width: 10),
                      //       Text('About'),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                );
        },
      ),
    );
  }
}
