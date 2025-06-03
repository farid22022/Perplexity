import 'package:web_socket_client/web_socket_client.dart';
import 'dart:convert';

class ChatWebService {
  WebSocket? _socket;
  final String userId = "user123"; // Replace with actual user ID
  final String token = "your-jwt-token"; // Replace with actual token
  // ConnectionState _currentConnectionState = ConnectionState.disconnected;

  // Public stream to listen to WebSocket messages
  Stream<dynamic> get messages => _socket?.messages ?? Stream.empty();

  // Public getter for current connection state
  // ConnectionState get connectionState => _currentConnectionState;

  void connect() {
    // Initialize WebSocket with token
    _socket = WebSocket(Uri.parse('ws://localhost:8000/ws/chat?token=$token'));

    // Listen to connection state changes
    _socket!.connection.listen(
      (state) {
        // _currentConnectionState = state as ConnectionState;
        print('WebSocket connection state: $state');
      },
      onError: (error) {
        print('WebSocket connection error: $error');
        // _currentConnectionState = ConnectionState.disconnected;
        // Attempt to reconnect after 5 seconds
        Future.delayed(Duration(seconds: 5), connect);
      },
      onDone: () {
        print('WebSocket connection closed');
        // _currentConnectionState = ConnectionState.disconnected;
        // Attempt to reconnect after 5 seconds
        Future.delayed(Duration(seconds: 5), connect);
      },
    );

    // Listen to messages (for logging or debugging)
    _socket!.messages.listen(
      (message) {
        print('Received message: $message');
      },
      onError: (error) {
        print('WebSocket message error: $error');
        // Attempt to reconnect after 5 seconds
        Future.delayed(Duration(seconds: 5), connect);
      },
      onDone: () {
        print('WebSocket message stream closed');
        // _currentConnectionState = ConnectionState.disconnected;
        // Attempt to reconnect after 5 seconds
        Future.delayed(Duration(seconds: 5), connect);
      },
    );
  }

  void chat(String query) {
    // if (_currentConnectionState == ConnectionState.connected) {
      _socket!.send(json.encode({'query': query, 'user_id': userId}));
    // } else {
    //   print('WebSocket not connected. Attempting to reconnect...');
    //   connect();
    // }
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
    // _currentConnectionState = ConnectionState.disconnected;
  }
}