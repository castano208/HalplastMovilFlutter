import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  IOWebSocketChannel? _channel;
  Set<String> _processedMessages = {};

  List<ChatMessage> get messages => _messages;

  void connectWebSocket(String sistemaChatId) {
    if (_channel != null) {
      return;
    }

    _channel = IOWebSocketChannel.connect('wss://apihalplast.onrender.com/ws');
    _channel!.stream.listen((message) async {
      if (message.isNotEmpty) {
        try {
          final Map<String, dynamic> data = jsonDecode(message);
          final messageId = data['timestamp'];

          if (!_processedMessages.contains(messageId)) {
            _processedMessages.add(messageId);
            final chatMessage = ChatMessage(
              id: messageId,
              senderId: data['id_usuario'],
              message: data['mensaje'],
              timestamp: DateTime.parse(data['timestamp']),
            );
            _messages.add(chatMessage);
            notifyListeners();
          }
        } catch (error) {
          print('Failed to process message: $error');
        }
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    });
  }

  Future<void> fetchMessages(String sistemaChatId, String userId, String userRol, String OtroUsuario) async {

    try {
      final response = await http.get(
        Uri.parse('https://apihalplast.onrender.com/api/chatPqrs/mensajes/$sistemaChatId'),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        String correo;
        if (responseData != null) {
          final List<dynamic> clienteMessages = responseData['mensajeCliente'];
          final List<dynamic> empleadoMessages = responseData['mensajeEmpleado'];
          _messages.clear();

          if (userRol == "cliente") {
            correo = userId;
          }else{
            correo = OtroUsuario;
          }
          clienteMessages.forEach((msg) {
            final chatMessage = ChatMessage(
              id: msg['_id'],
              senderId: correo,
              message: msg['mensaje'],
              timestamp: DateTime.parse(msg['timestamp']),
            );
            _messages.add(chatMessage);
            _processedMessages.add(chatMessage.timestamp.toIso8601String());
          });

          if (userRol == "empleado") {
            correo = userId;
          }else{
            correo = OtroUsuario;
          }
          empleadoMessages.forEach((msg) {
            final chatMessage = ChatMessage(
              id: msg['_id'],
              senderId: correo,
              message: msg['mensaje'],
              timestamp: DateTime.parse(msg['timestamp']),
            );
            _messages.add(chatMessage);
            _processedMessages.add(chatMessage.timestamp.toIso8601String());
          });

          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          notifyListeners();
        } else {
          _messages = [];
          final response2 = await http.post(
            Uri.parse('https://apihalplast.onrender.com/api/chatPqrs/mensajes/crear/$sistemaChatId'),
            headers: {'Content-Type': 'application/json'},
          );
          if (response2.statusCode != 201) {
            print('Failed to create chat: ${response2.body}');
          }
        }
      } else {
        print('Failed to load chat data: ${response.body}');
      }
    } catch (error) {
      print('Failed to fetch messages: $error');
    }
  }

  Future<void> sendMessage(String sistemaChatId, String message, String userId) async {
    final timestamp = DateTime.now().toIso8601String();
    final msg = jsonEncode({
      'mensaje': message,
      'id_usuario': userId,
      'sistemaChatId': sistemaChatId,
      'timestamp': timestamp,
    });

    _channel!.sink.add(msg);

    final response = await http.post(
      Uri.parse('https://apihalplast.onrender.com/api/chatPqrs/mensajes/$sistemaChatId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mensaje': message, 'id_usuario': userId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save message');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String message;
  final DateTime timestamp;

  ChatMessage({required this.id, required this.senderId, required this.message, required this.timestamp});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'],
      senderId: json['senderId'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String sistemaChatId;
  final String userId;
  final String userRol;
  final String OtroUsuario;

  ChatScreen({required this.sistemaChatId, required this.userId, required this.userRol, required this.OtroUsuario});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();
  late ChatProvider chatProvider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      await chatProvider.fetchMessages(widget.sistemaChatId, widget.userId, widget.userRol, widget.OtroUsuario);
      chatProvider.connectWebSocket(widget.sistemaChatId);
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, provider, child) {
                      if (provider.messages.isEmpty) {
                        return Center(
                          child: Text('Chat vacio.'),
                        );
                      } else {
                        return ListView.builder(
                          itemCount: provider.messages.length,
                          itemBuilder: (context, index) {
                            final message = provider.messages[index];
                            bool isCurrentUser = message.senderId == widget.userId;

                            return Align(
                              alignment: isCurrentUser ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: isCurrentUser ? Colors.grey[300]! : Colors.lightBlueAccent,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.message,
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                    SizedBox(height: 4.0),
                                    Text(
                                      '${message.timestamp.hour}:${message.timestamp.minute}',
                                      style: TextStyle(fontSize: 12.0, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            labelText: 'Envia un mensaje...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          final message = messageController.text;
                          chatProvider.sendMessage(widget.sistemaChatId, message, widget.userId);
                          messageController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
