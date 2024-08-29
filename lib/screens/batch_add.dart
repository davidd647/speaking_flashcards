import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speaking_flashcards/providers/session_logic.dart';
import 'package:speaking_flashcards/widgets/wide_button.dart';

class BatchAdd extends StatefulWidget {
  const BatchAdd({super.key});
  static const routeName = '/batchadd';

  @override
  State<BatchAdd> createState() => _BatchAddState();
}

class _BatchAddState extends State<BatchAdd> {
  TextEditingController batchAddController = TextEditingController(); // for adding Q's by the batch!
  String invalidRow = '';

  void validateCSV() {
    invalidRow = '';

    List<String> lines = batchAddController.text.split('\n');
    for (int x = 0; x < lines.length; x++) {
      List<String> fields = lines[x].split(',');
      if (lines[x] != '' && fields.length != 2) {
        invalidRow = "Line $x invalid: ${lines[x]}";
      }
    }

    setState(() {});
  }

  void addFromCSV() async {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context, listen: false);
    List<String> lines = batchAddController.text.split('\n');
    for (int x = 0; x < lines.length; x++) {
      List<String> fields = lines[x].split(',');
      await providerSessionLogic.addQuestion(fields[0], fields[1]);
    }
    batchAddController.text = '';
    invalidRow = '${lines.length} flashcards added! :)';
  }

  @override
  void initState() {
    super.initState();
    batchAddController.addListener(() {
      print('checking...');
      validateCSV();
    });
  }

  @override
  Widget build(BuildContext context) {
    final providerSessionLogic = Provider.of<ProviderSessionLogic>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Add'),
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
                      const SizedBox(height: 24),
                      TextField(
                        controller: batchAddController,
                        keyboardType: TextInputType.multiline,
                        // maxLines: null, // This makes it expandable to any number of lines
                        maxLines: 5,
                        minLines: 5, // Optional, but good to set a starting point
                        decoration: const InputDecoration(
                          hintText: "Enter your batch here (in CSV format)",
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.newline, // For iOS to show a return key that makes a new line
                      ),
                      const SizedBox(height: 10),
                      WideButton(
                          disabled: invalidRow != '' ? true : false,
                          onTap: () {
                            if (invalidRow != '') return;

                            addFromCSV();
                          },
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              Icon(Icons.add, color: (invalidRow != '') ? Colors.grey[300] : null),
                              const SizedBox(width: 10),
                              Text(
                                'Add Batch',
                                style: TextStyle(color: invalidRow != '' ? Colors.grey[400] : null),
                              ),
                            ],
                          )),
                      if (invalidRow != '') const SizedBox(height: 10),
                      if (invalidRow != '') Text(invalidRow, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      WideButton(
                        disabled: true,
                        onTap: () {},
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            Icon(Icons.exit_to_app_sharp, color: Colors.grey[300]),
                            const SizedBox(width: 10),
                            Text(
                              'Open website to copy batch from',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }
}
