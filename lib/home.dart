import 'package:charabia/process.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final apiKey = TextEditingController();
  final user = TextEditingController();
  final system = TextEditingController();
  final output = TextEditingController();
  bool isSrtSubtitles = false;
  int processedSubs = 0;
  int totalSubs = 0;
  bool isProcessing = false;

  void processing() async {
    if (isSrtSubtitles) {
      var subtitles = srtToStructure(user.text);
      setState(() {
        processedSubs = 1;
        totalSubs = subtitles.length;
        isProcessing = true;
      });
      for (var sub in subtitles) {
        String translation =
            await gptTurbo(apiKey.text, system.text, sub["text"]);
        setState(() {
          processedSubs += 1;
        });
        sub["text"] = formatSubText(translation);
      }
      output.text = structToSrt(subtitles);
      setState(() {
        isProcessing = false;
      });
    } else {
      output.text = await gptTurbo(apiKey.text, system.text, user.text);
    }
  }

  void copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
      ),
    );
  }

  @override
  void dispose() {
    apiKey.dispose();
    system.dispose();
    user.dispose();
    output.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return Center(
          child: LinearProgressIndicator(value: processedSubs / totalSubs));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charabia'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: apiKey,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'openAI API Key',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Empty value';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          controller: system,
                          decoration: const InputDecoration(
                            hintText: "Only translate to French",
                            labelText: 'System',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Empty value';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          child: CheckboxListTile(
                        title: const Text("SRT subtitles"),
                        value: isSrtSubtitles,
                        onChanged: (newValue) {
                          setState(() {
                            isSrtSubtitles = newValue!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      )),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              processing();
                            }
                          },
                          child: const Text('Process'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            copy(user.text);
                          },
                          icon: const Icon(Icons.content_copy),
                          label: const Text('Copy Input'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            copy(output.text);
                          },
                          icon: const Icon(Icons.content_copy),
                          label: const Text('Copy Output'),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: user,
                          maxLines: null,
                          decoration: const InputDecoration(
                            labelText: 'Input',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Empty value';
                            }
                            if (user.text.length > 4000 && !isSrtSubtitles) {
                              return 'Input too long (>4000)';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          controller: output,
                          maxLines: null,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Output',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
