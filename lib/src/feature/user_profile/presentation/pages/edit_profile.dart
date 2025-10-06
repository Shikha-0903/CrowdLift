import 'package:crowdlift/src/feature/user_profile/presentation/pages/my_profile.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crowdlift/src/core/widgets/custom_snack_bar.dart';
import 'package:crowdlift/src/core/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _role = TextEditingController();
  final TextEditingController _aim = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _capacityAbout = TextEditingController();
  final TextEditingController _interestExpect = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String _uid = "";
  String _imageUrl = "";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _uid = user.uid;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('crowd_user')
            .doc(_uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _name.text = userDoc['name'];
            _role.text = userDoc['role'];
            _email.text = userDoc['email'];
            _aim.text = userDoc['aim'];
            _description.text = userDoc['description'];
            _capacityAbout.text = userDoc['capacity_about'];
            _interestExpect.text = userDoc['interest_expect'];
            _imageUrl = userDoc['profile_image'];
          });
        }
      }
    } catch (e) {
      showCustomSnackBar(context, "Error loading user data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> removeProfileImage() async {
    if (_uid.isEmpty) {
      showCustomSnackBar(context, "Error: User not found.");
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Remove from Firebase Storage
      String filePath = 'profile_images/$_uid/profile_$_uid.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
      await storageRef.delete();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('crowd_user')
          .doc(_uid)
          .update({'profile_image': ""});

      // Update UI
      setState(() {
        _imageUrl = "";
      });

      showCustomSnackBar(context, "Profile image removed successfully!");
    } catch (e) {
      showCustomSnackBar(context, "Error removing image: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> pickAndUploadImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select Image Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text("Gallery"),
              onTap: () async {
                Navigator.pop(context); // Close dialog
                XFile? pickedFile = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 50, // Reduce image size
                );
                if (pickedFile != null) {
                  uploadImage(File(pickedFile.path));
                } else {
                  showCustomSnackBar(context, "No image selected.");
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Camera"),
              onTap: () async {
                final XFile? pickedFile = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 50, // Reduce image size
                );
                Navigator.pop(context);
                if (pickedFile != null) {
                  print("Image picked: ${pickedFile.path}");
                  try {
                    await uploadImage(File(pickedFile.path));
                  } catch (e) {
                    print("Error uploading image: $e");
                  }
                } else {
                  showCustomSnackBar(context, "No image captured.");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> uploadImage(File imageFile) async {
    if (_uid.isEmpty) {
      showCustomSnackBar(context, "Error: User not found.");
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Define file path in Firebase Storage
      String filePath = 'profile_images/$_uid/profile_$_uid.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(filePath);

      // Upload image
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Update Firestore with new profile image URL
      await FirebaseFirestore.instance
          .collection('crowd_user')
          .doc(_uid)
          .update({'profile_image': downloadUrl});

      setState(() {
        _imageUrl = downloadUrl;
      });

      showCustomSnackBar(context, "Profile image updated!");
    } catch (e) {
      showCustomSnackBar(context, "Error uploading image: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance.collection('crowd_user').doc(_uid).set({
        'aim': _aim.text,
        'description': _description.text,
        'capacity_about': _capacityAbout.text,
        'interest_expect': _interestExpect.text,
      }, SetOptions(merge: true));

      showCustomSnackBar(context, 'Update successful!');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MyProfile()));
    } catch (e) {
      showCustomSnackBar(context, 'Update failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFF070527),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => pickAndUploadImage(context),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageUrl.isNotEmpty
                            ? NetworkImage(_imageUrl)
                            : null,
                        child: _imageUrl.isEmpty
                            ? Icon(Icons.camera_alt, size: 40)
                            : null,
                      ),
                    ),
                    if (_imageUrl.isNotEmpty) // Show only if an image exists
                      TextButton(
                        onPressed: removeProfileImage,
                        child: Text(
                          "Remove Profile Image",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: 20),
                    _buildReadOnlyField("Name", _name),
                    _buildReadOnlyField("Email", _email),
                    _buildReadOnlyField("Role", _role),
                    _buildTextField("Your Aim", _aim),
                    _buildTextField("About Yourself", _description),
                    _buildTextField(
                      _role.text == "Investor"
                          ? "Investment Interest"
                          : "Business Expectation",
                      _interestExpect,
                    ),
                    _buildTextField(
                      _role.text == "Investor"
                          ? "Investment Capacity"
                          : "Business Details",
                      _capacityAbout,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: updateProfile,
                      child: Text("Update"),
                    ),
                  ],
                ),
              ),
            ),
      backgroundColor: Color(0xFF070527),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ReusableTextField(
          controller: controller, hintText: label, readOnly: true),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ReusableTextField(controller: controller, hintText: label),
    );
  }
}
