import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String uid;
  final String? firstName;
  final String? lastName;

  UserData({
    required this.uid,
    this.firstName,
    this.lastName,
  });

  // Factory method to create a UserData object from Firestore document
  factory UserData.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return UserData(
      uid: doc.id, // Use document ID as UID
      firstName: data?['firstName'] as String?,
      lastName: data?['lastName'] as String?,
    );
  }
}
