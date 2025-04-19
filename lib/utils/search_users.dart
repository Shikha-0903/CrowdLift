import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchUserService {
  static final SearchUserService _instance = SearchUserService._internal();

  factory SearchUserService() {
    return _instance;
  }

  SearchUserService._internal();

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    List<Map<String, dynamic>> results = [];

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('crowd_user')
          .where('uid', isNotEqualTo: currentUid) // Exclude current user
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Convert to lower case safely
        String name = (data['name'] ?? "").toString().toLowerCase();
        String role = (data['role'] ?? "").toString().toLowerCase();
        String email = (data['email'] ?? "").toString().toLowerCase();
        String phone = (data['phone'] ?? "").toString(); // Avoid null errors

        // Match any field with query
        if (name.contains(query.toLowerCase()) ||
            phone.contains(query) ||
            role.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase())) {
          results.add(data);
        }
      }

      print("Search query: $query");
      print("Results count: ${results.length}");

      return results;
    } catch (e) {
      print("Search error: $e");
      return [];
    }
  }
}
