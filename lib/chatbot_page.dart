import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"sender": "bot", "text": "Namaste! Mai ek health assistant hoon. Aapki kya madad kar sakta hoon?"}
  ];

  void _sendMessage() async {
    final message = _messageController.text;
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": message});
      _messageController.clear();
    });

    try {
      final response = await ApiService.sendChatbotMessage(message);
      if (!mounted) return;

      setState(() {
        _messages.add({"sender": "bot", "text": response['response'] ?? "Kuch galat ho gaya."});
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({"sender": "bot", "text": "Maaf kijiye, abhi mai jawab nahi de sakta."});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Chatbot"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return _buildMessage(message['sender']!, message['text']!);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessage(String sender, String text) {
    final isBot = sender == "bot";
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isBot ? Colors.grey.shade300 : Colors.teal,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isBot ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Apna message type karein...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.teal,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
