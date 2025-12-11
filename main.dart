import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class ChatMessage {
  final String text;
  final bool fromUser;
  ChatMessage(this.text, {this.fromUser = false});
}

class ChatModel extends ChangeNotifier {
  List<ChatMessage> messages = [];
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool listening = false;

  ChatModel() {
    _tts.setSpeechRate(0.5);
  }

  void addUser(String text) {
    messages.insert(0, ChatMessage(text, fromUser: true));
    notifyListeners();
    _callOpenAI(text);
  }

  Future<void> _callOpenAI(String prompt) async {
    messages.insert(0, ChatMessage('...', fromUser: false));
    notifyListeners();
    try {
      // IMPORTANT: Provide your OPENAI_API_KEY via environment variable in Codemagic or other secure storage.
      const apiUrl = 'https://api.openai.com/v1/chat/completions';
      final apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
      if (apiKey.isEmpty) {
        // Replace with runtime retrieval if needed.
        _replaceLast('OpenAI API key not set. Add OPENAI_API_KEY environment variable.');
        return;
      }

      final body = {
        "model": "gpt-4o-mini", // change to available model
        "messages": [
          {"role": "system", "content": "You are Jarvis, a respectful sarcastic assistant who replies in Hinglish."},
          {"role": "user", "content": prompt}
        ],
        "max_tokens": 400,
        "temperature": 0.7
      };

      final res = await http.post(Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey'
          },
          body: jsonEncode(body));

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final text = (j['choices']?[0]?['message']?['content']) ?? 'No response';
        _replaceLast(text);
        await _tts.speak(text);
      } else {
        _replaceLast('OpenAI error: \${res.statusCode}');
      }
    } catch (e) {
      _replaceLast('Error: \$e');
    }
  }

  void _replaceLast(String text) {
    if (messages.isNotEmpty) {
      messages[0] = ChatMessage(text, fromUser: false);
    } else {
      messages.insert(0, ChatMessage(text, fromUser: false));
    }
    notifyListeners();
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!listening) {
      final available = await _speech.initialize();
      if (available) {
        listening = true;
        notifyListeners();
        _speech.listen(onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            stopListening();
          }
        });
      }
    }
  }

  void stopListening() {
    if (listening) {
      _speech.stop();
      listening = false;
      notifyListeners();
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatModel(),
      child: MaterialApp(
        title: 'Jarvis',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.cyanAccent,
        ),
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ChatModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Jarvis — Boss'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(12),
              itemCount: model.messages.length,
              itemBuilder: (context, i) {
                final m = model.messages[i];
                return Align(
                  alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical:6),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.fromUser ? Colors.cyanAccent.withOpacity(0.9) : Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text, style: TextStyle(fontSize:16)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(model.listening ? Icons.mic : Icons.mic_none),
                  onPressed: () async {
                    if (!model.listening) {
                      await model.startListening((text) {
                        model.addUser(text);
                      });
                    } else {
                      model.stopListening();
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Type your command, Boss...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (t) {
                      if (t.trim().isEmpty) return;
                      model.addUser(t.trim());
                      _ctrl.clear();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final t = _ctrl.text.trim();
                    if (t.isEmpty) return;
                    model.addUser(t);
                    _ctrl.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
