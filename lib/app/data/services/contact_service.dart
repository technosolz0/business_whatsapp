import 'package:adminpanel/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact_model.dart';

class ContactsService {
  static final ContactsService instance = ContactsService._();
  ContactsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'contacts';
  final String _deletedCollectionName = 'deleted_contacts';

  CollectionReference<Map<String, dynamic>> get _contactsRef =>
      _firestore.collection(_collectionName).doc(clientID).collection("data");

  CollectionReference<Map<String, dynamic>> get _deletedContactsRef =>
      _firestore
          .collection(_deletedCollectionName)
          .doc(clientID)
          .collection("data");

  // ---------------------------------------------------------------------------
  // STREAM: Get all contacts
  // ---------------------------------------------------------------------------
  Stream<List<ContactModel>> getContactsStream() {
    return _contactsRef.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => ContactModel.fromFirestore(doc))
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // One-time fetch
  // ---------------------------------------------------------------------------
  Future<List<ContactModel>> getAllContacts() async {
    final snapshot = await _contactsRef
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => ContactModel.fromFirestore(doc)).toList();
  }

  // ---------------------------------------------------------------------------
  // PAGINATION: Get contacts by page
  // ---------------------------------------------------------------------------
  Future<List<ContactModel>> getContactsPage({
    required int page,
    required int pageSize,
  }) async {
    final snapshot = await _contactsRef
        .orderBy('createdAt', descending: true)
        .limit(pageSize + 1) // Get one extra to check if there are more
        .get();

    final docs = snapshot.docs;
    final hasMore = docs.length > pageSize;

    // If we have more than pageSize, remove the extra one
    final contactsToReturn = hasMore ? docs.take(pageSize) : docs;

    return contactsToReturn
        .map((doc) => ContactModel.fromFirestore(doc))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Get by ID
  // ---------------------------------------------------------------------------
  Future<ContactModel?> getContactById(String id) async {
    final doc = await _contactsRef.doc(id).get();
    if (doc.exists) return ContactModel.fromFirestore(doc);
    return null;
  }

  // Fetch multiple contacts by IDs (with batching to bypass whereIn 30-limit)
  Future<List<ContactModel>> getContactsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    List<ContactModel> results = [];
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);

      final snap = await _contactsRef
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      results.addAll(
        snap.docs.map((doc) => ContactModel.fromFirestore(doc)).toList(),
      );
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // 🔍 NEW: Check if phone exists in DB
  // ---------------------------------------------------------------------------
  Future<bool> numberExists(
    String countryCallingCode,
    String phoneNumber,
  ) async {
    final snap = await _contactsRef
        .where('countryCallingCode', isEqualTo: countryCallingCode)
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    //print(snap.docs);
    return snap.docs.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // 🔍 NEW: Check if email exists in DB
  // ---------------------------------------------------------------------------
  Future<bool> emailExists(String? email) async {
    if (email == null || email.isEmpty) return false;

    final snap = await _contactsRef
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // ADD CONTACT
  // ---------------------------------------------------------------------------
  Future<String> addContact(ContactModel contact) async {
    try {
      // Duplicate phone check
      final duplicatePhone = await _contactsRef
          .where('countryCallingCode', isEqualTo: contact.countryCallingCode)
          .where('phoneNumber', isEqualTo: contact.phoneNumber)
          .limit(1)
          .get();

      if (duplicatePhone.docs.isNotEmpty) {
        final existing = duplicatePhone.docs.first.data();
        final existingName = existing['fName'] ?? 'Unknown';

        throw Exception('DUPLICATE_PHONE:${contact.phoneNumber}:$existingName');
      }

      final now = DateTime.now();

      final newContact = contact.copyWith(createdAt: now, updatedAt: now);

      final docRef = await _contactsRef.add(newContact.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE CONTACT
  // ---------------------------------------------------------------------------
  Future<void> updateContact(String id, ContactModel contact) async {
    final updated = contact.copyWith(updatedAt: DateTime.now());

    // Update contact in contacts collection
    await _contactsRef.doc(id).update(updated.toFirestore());

    // Also update the name in chats collection if chat exists
    try {
      final chatQuery = await _firestore
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .where(
            'phoneNumber',
            isEqualTo: '${contact.countryCallingCode}${contact.phoneNumber}',
          )
          .limit(1)
          .get();

      if (chatQuery.docs.isNotEmpty) {
        final chatDoc = chatQuery.docs.first;
        final updatedName = '${contact.fName} ${contact.lName}'.trim();

        await chatDoc.reference.update({
          'name': updatedName.isEmpty ? contact.phoneNumber : updatedName,
        });
      }
    } catch (e) {
      // Log error but don't fail the contact update
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE CONTACT WITH BACKUP
  // ---------------------------------------------------------------------------
  Future<void> deleteContact(String id) async {
    final doc = await _contactsRef.doc(id).get();
    if (!doc.exists) throw Exception("Contact not found");

    final data = doc.data()!;

    final deletedData = {
      ...data,
      'deletedAt': Timestamp.fromDate(DateTime.now()),
      'originalId': id,
    };

    await _deletedContactsRef.doc(id).set(deletedData);
    await _contactsRef.doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // TAG HANDLING
  // ---------------------------------------------------------------------------
  Future<String> addContactWithTagNames(
    ContactModel contact,
    List<String> tagNames,
  ) async {
    final updated = contact.copyWith(tags: tagNames);
    return await addContact(updated);
  }

  Future<void> updateContactWithTagNames(
    String id,
    ContactModel contact,
    List<String> tagNames,
  ) async {
    final updated = contact.copyWith(tags: tagNames);
    await updateContact(id, updated);
  }

  // Get contacts by tag name
  Stream<List<ContactModel>> getContactsByTagIdStream(String tagName) {
    return _contactsRef
        .where('tags', arrayContains: tagName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ContactModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get all tags
  Future<List<String>> getAllTags() async {
    final snap = await FirebaseFirestore.instance
        .collection("tags")
        .doc(clientID)
        .collection("data")
        .get();
    return snap.docs.map((e) => e["name"] as String).toList();
  }
}
