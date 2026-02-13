import 'package:adminpanel/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tag_model.dart';

class TagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tags';

  CollectionReference<Map<String, dynamic>> get _tagsRef =>
      _firestore.collection(_collection).doc(clientID).collection("data");

  // STREAM — get all tags ordered by name
  Stream<List<TagModel>> getTagsStream() {
    return _tagsRef
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TagModel.fromFirestore(doc)).toList(),
        );
  }

  // Get tag by name
  Future<TagModel?> getTagByName(String name) async {
    try {
      final snap = await _tagsRef.where('name', isEqualTo: name).limit(1).get();

      if (snap.docs.isNotEmpty) {
        return TagModel.fromFirestore(snap.docs.first);
      }
      return null;
    } catch (e) {
      //print('Error fetching tag by name: $e');
      return null;
    }
  }

  // Create new tag ONLY IF it does not exist
  Future<String> addTag(TagModel tag) async {
    try {
      final existing = await getTagByName(tag.name);
      if (existing != null) {
        return existing.id; // return existing (avoid duplication)
      }

      final docRef = await _tagsRef.add(tag.toFirestore());
      return docRef.id;
    } catch (e) {
      //print('Error adding tag: $e');
      rethrow;
    }
  }

  // Create tag if missing, return TAG NAME (lowercase)
  Future<String> getOrCreateTagName(String tagName) async {
    try {
      final lower = tagName.trim().toLowerCase(); // 🔥 force lowercase

      final existing = await getTagByName(lower);
      if (existing != null) return existing.name; // always lowercase

      final now = DateTime.now();

      final newTag = TagModel(
        id: lower, // use lowercase ID
        name: lower, // store lowercase name
        createdAt: now,
        updatedAt: now,
      );

      await addTag(newTag);
      return lower;
    } catch (e) {
      //print('Error creating tag by name: $e');
      rethrow;
    }
  }

  // Bulk create tag names (all lowercase)
  Future<List<String>> getOrCreateTagNames(List<String> names) async {
    try {
      final List<String> result = [];

      for (final n in names) {
        final lower = n.trim().toLowerCase(); // 🔥 normalize here also
        final tagName = await getOrCreateTagName(lower);
        result.add(tagName); // already lowercase
      }

      return result;
    } catch (e) {
      //print('Error creating tag names list: $e');
      rethrow;
    }
  }

  // Update tag by ID
  Future<void> updateTag(String id, TagModel tag) async {
    try {
      await _tagsRef.doc(id).update(tag.toFirestore());
    } catch (e) {
      //print('Error updating tag: $e');
      rethrow;
    }
  }

  // Delete tag by ID
  Future<void> deleteTag(String id) async {
    try {
      await _tagsRef.doc(id).delete();
    } catch (e) {
      //print('Error deleting tag: $e');
      rethrow;
    }
  }
}
