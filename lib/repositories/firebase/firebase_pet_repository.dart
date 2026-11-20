import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pet_model.dart';
import '../interfaces/pet_repository.dart';

/// Implementação concreta do IPetRepository usando Cloud Firestore.
///
/// Padrões aplicados:
/// - GoF Adapter: Converte DocumentSnapshot do Firebase em PetModel de domínio.
/// - SOLID LSP: Substitui perfeitamente IPetRepository.
class FirebasePetRepository implements IPetRepository {
  final FirebaseFirestore _firestore;

  FirebasePetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('pets');

  @override
  Stream<List<PetModel>> watchAvailablePets() {
    return _collection
        .where('status', isEqualTo: 'Disponível')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  @override
  Future<List<PetModel>> getAvailablePets() async {
    final snapshot = await _collection.where('status', isEqualTo: 'Disponível').get();
    return snapshot.docs
        .map((doc) => PetModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<PetModel?> getPetById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return PetModel.fromMap(doc.data()!, id: doc.id);
  }

  @override
  Future<void> addPet(PetModel pet) async {
    await _collection.add(pet.toMap());
  }

  @override
  Future<void> updatePet(PetModel pet) async {
    await _collection.doc(pet.id).update(pet.toMap());
  }

  @override
  Future<void> deletePet(String id) async {
    await _collection.doc(id).delete();
  }
}
