import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String uid;
  final String? firstName;
  final String? lastName;
  final String? email; // Add email field
  final String? password; // Add password field (remember to hash passwords!)

  UserData({
    required this.uid,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
  });

  // Factory method to create a UserData object from Firestore document
  factory UserData.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()?['user_data']; // Access data under 'user_data'
    return UserData(
      uid: doc.id,
      firstName: data?['firstName'] as String?,
      lastName: data?['lastName'] as String?,
      email: data?['email'] as String?,
      password: data?['password'] as String?,
    );
  }
}
