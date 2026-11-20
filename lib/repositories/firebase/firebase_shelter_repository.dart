import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shelter_model.dart';
import '../interfaces/shelter_repository.dart';

/// Implementação concreta do IShelterRepository usando Cloud Firestore.
class FirebaseShelterRepository implements IShelterRepository {
  final FirebaseFirestore _firestore;

  FirebaseShelterRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('shelters');

  @override
  Stream<List<ShelterModel>> watchShelters() {
    return _collection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ShelterModel.fromMap(doc.data(), id: doc.id))
        .toList());
  }

  @override
  Stream<List<ShelterModel>> watchSheltersByCreator(String creatorId) {
    if (creatorId.isEmpty) return Stream.value(const []);

    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ShelterModel.fromMap(doc.data(), id: doc.id))
          // fromMap já resolve criadorId a partir dos campos legados
          // (voluntarioId/userId), mantendo compatibilidade retroativa.
          .where((shelter) => shelter.criadorId == creatorId)
          .toList();
    });
  }

  @override
  Future<List<ShelterModel>> getShelters() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => ShelterModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<List<ShelterModel>> getSheltersByCreator(String creatorId) async {
    if (creatorId.isEmpty) return const [];
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => ShelterModel.fromMap(doc.data(), id: doc.id))
        .where((shelter) => shelter.criadorId == creatorId)
        .toList();
  }

  @override
  Future<ShelterModel?> getShelterById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ShelterModel.fromMap(doc.data()!, id: doc.id);
  }

  @override
  Future<void> addShelter(ShelterModel shelter) async {
    await _collection.add(shelter.toMap());
  }

  @override
  Future<void> updateShelter(ShelterModel shelter) async {
    await _collection.doc(shelter.id).update(shelter.toMap());
  }
}
