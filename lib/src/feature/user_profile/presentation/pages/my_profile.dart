import 'package:crowdlift/src/feature/user_profile/presentation/pages/edit_profile.dart';
import 'package:crowdlift/src/core/utils/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  String userName = "User";
  String role = "None";
  String email = "None";
  String description = "None";
  String aim = "None";
  String interestExpect = "None";
  String capacityAbout = "None";
  String phone = "XXXXXXXXXX";

  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Call the new function to fetch data
  }

  Future<void> _fetchUserData() async {
    try {
      // Get the current user's UID from FirebaseAuth
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('crowd_user')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              userName = data['name'];
              role = data['role'];
              email = data['email'];
              description = data['description'];
              aim = data['aim'];
              interestExpect = data['interest_expect'];
              capacityAbout = data['capacity_about'];
              phone = data['phone'];
            });
          }
        } else {
          debugPrint("User document does not exist");
        }
      } else {
        debugPrint("User is not authenticated");
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070527), Color(0xFF2A2D5E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Profile Avatar
                  ProfileAvatar(radius: 60, userId: "$uid"),
                  const SizedBox(height: 10),
                  Text(
                    userName[0].toUpperCase() + userName.substring(1),
                    style: GoogleFonts.robotoSlab(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  // Profile Details in Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.call, "Phone no", phone),
                          _buildInfoRow(Icons.badge, "Role", role),
                          _buildInfoRow(Icons.lightbulb_outline, "Aim", aim),
                          _buildInfoRow(
                              Icons.description, "Description", description),
                          _buildInfoRow(
                              Icons.business,
                              role == "Investor"
                                  ? "Capacity"
                                  : "About Business",
                              capacityAbout),
                          _buildInfoRow(
                              Icons.favorite,
                              role == "Investor"
                                  ? "Interested In"
                                  : "Expectations",
                              interestExpect),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Edit Profile Button
                  /*ElevatedButton.icon(
                    onPressed: () {

                    },
                    icon: Icon(Icons.edit, color: Colors.white),
                    label: Text("Edit Profile", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),*/
                  const SizedBox(height: 20),
                  // Info Text
                  Text(
                    "If your information is not visible, please edit your profile.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => EditProfile()));
        },
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withAlpha(100),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.deepPurple, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "$title :",
                  style: GoogleFonts.firaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Text(
              value,
              style: GoogleFonts.oxygen(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
