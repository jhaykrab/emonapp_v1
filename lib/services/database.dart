import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Emon/models/user_data.dart'; // Import UserData model

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to update user data in Firestore
  Future<void> updateUserData(
      String uid, String firstName, String lastName) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(uid);

      await userRef.set({
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
      });

      print('User data updated successfully!');
    } catch (e) {
      print('Error updating user data: $e');
      throw Exception('Failed to update user data');
    }
  }

  // Method to fetch user data by UID
  Future<UserData?> getUserData(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('users').doc(uid).get();

      if (snapshot.exists) {
        return UserData.fromFirestore(snapshot); // Convert snapshot to UserData
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null; // Return null if no data or error
  }
}
