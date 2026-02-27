import 'dart:async';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../modules/chats/models/chat_model.dart';
import '../../modules/chats/models/message_model.dart';

class ChatService {
  final Dio _dio = NetworkUtilities.getDioClient();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  /// Listen to list of chats for a client in real-time
  Stream<List<ChatModel>> getChatsStream(String clientId) {
    return _firestore
        .collection('chats')
        .doc(clientId)
        .collection('data')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Listen to messages for a specific chat in real-time
  Stream<List<MessageModel>> getMessagesStream(String chatId, String clientId) {
    return _firestore
        .collection('chats')
        .doc(clientId)
        .collection('data')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Fetch list of chats for a client (keep for backward compatibility if needed)
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

  /// Fetch messages for a specific chat with pagination (keep for legacy load more)
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
}
