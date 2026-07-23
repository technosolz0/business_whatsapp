import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:business_whatsapp/app/data/models/question_model.dart';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/main.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ChatBotService {
  final Dio _dio = Dio()..interceptors.add(PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
    compact: true,
  ));
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload files to the store
  Future<Map<String, dynamic>> uploadDocuments({
    required bool isQnA,
    required List<MultipartFile> files,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> formDataMap = {
        'clientId': clientID,
        'isQnA': isQnA,
      };

      if (description != null && description.isNotEmpty) {
        formDataMap['description'] = description;
      }

      for (int i = 0; i < files.length; i++) {
        formDataMap['file${i + 1}'] = files[i];
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post(ApiEndpoints.uploadChatbotDoc, data: formData);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to upload documents: ${response.statusMessage}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          'API Error: ${e.response?.data?['detail'] ?? e.response?.data?['message'] ?? e.message}',
        );
      }
      rethrow;
    }
  }

  /// Update a file in the store
  Future<Map<String, dynamic>> updateDocument({
    required bool isQnA,
    required String id,
    required MultipartFile file,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> formDataMap = {
        'clientId': clientID,
        'isQnA': isQnA,
        'id': id,
        'file1': file,
      };

      if (description != null && description.isNotEmpty) {
        formDataMap['description'] = description;
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post(ApiEndpoints.updateChatbotDoc, data: formData);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to update document: ${response.statusMessage}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          'API Error: ${e.response?.data?['detail'] ?? e.response?.data?['message'] ?? e.message}',
        );
      }
      rethrow;
    }
  }

  /// List documents from the store
  Future<Map<String, dynamic>> listDocuments({
    required bool isQnA,
    int pageSize = 20,
    String? pageToken,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'clientId': clientID,
        'isQnA': isQnA,
        'pageSize': pageSize,
      };

      if (pageToken != null && pageToken.isNotEmpty) {
        queryParams['pageToken'] = pageToken;
      }

      final response = await _dio.get(ApiEndpoints.listChatbotDocs, queryParameters: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(
          'Failed to list documents: ${response.data['message'] ?? response.statusMessage}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          'API Error: ${e.response?.data?['detail'] ?? e.response?.data?['message'] ?? e.message}',
        );
      }
      rethrow;
    }
  }

  /// Delete a document from the store
  Future<Map<String, dynamic>> deleteDocument({required String id}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.deleteChatbotDoc,
        data: {'clientId': clientID, 'id': id},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(
          'Failed to delete document: ${response.data['message'] ?? response.statusMessage}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          'API Error: ${e.response?.data?['detail'] ?? e.response?.data?['message'] ?? e.message}',
        );
      }
      rethrow;
    }
  }

  /// Stream of questions from Firestore
  Stream<List<QuestionModel>> getBotQuestionsStream() {
    return _firestore
        .collection('unanswered_questions')
        .doc(clientID)
        .collection('data')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return QuestionModel.fromFirestore(doc.id, doc.data());
          }).toList();
        });
  }

  /// Update a question document in Postgres (and syncs to Firestore)
  Future<void> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrint("Updating question in backend: $questionId with data: $data");
      
      final response = await _dio.post(
        ApiEndpoints.updateChatbotQuestion,
        data: {
          'clientId': clientID,
          'questionId': questionId,
          'data': data,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to update question: $e');
    }
  }

  /// Delete a question document from Postgres (and syncs to Firestore)
  Future<void> deleteQuestion({required String questionId}) async {
    try {
      debugPrint("Deleting question in backend: $questionId");
      
      final response = await _dio.post(
        ApiEndpoints.deleteChatbotQuestion,
        data: {
          'clientId': clientID,
          'questionId': questionId,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to delete question: $e');
    }
  }
}
