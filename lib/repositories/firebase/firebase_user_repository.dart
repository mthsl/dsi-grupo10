import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile_model.dart';
import '../interfaces/user_repository.dart';

/// Implementação concreta do IUserRepository usando Cloud Firestore.
class FirebaseUserRepository implements IUserRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  @override
  Future<UserProfileModel?> getUserProfile(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfileModel.fromMap(doc.data()!, id: doc.id);
  }

  @override
  Stream<UserProfileModel?> watchUserProfile(String uid) {
    return _collection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserProfileModel.fromMap(snapshot.data()!, id: snapshot.id);
    });
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    await _collection.doc(profile.id).set(
      {
        ...profile.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> toggleFavorite(String uid, String petId) async {
    final docRef = _collection.doc(uid);
    final snapshot = await docRef.get();

    List<dynamic> currentFavorites = [];
    if (snapshot.exists && snapshot.data() != null && snapshot.data()!.containsKey('favorites')) {
      currentFavorites = List.from(snapshot.get('favorites') ?? []);
    }

    if (currentFavorites.contains(petId)) {
      await docRef.update({
        'favorites': FieldValue.arrayRemove([petId])
      });
    } else {
      await docRef.set({
        'favorites': FieldValue.arrayUnion([petId])
      }, SetOptions(merge: true));
    }
  }

  @override
  Stream<List<String>> watchFavorites(String uid) {
    return _collection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null || !snapshot.data()!.containsKey('favorites')) {
        return const <String>[];
      }
      final dynamic raw = snapshot.get('favorites');
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return const <String>[];
    });
  }
}
