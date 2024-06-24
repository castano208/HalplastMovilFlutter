import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as socket;


void main() {
  final client = socket.io('http:/localhost:3000',
  <String, dynamic>{
    'transports': ['websocket'],
  });

  client.onConnect((_) {
    print('Connected!');

     readLine()
    .listen((String line) => client.emit('stream', line));
  });

  client.on('msg', (data) => _printFromServer(data));
}

Stream<String> readLine() => stdin
.transform(utf8.decoder)
.transform(const LineSplitter());

void _printFromServer(String message) => print(message);