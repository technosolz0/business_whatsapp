import 'dart:async';
import 'dart:convert';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_model.dart'; // Adjust path if needed

class ChatService {
  final Dio _dio = NetworkUtilities.getDioClient();
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _wsStreamController;

  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  /// Fetch list of chats for a client
  Future<List<Map<String, dynamic>>> getChats(String clientId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getChats,
        queryParameters: {'clientId': clientId},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to load chats');
    } catch (e) {
      debugPrint('Error in getChats: $e');
      rethrow;
    }
  }

  /// Fetch list of admins for a client
  Future<List<Map<String, dynamic>>> getAdmins(String clientId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getAdmins,
        queryParameters: {'clientId': clientId},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to load admins');
    } catch (e) {
      debugPrint('Error in getAdmins: $e');
      rethrow;
    }
  }

  /// Fetch messages for a specific chat with pagination
  Future<List<Map<String, dynamic>>> getMessages({
    required String chatId,
    required String clientId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getMessages,
        queryParameters: {
          'chatId': chatId,
          'clientId': clientId,
          'limit': limit,
          'offset': offset,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to load messages');
    } catch (e) {
      debugPrint('Error in getMessages: $e');
      rethrow;
    }
  }

  /// Send a text or media message
  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.sendMessage, data: data);
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to send message: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error in sendMessage: $e');
      rethrow;
    }
  }

  /// Update chat properties (isActive, unRead, isFavourite)
  Future<void> updateChat(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(ApiEndpoints.patchChat, data: data);
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to update chat');
      }
    } catch (e) {
      debugPrint('Error in updateChat: $e');
      rethrow;
    }
  }

  /// Create a new chat from a contact
  Future<void> createChat(String clientId, String chatId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.createChat,
        data: {'clientId': clientId, 'chatId': chatId},
      );
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to create chat');
      }
    } catch (e) {
      debugPrint('Error in createChat: $e');
      rethrow;
    }
  }

  /// Delete a chat and its messages
  Future<void> deleteChat(String clientId, String chatId) async {
    try {
      final response = await _dio.delete(
        ApiEndpoints.deleteChat,
        queryParameters: {'clientId': clientId, 'chatId': chatId},
      );
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to delete chat');
      }
    } catch (e) {
      debugPrint('Error in deleteChat: $e');
      rethrow;
    }
  }

  /// Initialize WebSocket connection
  void initWebSocket(String clientId) {
    if (_channel != null) {
      _channel!.sink.close();
    }

    _wsStreamController ??= StreamController<Map<String, dynamic>>.broadcast();

    final url = ApiEndpoints.wsUrl(clientId);
    debugPrint('Connecting to WebSocket: $url');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        (data) {
          debugPrint('WebSocket received: $data');
          try {
            final Map<String, dynamic> message = jsonDecode(data);
            _wsStreamController?.add(message);
          } catch (e) {
            debugPrint('Error decoding WS message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _reconnect(clientId);
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _reconnect(clientId);
        },
      );
    } catch (e) {
      debugPrint('Error initializing WebSocket: $e');
      _reconnect(clientId);
    }
  }

  void _reconnect(String clientId) {
    // Basic reconnection logic
    Future.delayed(const Duration(seconds: 5), () {
      debugPrint('Attempting to reconnect WebSocket...');
      initWebSocket(clientId);
    });
  }

  Stream<Map<String, dynamic>> get webSocketStream =>
      _wsStreamController?.stream ?? const Stream.empty();

  void closeWebSocket() {
    _channel?.sink.close();
    _wsStreamController?.close();
    _wsStreamController = null;
    _channel = null;
  }
}
