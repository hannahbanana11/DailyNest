import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addNote({
    required String title,
    required String note,
    DateTime? selectedDate,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Please log in first");
    }

    DateTime noteDate = selectedDate ?? DateTime.now();
    DateTime now = DateTime.now();

    String currentTime = _formatTime(now);

    DateTime timestampDate = DateTime(
      noteDate.year,
      noteDate.month,
      noteDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    await _firestore.collection('users').doc(user.uid).collection('notes').add({
      'title': title,
      'note': note,
      'time': currentTime,
      'timestamp': Timestamp.fromDate(timestampDate),
      'dateOnly':
          '${noteDate.year}-${noteDate.month.toString().padLeft(2, '0')}-${noteDate.day.toString().padLeft(2, '0')}',
    });
  }

  Stream<QuerySnapshot> getNotesStreamForDate(DateTime selectedDate) {
    final user = _auth.currentUser;

    if (user == null) {
      // Return an empty stream instead of throwing an exception
      return const Stream.empty();
    }

    String dateString =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .where('dateOnly', isEqualTo: dateString)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getNotesStream() {
    final user = _auth.currentUser;

    if (user == null) {
      // Return an empty stream instead of throwing an exception
      return const Stream.empty();
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> updateNote({
    required String docID,
    required String newNote,
    required String newTitle,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Please log in first");
    }

    DateTime now = DateTime.now();
    String currentTime = _formatTime(now);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(docID)
        .update({
          'title': newTitle,
          'note': newNote,
          'time': currentTime,
        });
  }

  Future<void> deleteNote(String docID) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Please log in first");
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(docID)
        .delete();
  }

  String _formatTime(DateTime dateTime) {
    String day = dateTime.day.toString().padLeft(2, '0');
    String month = dateTime.month.toString().padLeft(2, '0');
    String year = dateTime.year.toString();

    return "$day/$month/$year";
  }

  // Savings/Passbook methods
  Future<void> addSavings({
    required String date,
    required List<Map<String, dynamic>> transactions,
    required double totalBalance,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Please log in first");
    }

    DateTime now = DateTime.now();

    await _firestore.collection('users').doc(user.uid).collection('savings').add({
      'date': date,
      'transactions': transactions,
      'totalBalance': totalBalance,
      'timestamp': Timestamp.fromDate(now),
    });
  }

  Stream<QuerySnapshot> getSavingsStream() {
    final user = _auth.currentUser;

    if (user == null) {
      // Return an empty stream instead of throwing an exception
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> updateSavings({
    required String docID,
    required String date,
    required List<Map<String, dynamic>> transactions,
    required double totalBalance,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Please log in first");
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .doc(docID)
        .update({
          'date': date,
          'transactions': transactions,
          'totalBalance': totalBalance,
        });
  }

  Future<void> deleteSavings(String docID) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Please log in first");
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .doc(docID)
        .delete();
  }
}