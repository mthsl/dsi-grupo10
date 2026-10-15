import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> toggleFavorite(String petId) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    DocumentReference userRef = _firestore.collection('users').doc(userId);
    DocumentSnapshot userDoc = await userRef.get();

    if (userDoc.exists) {
      List<dynamic> favorites = userDoc.data().toString().contains('favorites') 
          ? userDoc.get('favorites') 
          : [];

      if (favorites.contains(petId)) {
        await userRef.update({
          'favorites': FieldValue.arrayRemove([petId])
        });
      } else {
        await userRef.update({
          'favorites': FieldValue.arrayUnion([petId])
        });
      }
    } else {
      await userRef.set({'favorites': [petId]}, SetOptions(merge: true));
    }
  }

  Stream<bool> isFavorite(String petId) {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data()!.containsKey('favorites')) {
        List<dynamic> favorites = snapshot.get('favorites');
        return favorites.contains(petId);
      }
      return false;
    });
  }

// Busca os dados completos dos pets favoritados
  Stream<List<Map<String, dynamic>>> getFavoritePets() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore.collection('users').doc(userId).snapshots().asyncMap((userSnapshot) async {
      if (!userSnapshot.exists || !userSnapshot.data()!.containsKey('favorites')) return [];

      List<dynamic> favoriteIds = userSnapshot.get('favorites');
      if (favoriteIds.isEmpty) return [];

      List<Map<String, dynamic>> favoritePets = [];
      for (String id in favoriteIds) {
        DocumentSnapshot petDoc = await _firestore.collection('pets').doc(id).get();
        if (petDoc.exists) {
          // CORREÇÃO: Map<String, dynamic>.from() cria uma cópia editável do documento
          Map<String, dynamic> petData = Map<String, dynamic>.from(petDoc.data() as Map<String, dynamic>);
          petData['id'] = petDoc.id; 
          favoritePets.add(petData);
        }
      }
      return favoritePets;
    });
  }
}