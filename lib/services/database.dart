import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Emon/models/user_data.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to update user data in Firestore
  Future<void> updateUserData(String uid, Map<String, dynamic> userData) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(uid);

      // Wrap userData in a 'user_data' field
      await userRef.set({'user_data': userData});

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

  // Method to fetch appliance data for a specific user
  Future<List<Map<String, dynamic>>> getApplianceData(String uid) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('registered_appliances')
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id; // Add the document ID to the appliance data
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching appliance data: $e');
      return []; // Return an empty list in case of an error
    }
  }
}
