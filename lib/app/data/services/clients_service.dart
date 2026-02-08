import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/client_model.dart';

class ClientsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _collectionName = 'clients';

  /// Get all clients
  Future<List<ClientModel>> getClients() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ClientModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting clients: $e');
      return [];
    }
  }

  /// Get a single client by ID
  Future<ClientModel?> getClientById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();

      if (doc.exists && doc.data() != null) {
        return ClientModel.fromJson(doc.data()!, doc.id);
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
      final docRef = await _firestore
          .collection(_collectionName)
          .doc(client.phoneNumberId)
          .set(client.toJson());
      return client.phoneNumberId;
    } catch (e) {
      print('Error adding client: $e');
      return null;
    }
  }

  /// Update an existing client
  Future<bool> updateClient(String id, ClientModel client) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(client.copyWith(updatedAt: DateTime.now()).toJson());
      return true;
    } catch (e) {
      print('Error updating client: $e');
      return false;
    }
  }

  /// Delete a client
  Future<bool> deleteClient(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting client: $e');
      return false;
    }
  }

  /// Upload a file to Firebase Storage
  /// Returns the download URL
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
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      final allClients = snapshot.docs
          .map((doc) => ClientModel.fromJson(doc.data(), doc.id))
          .toList();

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
