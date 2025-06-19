import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ChatScreen(myId: 'user1', peerId: 'user2'));
  }
}

class ChatScreen extends StatefulWidget {
  final String myId;
  final String peerId;

  const ChatScreen({super.key, required this.myId, required this.peerId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  final String text;
  final bool isMine;
  _ChatMessage(this.text, this.isMine);
}

class _ChatScreenState extends State<ChatScreen> {
  late IO.Socket socket;
  final TextEditingController controller = TextEditingController();
  final List<_ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    socket = IO.io('http://192.168.100.127:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.onConnect((_) {
      print('✅ Connected');
      socket.emit('join', widget.myId);
    });

    socket.on('private-message', (data) {
      setState(() {
        messages.add(_ChatMessage(data['message'], false));
      });
    });
  }

  void _sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    socket.emit('private-message', {
      'to': widget.peerId,
      'from': widget.myId,
      'message': text,
    });

    setState(() {
      messages.add(_ChatMessage(text, true));
    });

    controller.clear();
  }

  @override
  void dispose() {
    controller.dispose();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat: ${widget.myId}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment:
                      msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isMine ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(msg.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
