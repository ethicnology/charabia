import 'dart:convert';

import 'package:http/http.dart' as http;

Future<String> gptTurbo(
  String apiKey,
  String system,
  String user,
) async {
  int statusCode = 429;
  while (statusCode == 429) {
    var url = Uri.parse('https://api.openai.com/v1/chat/completions');
    var response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
          ]
        }));

    statusCode = response.statusCode;
    // print(statusCode);
    if (statusCode == 429) {
      await Future.delayed(const Duration(seconds: 1));
      continue;
    }
    if (statusCode == 200) {
      final data = jsonDecode(response.body);
      print(
        'gptTurbo process… system: ${system.length} user: ${user.length} total_tokens: ${data['usage']['total_tokens']} finish_reason: ${data["finish_reason"]}',
      );
      String value = data['choices'][0]['message']['content'];
      final bytes = value.codeUnits;
      final encodedString = utf8.decode(bytes);
      return encodedString;
    }
  }

  throw Exception('Failed to get completions');
}

Future<String> srtProcessing(
  String apiKey,
  String system,
  String user,
) async {
  var subtitles = srtToStructure(user);
  for (var sub in subtitles) {
    String translation = await gptTurbo(apiKey, system, sub["text"]);
    sub["text"] = formatSubText(translation);
  }
  return structToSrt(subtitles);
}

List<Map<String, dynamic>> srtToStructure(String srtString) {
  final List<Map<String, dynamic>> subtitles = [];
  final List<String> lines = srtString.split('\n');
  int i = 0;

  final RegExp idRegExp = RegExp(r'^\d+$');
  final RegExp timeRegExp =
      RegExp(r'^\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}$');

  while (i < lines.length) {
    final Map<String, dynamic> subtitle = {};
    assert(idRegExp.hasMatch(lines[i].trim()));
    subtitle['id'] = int.parse(lines[i].trim());
    assert(subtitle['id'] == subtitles.length + 1);
    i++;

    assert(timeRegExp.hasMatch(lines[i].trim()));
    final List<String> timeStrings = lines[i].trim().split(' --> ');
    subtitle['start_time'] = timeStrings[0];
    subtitle['end_time'] = timeStrings[1];
    i++;

    subtitle['text'] = lines[i].trim();
    i++;

    while (i < lines.length && lines[i].trim().isNotEmpty) {
      subtitle['text'] += '\n${lines[i].trim()}';
      i++;
    }

    subtitles.add(subtitle);
    i++;
  }

  return subtitles;
}

// Ensures that text does not contain a string more than 47 chars without line break, if so, breaks it.
String formatSubText(String text) {
  var maxSrtLength = 47;
  var lines = text.split("\n");
  for (int i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (line.length > maxSrtLength) {
      var splitted = line.split(" ");
      var midIndex = splitted.length ~/ 2;
      var truncated =
          "${splitted.getRange(0, midIndex).join(" ")}\n${splitted.getRange(midIndex, splitted.length).join(" ")}";
      lines[i] = truncated;
    }
  }
  return lines.join("\n");
}

String structToSrt(List<Map<String, dynamic>> subtitles) {
  final StringBuffer buffer = StringBuffer();
  for (final Map<String, dynamic> subtitle in subtitles) {
    buffer.writeln('${subtitle['id']}');
    buffer.writeln('${subtitle['start_time']} --> ${subtitle['end_time']}');
    buffer.writeln('${subtitle['text']}');
    buffer.writeln();
  }
  return buffer.toString();
}
