import 'dart:typed_data';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:business_whatsapp/app/data/models/broadcast_model.dart';
import 'package:business_whatsapp/main.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BroadcastFirebaseService {
  BroadcastFirebaseService._();
  static final instance = BroadcastFirebaseService._();

  final Dio _dio = NetworkUtilities.getDioClient();

  Future<String> saveDraft(BroadcastModel model) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.createBroadcast,
        data: {...model.toDraftJson(), "clientId": clientID, "id": model.id},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['broadcastId'] ?? '';
      }
    } catch (e) {
      print("Error saving draft: $e");
    }
    return '';
  }

  Future<String> saveBroadcast(
    BroadcastModel model, {
    List<Map<String, dynamic>>? contacts,
  }) async {
    try {
      final payload = model.toApiJson();
      payload['clientId'] = clientID;
      payload['id'] = model.id;
      if (contacts != null) {
        payload['contacts'] = contacts;
      }
      if (model.deliveryTimestamp != null) {
        payload['deliveryTimestamp'] = model.deliveryTimestamp!
            .toUtc()
            .toIso8601String();
      }
      final response = await _dio.post(
        ApiEndpoints.createBroadcast,
        data: payload,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['broadcastId'] ?? '';
      }
    } catch (e) {
      print("Error saving broadcast: $e");
    }
    return '';
  }

  Future<void> saveQuota(dynamic quota, String date) async {
    // No-op in database mode
  }

  Future<void> updateDraft(String id, BroadcastModel model) async {
    try {
      final response = await _dio.patch(
        "${ApiEndpoints.patchBroadcast}?broadcastId=$id",
        data: model.toApiJson(),
      );
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to update draft: status ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Error updating draft: $e");
    }
  }

  Future<void> deleteBroadcast(
    String id,
    DateTime? createdAt,
    int? sent,
    int? delivered,
    int? read,
    int? scheduled,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.deleteBroadcast,
        queryParameters: {
          'clientId': clientID,
          'broadcastId': id,
          if (createdAt != null)
            'completedAt': createdAt.toUtc().toIso8601String(),
          if (sent != null) 'sent': sent,
          if (delivered != null) 'delivered': delivered,
          if (read != null) 'read': read,
        },
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception("Failed to delete broadcast");
      }
      if (scheduled != null && scheduled != 0) {
        await deleteScheduledBroadcast(id);
      }
    } catch (e) {
      print("Error deleting broadcast: $e");
    }
  }

  Future<BroadcastModel?> getBroadcast(String id) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getBroadcastDetails,
        queryParameters: {'broadcastId': id},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final bData = response.data['broadcast'];
        if (bData != null) {
          return BroadcastModel.fromJson(bData);
        }
      }
    } catch (e) {
      print("Error getting broadcast details: $e");
    }
    return null;
  }

  Future<List<BroadcastModel>> getAllBroadcasts() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getBroadcasts,
        queryParameters: {'clientId': clientID},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'] ?? [];
        return list.map((item) => BroadcastModel.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error fetching all broadcasts: $e");
    }
    return [];
  }

  Future<int> getBroadcastsCount() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getBroadcasts,
        queryParameters: {'clientId': clientID, 'page': 1, 'pageSize': 1},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['totalCount'] ?? 0;
      }
    } catch (e) {
      print("Error getting broadcasts count: $e");
    }
    return 0;
  }

  Future<List<BroadcastModel>> getBroadcastsPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getBroadcasts,
        queryParameters: {
          'clientId': clientID,
          'page': page,
          'pageSize': pageSize,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'] ?? [];
        return list.map((item) => BroadcastModel.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error fetching paginated broadcasts: $e");
    }
    return [];
  }

  Future<int> getUsedQuota() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getUsedQuota,
        queryParameters: {'clientId': clientID},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['usedQuota'] ?? 0;
      }
    } catch (e) {
      print("Error fetching used quota: $e");
    }
    return 0;
  }

  Future<int> getActiveBroadcastCount() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getActiveBroadcastsCount,
        queryParameters: {'clientId': clientID},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['count'] ?? 0;
      }
    } catch (e) {
      print("Error fetching active broadcast count: $e");
    }
    return 0;
  }

  Stream<List<BroadcastModel>> streamBroadcasts() {
    return Stream.value([]);
  }

  Stream<BroadcastModel?> streamBroadcast(String id) {
    return Stream.value(null);
  }

  Future<bool> isBrodcastCreationLimitExceeded() async {
    return false;
  }

  Future<void> deleteScheduledBroadcast(String id) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.deleteScheduledBroadcast,
        data: {'clientId': clientID, 'broadcastId': id},
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to delete scheduled broadcast");
      }
    } catch (e) {
      print("Error deleting scheduled broadcast: $e");
    }
  }

  Future<void> stopBroadcastRetry(String id) async {
    // Placeholder
  }

  Future<BroadcastMedia?> getBroadcastMedia(String id) async {
    try {
      final storageRef = FirebaseStorage.instance.ref(
        'broadcasts_media/$clientID/$id',
      );
      final list = await storageRef.listAll();

      if (list.items.isEmpty) {
        return null;
      }

      final fileRef = list.items.first;

      // Download bytes
      final data = await fileRef.getData();
      if (data == null) return null;

      return BroadcastMedia(name: fileRef.name, bytes: data);
    } catch (e) {
      print("Error downloading media: $e");
      return null;
    }
  }
}

class BroadcastMedia {
  final String name;
  final Uint8List bytes;

  BroadcastMedia({required this.name, required this.bytes});
}
