import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/providers/settings.dart';

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

    Color bgColor = Colors.white;
    // Color containerColor = Colors.grey.shade200;
    Color fgColor = Colors.black;

    if ((!providerSettings.darknessMatchesOS && providerSettings.darkMode) ||
        (providerSettings.darknessMatchesOS && providerSettings.systemIsInDarkMode)) {
      bgColor = Colors.black;
      // containerColor = Colors.grey.shade600;
      fgColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          'Settings',
          style: TextStyle(color: fgColor),
        ),
        iconTheme: IconThemeData(color: fgColor),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // final maxWidth = constraints.maxWidth;
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
                        title: Text(
                          'Show Queue',
                          style: TextStyle(color: fgColor),
                        ),
                        subtitle: Text(
                          'Shows all questions in the order they will be asked on the main screen.',
                          style: TextStyle(color: fgColor),
                        ),
                        value: providerSettings.showQueue,
                        onChanged: (val) {
                          providerSettings.toggleShowQueue();
                        },
                      ),
                      SwitchListTile(
                        activeColor: Colors.blue,
                        title: Text(
                          'Allow Auto Recog',
                          style: TextStyle(color: fgColor),
                        ),
                        subtitle: Text(
                          'When you are correct - after the next question is read, the microphone will start recording the answer immediately.',
                          style: TextStyle(color: fgColor),
                        ),
                        value: providerSessionLogic.allowAutoRecog,
                        onChanged: (val) {
                          providerSessionLogic.toggleallowAutoRecog();
                        },
                      ),

                      SwitchListTile(
                        activeColor: Colors.blue,
                        title: Text(
                          'Darkness Matches OS',
                          style: TextStyle(color: fgColor),
                        ),
                        subtitle: Text(
                          'Let display match OS lightness/darkness (overrides Dark Mode option)',
                          style: TextStyle(color: fgColor),
                        ),
                        value: providerSettings.darknessMatchesOS,
                        onChanged: (val) {
                          providerSettings.toggleDarknessMatchesOS();
                        },
                      ),
                      if (providerSettings.darknessMatchesOS == false)
                        SwitchListTile(
                          activeColor: Colors.blue,
                          title: Text(
                            'Dark Mode',
                            style: TextStyle(color: fgColor),
                          ),
                          subtitle: Text(
                            'A display mode better suited for studying in dark environments.',
                            style: TextStyle(color: fgColor),
                          ),
                          value: providerSettings.darkMode,
                          onChanged: (val) {
                            providerSettings.toggledarkMode();
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
