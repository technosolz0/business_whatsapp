import 'dart:io';
import 'dart:typed_data';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/client_model.dart';

class ClientsService {
  final Dio _dio = NetworkUtilities.getDioClient();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get all clients
  Future<List<ClientModel>> getClients() async {
    try {
      final response = await _dio.get(ApiEndpoints.getAllClients);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((data) => ClientModel.fromJson(data, data['client_id']))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting clients: $e');
      return [];
    }
  }

  /// Get a single client by ID
  Future<ClientModel?> getClientById(String id) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getClientDetails,
        queryParameters: {'clientId': id},
      );

      if (response.statusCode == 200) {
        return ClientModel.fromJson(response.data, id);
      }
      return null;
    } catch (e) {
      print('Error getting client by ID: $e');
      return null;
    }
  }

  /// Add a new client
  Future<String?> addClient(ClientModel client) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.addClient,
        data: client.toJson(),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['clientId'];
      }
      return null;
    } catch (e) {
      print('Error adding client: $e');
      return null;
    }
  }

  /// Update an existing client
  Future<bool> updateClient(String id, ClientModel client) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.patchClient,
        queryParameters: {'clientId': id},
        data: client.toJson(),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Error updating client: $e');
      return false;
    }
  }

  /// Delete a client
  Future<bool> deleteClient(String id) async {
    try {
      final response = await _dio.delete(
        ApiEndpoints.deleteClient,
        queryParameters: {'clientId': id},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Error deleting client: $e');
      return false;
    }
  }

  /// Upload a file to Firebase Storage (Keeping Firebase for media for now)
  Future<String?> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Upload raw data (bytes) to Firebase Storage (For Web)
  Future<String?> uploadData(Uint8List data, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putData(data);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading data: $e');
      return null;
    }
  }

  /// Search clients by name or phone number
  Future<List<ClientModel>> searchClients(String query) async {
    try {
      // For now, search locally after fetching all, or we could add a backend search
      final allClients = await getClients();

      if (query.isEmpty) {
        return allClients;
      }

      final lowercaseQuery = query.toLowerCase();
      return allClients.where((client) {
        return client.name.toLowerCase().contains(lowercaseQuery) ||
            client.phoneNumber.contains(query);
      }).toList();
    } catch (e) {
      print('Error searching clients: $e');
      return [];
    }
  }
}
