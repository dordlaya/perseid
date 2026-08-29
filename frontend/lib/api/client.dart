import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:5173/api';
  static const String wsUrl = 'ws://localhost:5173/ws';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<Snapshot> _snapshotController = StreamController<Snapshot>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  Stream<Snapshot> get snapshotStream => _snapshotController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  Timer? _reconnectTimer;
  int _reconnectDelay = 500;

  void connectStream() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _connectionController.add(true);
      _reconnectDelay = 500;

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            final snapshot = Snapshot.fromJson(data);
            _snapshotController.add(snapshot);
          } catch (e) {
            print('Error parsing snapshot: $e');
          }
        },
        onDone: () {
          _handleDisconnect();
        },
        onError: (error) {
          _handleDisconnect();
        },
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _connectionController.add(false);
    _subscription?.cancel();
    _channel?.sink.close();
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _reconnectDelay), () {
      _reconnectDelay = (_reconnectDelay * 1.6).toInt().clamp(500, 8000);
      connectStream();
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _snapshotController.close();
    _connectionController.close();
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'ok': false, 'error': 'network'};
    }
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'ok': false, 'error': 'network'};
    }
  }

  Future<void> setStatus(int id, bool value) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'value': value}),
      );
    } catch (e) {
      // Ignore network errors for status updates
    }
  }

  Future<void> reset() async {
    try {
      await http.post(Uri.parse('$baseUrl/reset'));
    } catch (e) {
      // Ignore network errors for reset
    }
  }

  Future<Map<String, dynamic>> boost(int id) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/boost'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'ok': false, 'error': 'network'};
    }
  }

  Future<Map<String, dynamic>> jam(int attacker, int target) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/jam'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'attacker': attacker, 'target': target}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'ok': false, 'error': 'network'};
    }
  }
}
