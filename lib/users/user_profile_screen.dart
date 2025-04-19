import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crowdlift/chat/chat_screen.dart';
import 'package:crowdlift/utils/phone_call.dart';
import 'package:crowdlift/utils/profile_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends StatelessWidget {
  final String name;
  final String phone;
  final String role;
  final String userId;
  final String email;
  final String description;
  final String profile_image;
  final String interest_expect;
  final String capacity_about;
  final String aim;

  const UserProfileScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.role,
    required this.userId,
    required this.email,
    required this.description,
    required this.interest_expect,
    required this.capacity_about,
    required this.profile_image,
    required this.aim,
  });

  String get formattedName => name.isNotEmpty
      ? name[0].toUpperCase() + name.substring(1)
      : "User";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          formattedName,
          style: GoogleFonts.robotoSlab(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF070527),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: ProfileAvatar(radius: 60, userId: userId),
            ),
            const SizedBox(height: 10),
            Text(
              formattedName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              role,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.chat,
                    label: "Chat",
                    color: Color(0xFFaf61d0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverId: userId,
                            receiverName: formattedName,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.call,
                    label: "Call",
                    color: Color(0xFF3dc1ae),
                    onTap: () => PhoneUtils.makePhoneCall(phone),
                  ),
                  _buildActionButton(
                    icon: Icons.email,
                    label: "Email",
                    color: Color(0xFFFF7755),
                    onTap: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: email,
                        queryParameters: {
                          'subject': 'connect\tcrowdlift',
                          'body': 'Hi,\tI\twanted\tto\tconnect\twith\tyou.'
                        },
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoCard("📞 Phone", phone, isClickable: true, onTap: () {
              PhoneUtils.makePhoneCall(phone);
            }),
            _buildInfoCard("📧 Email", email, isClickable: true, onTap: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: email,
                queryParameters: {'subject': 'connect\tcrowdlift',
                  'body': 'Hi,\tI\twanted\tto\tconnect\twith\tyou.'
                },
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              }
            }),
            _buildInfoCard("🚀 Aim", aim),
            _buildInfoCard("📜 Description", description),
            _buildInfoCard(role == "Investor" ? "💰 Capacity" : "🏢 About Business", capacity_about),
            _buildInfoCard(role == "Investor" ? "📌 Interest" : "🎯 Expectation", interest_expect),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value,
      {bool isClickable = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: isClickable
              ? GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          )
              : Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
