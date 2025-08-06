import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WeightEntry {
  final String id;
  final double weight;
  final DateTime date;

  WeightEntry({required this.id, required this.weight, required this.date});

  Map<String, dynamic> toMap() {
    return {'weight': weight, 'date': Timestamp.fromDate(date)};
  }

  factory WeightEntry.fromMap(String id, Map<String, dynamic> map) {
    return WeightEntry(
      id: id,
      weight: (map['weight'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}

class WeightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<List<WeightEntry>> getWeightEntries() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('weight_entries')
              .orderBy('date', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        return WeightEntry.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to load weight entries: $e');
    }
  }

  Future<void> addWeightEntry(double weight) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weight_entries')
          .add({'weight': weight, 'date': Timestamp.fromDate(DateTime.now())});
    } catch (e) {
      throw Exception('Failed to add weight entry: $e');
    }
  }

  Future<void> deleteWeightEntry(String entryId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weight_entries')
          .doc(entryId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete weight entry: $e');
    }
  }
}
