import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

late final WebSocket ws;

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/ws', webSocketHandler(_wsHandler));

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

Future<void> _wsHandler(WebSocketChannel webSocket) async {
  stdout.writeln('WebSocket connected');
  final socket = webSocket.cast<String>();
  await for (final message in socket.stream) {
    stdout.writeln('Received message: $message');
    final request = jsonDecode(message);
    final action = request['action'];
    final data = request['data'];
    switch (action) {
      case 'join':
        // Add user to chat room
        final username = data['username'];
        final room = data['room'];
        _joinRoom(username, room, webSocket);

        await joinroom(data['room'], ws);
        break;
      case 'leave':
        // Remove user from chat room
        final username = data['username'];
        final room = data['room'];
        _leaveRoom(username, room);

        await leaveroom(data['room'], ws);
        break;
      case 'send':
        // Send message to chat room
        final username = data['username'];
        final room = data['room'];
        final message = data['message'];
        await sendmessage(data['room'], data['message'], ws);
        _sendMessage(username, room, message);
        break;
      default:
        stdout.writeln('Invalid action: $action');
    }
  }
}

// Keep track of WebSocket connections for each room.
final Map<String, List<WebSocket>> rooms = {};

Future<void> joinroom(String room, WebSocket ws) async {
  // Add the WebSocket to the list of clients for the specified room.
  if (!rooms.containsKey(room)) {
    rooms[room] = [];
  }
  rooms[room]?.add(ws);
  await sendTo(ws, {'type': 'join', 'room': room});
}

Future<void> leaveroom(String room, WebSocket ws) async {
  // Remove the WebSocket from the list of clients for the specified room.
  if (rooms.containsKey(room)) {
    rooms[room]?.remove(ws);
    if (rooms[room]!.isEmpty || rooms[room] == null) {
      rooms.remove(room);
    }
  }
  await sendTo(ws, {'type': 'leave', 'room': room});
}

Future<void> sendmessage(String room, String message, WebSocket ws) async {
  // Send the message to all clients in the specified room.
  if (rooms.containsKey(room)) {
    final data = {'type': 'message', 'room': room, 'message': message};
    for (final client in rooms[room]!) {
      await sendTo(client, data);
    }
  }
}

Future sendTo(WebSocket ws, dynamic data) async {
  try {
    ws.add(json.encode(data));
  } catch (e) {
    print('Error: $e');
  }
}

final Map<String, List<WebSocketChannel>> _chatRooms = {};
final Map<WebSocketChannel, Map<String, dynamic>> _users = {};

void _joinRoom(String username, String room, WebSocketChannel socket) {
  final roomData = _chatRooms.putIfAbsent(room, () => <WebSocketChannel>[]);
  roomData.add(socket);

  _users[socket] = {'username': username, 'room': room};
}

void _leaveRoom(String username, String room) {
  final sockets = _chatRooms[room];
  if (sockets != null) {
    for (var socket in sockets) {
      if (_users.containsKey(socket) &&
          _users[socket]!['username'] == username) {
        sockets.remove(socket);
        _users.remove(socket);
        break;
      }
    }
  }
}

void _sendMessage(String username, String room, String message) {
  final sockets = _chatRooms[room];
  if (sockets != null) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'username': username,
      'message': message,
      'timestamp': timestamp
    };
    for (var socket in sockets) {
      socket.sink.add(json.encode(data));
    }
  }
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
