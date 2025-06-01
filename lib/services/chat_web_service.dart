import 'package:web_socket_client/web_socket_client.dart';
import 'dart:convert';

class ChatWebService {
  WebSocket? _socket;

  void connect() {
    _socket!.messages.listen((message) {
      final data = json.decode(message);
      print(data['type']);
    });
  }

  void chat(String query) {
    _socket!.send({'query': query});
  }
}
