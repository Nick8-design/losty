import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../service/chat_service.dart';


class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService chatService = ChatService();
  List<Map<String, String>> messages = [];
  bool isTyping = false;
  final ScrollController _scrollController = ScrollController();


  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }


  void sendMessage() async {
    String userMessage = _controller.text;
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": userMessage});
      isTyping = true;
    });

    _controller.clear();

    String aiResponse = await chatService.sendMessage(userMessage);

    setState(() {
      messages.add({"role": "ai", "text": aiResponse});
      isTyping = false;
    });
    Future.delayed(Duration(milliseconds: 300), _scrollToBottom);

  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        messages.add({"role": "ai", "text": "Hello! Welcome to the Lost and Found app. What is your name?"});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lost & Found Assistant")),
      body: Column(
        children: [


          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,  // Add this controller
                  itemCount: messages.length + (isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (isTyping && index == messages.length) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Typing...", style: TextStyle(fontStyle: FontStyle.italic)),
                      );
                    }
                    final message = messages[index];
                    return Align(
                      alignment: message["role"] == "user" ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message["role"] == "user" ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          message["text"]!,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _scrollToBottom,
                    child: Icon(Icons.arrow_downward),
                  ),
                )
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
