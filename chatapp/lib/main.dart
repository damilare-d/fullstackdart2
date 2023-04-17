import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fullstackdart app',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'fullstackdart app'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();

  int _counter = 0;
  late WebSocketChannel _channel;
  final _messages = [];
  String? dmessage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/ws2'),
    );
    _channel.stream.listen((value) => setState(() {
          _counter = int.tryParse(value) ?? _counter;
        }));
    // _channel.stream.listen((value) => setState(() {
    //       _messages.add(value);
    //     }));
  }
  // _channel.stream.listen((value) {
  //   setState(() {
  //     _counter = int.tryParse(value) ?? _counter;
  //   });
  // });
  // IO.Socket socket = IO.io('http://localhost:3000');
  // socket.onConnect((_) {
  //   stdout.writeln('connect');
  //   socket.emit('msg', 'test');
  // });
  // socket.on('event', (data) => stdout.writeln(data));
  // socket.onDisconnect((_) => stdout.writeln('disconnect'));
  // socket.on('fromServer', (_) => stdout.writeln(_));

  void _incrementCounter() {
    setState(() {
      // _counter++;
      _channel.sink.add('increment');
    });
  }

  void _decrementCounter() {
    setState(() {
      // _counter--;
      _channel.sink.add('decrease');
    });
  }

  void _sendMessage2() {
    if (_controller.text.isNotEmpty) {
      _channel.sink.add(_controller.text);
    }
  }

  void _sendMessage() {
    final message = _controller.text;
    _channel.sink.add('the send button works');
    if (_controller.text.isNotEmpty) {
      _channel.sink.add(jsonEncode({
        'action': 'send',
        'data': {
          'username': 'user',
          'room': 'room',
          'message': message,
        },
      }));
      setState(() {
        _messages.add(message);
        //dmessage = message;
        dmessage = _messages.last;
        _controller.clear();
      });
      print('Message sent: $dmessage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _controller.text;
    print('Message sent build: $dmessage');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Send a message'),
            ),
            Text(
              'Message sent: ${dmessage ?? ''}',
              style: const TextStyle(fontSize: 18),
            ),
            // StreamBuilder(
            //   stream: _channel.stream,
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.active &&
            //         snapshot.hasData) {
            //       final message = snapshot.data;
            //       return Text(message ?? 'message is null');
            //     } else {
            //       return const SizedBox(child: Text('message not recieved'));
            //     }
            //   },
            // ),
            // ListView.builder(
            //   shrinkWrap: true,
            //   itemExtent: 5,
            //   itemCount: _messages.length,
            //   itemBuilder: (context, index) {
            //     return Text(_messages[index]);
            //   },
            // ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              _counter.toString() ?? 'loading...',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            onPressed: _sendMessage2,
            tooltip: 'send message',
            child: const Icon(Icons.send),
          ),
          FloatingActionButton(
            onPressed: _decrementCounter,
            tooltip: 'decrease',
            child: const Icon(Icons.remove),
          ),
        ],
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
