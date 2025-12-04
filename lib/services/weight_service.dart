import 'dart:async';
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
    print('DEBUG WeightService: getWeightEntries called, userId: $_userId');
    
    // Try cache first, then server
    try {
      print('DEBUG WeightService: Attempting to get from cache first...');
      final cacheSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weight_entries')
          .get(const GetOptions(source: Source.cache));
      
      print('DEBUG WeightService: Cache returned ${cacheSnapshot.docs.length} documents');
      if (cacheSnapshot.docs.isNotEmpty) {
        final entries = cacheSnapshot.docs.map((doc) {
          return WeightEntry.fromMap(doc.id, doc.data());
        }).toList();
        entries.sort((a, b) => b.date.compareTo(a.date));
        print('DEBUG WeightService: Returning ${entries.length} entries from cache');
        return entries;
      }
    } catch (e) {
      print('DEBUG WeightService: Cache query failed (this is OK if no cache): $e');
    }
    
    // If no cache or cache failed, try server without orderBy (faster, no index needed)
    // When reloading after add, always use server to get latest data
    print('DEBUG WeightService: Querying from server without orderBy...');
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weight_entries')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      
      print('DEBUG WeightService: Server query returned ${querySnapshot.docs.length} documents');
      final entries = querySnapshot.docs.map((doc) {
        print('DEBUG WeightService: Processing doc ${doc.id} with data: ${doc.data()}');
        return WeightEntry.fromMap(doc.id, doc.data());
      }).toList();
      
      // Sort manually by date descending
      entries.sort((a, b) => b.date.compareTo(a.date));
      print('DEBUG WeightService: Returning ${entries.length} entries (sorted manually)');
      return entries;
    } catch (e, stackTrace) {
      print('DEBUG WeightService: Server query failed: $e');
      print('DEBUG WeightService: Stack trace: $stackTrace');
      
      // Last resort: try serverAndCache with a longer timeout
      print('DEBUG WeightService: Trying serverAndCache as last resort...');
      try {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('weight_entries')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 30));
        
        print('DEBUG WeightService: serverAndCache returned ${querySnapshot.docs.length} documents');
        final entries = querySnapshot.docs.map((doc) {
          return WeightEntry.fromMap(doc.id, doc.data());
        }).toList();
        entries.sort((a, b) => b.date.compareTo(a.date));
        print('DEBUG WeightService: Returning ${entries.length} entries');
        return entries;
      } catch (e2) {
        print('DEBUG WeightService: All query attempts failed: $e2');
        throw Exception('Failed to load weight entries: $e2');
      }
    }
  }

  Future<void> addWeightEntry(double weight) async {
    try {
      print('DEBUG WeightService: addWeightEntry called, weight: $weight, userId: $_userId');
      final now = DateTime.now();
      print('DEBUG WeightService: Adding entry with date: $now');
      print('DEBUG WeightService: About to call Firestore add()...');
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weight_entries')
          .add({'weight': weight, 'date': Timestamp.fromDate(now)});
      print('DEBUG WeightService: Firestore add() completed, doc id: ${docRef.id}');
      print('DEBUG WeightService: Waiting for Firestore to propagate...');
      // Wait a bit for Firestore to propagate the write
      await Future.delayed(const Duration(milliseconds: 500));
      print('DEBUG WeightService: Entry added successfully with id: ${docRef.id}');
    } catch (e, stackTrace) {
      print('DEBUG WeightService: Error in addWeightEntry: $e');
      print('DEBUG WeightService: Stack trace: $stackTrace');
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

  Future<void> updateWeightEntry(String entryId, double weight, DateTime date) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weight_entries')
          .doc(entryId)
          .update({
        'weight': weight,
        'date': Timestamp.fromDate(date),
      });
    } catch (e) {
      throw Exception('Failed to update weight entry: $e');
    }
  }
}
