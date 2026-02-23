import 'dart:typed_data';

import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';

import 'package:business_whatsapp/app/Utilities/constants/app_constants.dart';
import 'package:business_whatsapp/app/data/models/broadcast_payload.dart';
import 'package:business_whatsapp/app/data/models/broadcast_status.dart';
import 'package:business_whatsapp/app/data/models/quota_model.dart';
import 'package:business_whatsapp/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../models/broadcast_model.dart';
import 'package:intl/intl.dart';

class BroadcastFirebaseService {
  static final BroadcastFirebaseService instance = BroadcastFirebaseService._();
  BroadcastFirebaseService._();

  CollectionReference<Map<String, dynamic>> get _ref => FirebaseFirestore
      .instance
      .collection("broadcasts")
      .doc(clientID)
      .collection("data");

  CollectionReference<Map<String, dynamic>> get _quotaRef => FirebaseFirestore
      .instance
      .collection("quota")
      .doc(clientID)
      .collection("data");

  /// -----------------------------------------------------------
  /// SAVE DRAFT
  /// -----------------------------------------------------------
  Future<String> saveDraft(BroadcastModel model) async {
    if (model.id != null && model.id!.isNotEmpty) {
      // Updating existing draft
      final docRef = _ref.doc(model.id);

      final data = model.toDraftJson();
      data.remove('createdAt'); // Don't reset creation time

      await docRef.set(data, SetOptions(merge: true));
      return docRef.id;
    } else {
      // Creating new draft
      final docRef = _ref.doc();
      model.id = docRef.id;
      await docRef.set(model.toDraftJson());
      return docRef.id;
    }
  }

  Future<String> saveBroadcast(BroadcastModel model) async {
    final docRef = _ref.doc(); // assign to model
    await docRef.set(model.toFirestore());
    return docRef.id; // return auto id
  }

  Future<String> saveQuota(QuotaModel model, String date) async {
    final docRef = _quotaRef.doc(date);
    final snap = await docRef.get();

    if (!snap.exists) {
      // Document doesn't exist → create new
      await docRef.set(model.toJson());
      return docRef.id;
    }

    // Document exists → update
    final existing = snap.data()!;

    int oldUsedQuota = existing["usedQuota"] ?? 0;
    List<dynamic> oldHistory = existing["broacast_history"] ?? [];

    // Convert to list of maps
    List<Map<String, dynamic>> updatedHistory = List<Map<String, dynamic>>.from(
      oldHistory,
    );

    for (var newItem in model.broadcasts) {
      int index = updatedHistory.indexWhere(
        (e) => e["broadcastId"] == newItem.broadcastId,
      );

      if (index >= 0) {
        // Update message_count of existing broadcast
        updatedHistory[index]["message_count"] =
            (updatedHistory[index]["message_count"] ?? 0) +
            newItem.messageCount;
      } else {
        // Add new broadcastHistory entry
        updatedHistory.add(newItem.toJson());
      }
    }

    int updatedUsedQuota = oldUsedQuota + model.usedQuota;

    await docRef.update({
      "usedQuota": updatedUsedQuota,
      "broacast_history": updatedHistory,
    });

    return docRef.id;
  }

  Future<bool> willExceedQuota(int newCount, String date) async {
    final docRef = _quotaRef.doc(date);
    final snap = await docRef.get();

    int used = 0;
    if (snap.exists) {
      used = snap.data()?["usedQuota"] ?? 0;
    }

    return (used + newCount) > AppConstants.dailyLimit;
  }

  Future<int> getUsedQuota() async {
    final String date = DateTime.now().toIso8601String().split('T')[0];
    final docRef = _quotaRef.doc(date);
    final snap = await docRef.get();
    //print("usedQouta : ${snap.data()?["usedQuota"] ?? 0}");
    return snap.data()?["usedQuota"] ?? 0;
  }

  Future<int> getActiveBroadcastCount() async {
    const activeStatuses = ['Sending', 'Pending', 'Scheduled'];

    final snap = await _ref.where("status", whereIn: activeStatuses).get();
    return snap.docs.length;
  }
  //---------------------------------------------------------------
  // 🔽 DOWNLOAD FILE FROM FIREBASE STORAGE
  //---------------------------------------------------------------

  Future<BroadcastMedia?> getBroadcastMedia(String id) async {
    try {
      final folderRef = FirebaseStorage.instance.ref("broadcasts_media/$id");

      final list = await folderRef.listAll();
      if (list.items.isEmpty) {
        //print("❌ No file found for ID: $id");
        return null;
      }

      final fileRef = list.items.first;

      // Download bytes
      final data = await fileRef.getData();
      if (data == null) return null;

      return BroadcastMedia(name: fileRef.name, bytes: data);
    } catch (e) {
      //print("❌ Error downloading media: $e");
      return null;
    }
  }

  /// -----------------------------------------------------------
  /// ADD A MESSAGE INSIDE BROADCAST DOCUMENT
  /// Collection: broadcasts/{broadcastId}/messages/{autoId}
  /// -----------------------------------------------------------
  Future<String> addBroadcastMessage(
    String broadcastId,
    BroadcastMessagePayload message,
  ) async {
    try {
      // Generate the Firestore auto ID first
      final msgRef = _ref.doc(broadcastId).collection("messages").doc();

      // assign this auto ID into your message model
      message.messageId = msgRef.id;

      // save to Firestore
      await msgRef.set(message.toJson());

      return msgRef.id; // return auto ID
    } catch (e) {
      // debugPrint("❌ Error adding broadcast message: $e");
      rethrow;
    }
  }

  /// -----------------------------------------------------------
  /// UPDATE DRAFT
  /// (only updates fields provided)
  /// -----------------------------------------------------------
  Future<void> updateDraft(String id, BroadcastModel model) async {
    BroadcastStatus draft = BroadcastStatus.draft;
    await _ref.doc(id).update({
      ...model.toFirestore(), // overwrite all fields like saveBroadcast
      "status": draft.label, // change status from draft → pending
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// -----------------------------------------------------------
  /// DELETE BROADCAST
  /// -----------------------------------------------------------

  Future<void> deleteBroadcast(
    String id,
    DateTime? createdAt,
    int? sent,
    int? delivered,
    int? read,
    int? scheduled,
  ) async {
    final doc = _ref.doc(id);

    // CASE 1: createdAt is null ➜ delete broadcast only
    if (createdAt == null) {
      //print("createdAt is NULL → Deleting broadcast only");

      // Delete subcollections
      final subs = ['messages'];
      for (final sub in subs) {
        final query = await doc.collection(sub).get();
        for (final d in query.docs) {
          await d.reference.delete();
        }
      }
      if (scheduled != 0) {
        // print('scheduled is NOT NULL → Deleting broadcast only $scheduled');
        await deleteScheduledBroadcast(clientID, id);
      }

      // Delete main document
      await doc.delete();

      //print("Broadcast $id deleted (no totalSendMsg update)");
      return; // ⛔ stop here
    }

    // CASE 2: createdAt is NOT null ➜ update totals and delete
    //print("createdAt is NOT NULL → Updating totals + deleting broadcast");

    // Format date as yyyy-MM-dd
    final dateId = DateFormat("yyyy-MM-dd").format(createdAt);

    // totalsendmsg/{adminID}/data/{yyyy-MM-dd}
    final totalMsgRef = FirebaseFirestore.instance
        .collection("totalSendMsg")
        .doc(clientID)
        .collection("data")
        .doc(dateId);

    // Subtract values
    await totalMsgRef.set({
      "date": dateId,
      "totalSent": FieldValue.increment(-(sent ?? 0)),
      "totalDelivered": FieldValue.increment(-(delivered ?? 0)),
      "totalRead": FieldValue.increment(-(read ?? 0)),
      "updatedAt": DateTime.now(),
    }, SetOptions(merge: true));

    // Delete subcollections
    final subs = ['messages'];
    for (final sub in subs) {
      final query = await doc.collection(sub).get();
      for (final d in query.docs) {
        await d.reference.delete();
      }
    }

    // Delete broadcast document
    await doc.delete();

    //print("Broadcast $id deleted and totals updated successfully");
  }

  /// -----------------------------------------------------------
  /// GET A SINGLE BROADCAST
  /// -----------------------------------------------------------
  Future<BroadcastModel?> getBroadcast(String id) async {
    final doc = await _ref.doc(id).get();
    if (!doc.exists) return null;
    return BroadcastModel.fromFirestore(doc);
  }

  /// -----------------------------------------------------------
  /// GET ALL BROADCASTS (including drafts)
  /// -----------------------------------------------------------
  Future<List<BroadcastModel>> getAllBroadcasts() async {
    final snap = await _ref.orderBy("createdAt", descending: true).get();
    return snap.docs.map(BroadcastModel.fromFirestore).toList();
  }

  /// -----------------------------------------------------------
  /// GET ONLY DRAFT BROADCASTS
  /// -----------------------------------------------------------
  Future<List<BroadcastModel>> getDrafts() async {
    final snap = await _ref
        .where("status", isEqualTo: "draft")
        .orderBy("createdAt", descending: true)
        .get();

    return snap.docs.map(BroadcastModel.fromFirestore).toList();
  }

  Future<int> getBroadcastsCount() async {
    final snap = await _ref.count().get();
    return snap.count ?? 0;
  }

  Future<List<BroadcastModel>> getBroadcastsPaginated({
    required int page,
    required int pageSize,
  }) async {
    Query query = _ref.orderBy("createdAt", descending: true).limit(pageSize);

    if (page > 1) {
      final prevSnap = await _ref
          .orderBy("createdAt", descending: true)
          .limit((page - 1) * pageSize)
          .get();

      if (prevSnap.docs.isNotEmpty) {
        query = query.startAfterDocument(prevSnap.docs.last);
      }
    }

    final snap = await query.get();
    return snap.docs
        .map(
          (doc) => BroadcastModel.fromFirestore(
            doc as QueryDocumentSnapshot<Map<String, dynamic>>,
          ),
        )
        .toList();
  }

  /// -----------------------------------------------------------
  /// STREAM ALL BROADCASTS (Realtime)
  /// -----------------------------------------------------------
  Stream<List<BroadcastModel>> streamBroadcasts() {
    return _ref
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BroadcastModel.fromFirestore).toList());
  }

  /// -----------------------------------------------------------
  /// STREAM SINGLE BROADCAST (Realtime)
  /// -----------------------------------------------------------
  Stream<BroadcastModel?> streamBroadcast(String id) {
    return _ref.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BroadcastModel.fromFirestore(doc);
    });
  }

  /// -----------------------------------------------------------
  /// CHECK IF BROADCAST LIMIT (10 ACTIVE) IS EXCEEDED
  /// Active statuses: sending, pending, scheduled
  /// -----------------------------------------------------------
  Future<bool> isBrodcastCreationLimitExceeded() async {
    const activeStatuses = ['Sending', 'Pending', 'Scheduled'];

    final snap = await _ref.where("status", whereIn: activeStatuses).get();
    return snap.docs.length >= AppConstants.activeBroadcastLimit;
  }

  Future<void> deleteScheduledBroadcast(
    String clientID,
    String broadcastId,
  ) async {
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.post(
        ApiEndpoints.deleteScheduledBroadcast,
        data: {'clientId': clientID, 'broadcastId': broadcastId},
      );

      if (response.statusCode == 200) {
        // print('✅ Scheduled broadcast deleted via API');
      } else {
        print('❌ Failed to delete scheduled broadcast: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error calling delete API: $e');
    }
  }
}

class BroadcastMedia {
  final String name;
  final Uint8List bytes;

  BroadcastMedia({required this.name, required this.bytes});
}
