import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF070527),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          "About CrowdLift",
          style: GoogleFonts.geologica(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF070527), // Dark theme for a modern look
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.groups, size: 80, color: Color(0xFFB5A3FF)),
              const SizedBox(height: 10),
              Text(
                "🚀 CrowdLift: Connecting Entrepreneurs & Investors",
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Highlight Section
              _buildHighlightCard(),

              const SizedBox(height: 20),

              // Animated Introduction
              _buildAnimatedIntro(),

              const SizedBox(height: 24),

              // Features Section
              _buildFeatureSection(),

              const SizedBox(height: 20),

              // Why Join Section
              _buildWhyJoinCard(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E8FFA), Color(0xFFD4E2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.blue.shade300, blurRadius: 8, spreadRadius: 2)
        ],
      ),
      child: Text(
        "💡 Have a great business idea but need Investment?\n\n"
        "💰 Looking for the next big investment opportunity?\n\n"
        "👥 Want to connect with like-minded professionals?",
        textAlign: TextAlign.center,
        style: GoogleFonts.openSans(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  Widget _buildAnimatedIntro() {
    return Card(
      color: const Color(0xFF2A9D8F),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              "CrowdLift is where dreams meet opportunities. Whether you're a startup founder or an investor looking for the next breakthrough, we help you make meaningful connections.",
              textAlign: TextAlign.center,
              textStyle:
                  GoogleFonts.openSans(fontSize: 16, color: Colors.white),
              speed: const Duration(milliseconds: 50),
            ),
          ],
          totalRepeatCount: 1,
          pause: const Duration(milliseconds: 500),
          displayFullTextOnTap: true,
          stopPauseOnTap: true,
        ),
      ),
    );
  }

  Widget _buildFeatureSection() {
    return Column(
      children: [
        _buildFeatureTile(Icons.business, "Explore Business Profiles",
            "Discover innovative startups & growing businesses."),
        _buildFeatureTile(Icons.handshake, "Find Investors & Partners",
            "Connect with investors & mentors who believe in your vision."),
        _buildFeatureTile(Icons.trending_up, "Investment Opportunities",
            "Support promising ventures and be part of their success."),
        _buildFeatureTile(Icons.security, "Safe & Transparent",
            "We ensure secure transactions & verified profiles."),
      ],
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white.withAlpha(150),
          radius: 25,
          child: Icon(icon, size: 28, color: Colors.white),
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.openSans(fontSize: 14, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildWhyJoinCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.greenAccent, Colors.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.green.shade300, blurRadius: 8, spreadRadius: 2)
        ],
      ),
      child: Column(
        children: [
          Text(
            "🔥 Why Join CrowdLift?",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          _buildBulletPoint("✔ Verified Business Profiles"),
          _buildBulletPoint("✔ Global Investor Network"),
          _buildBulletPoint("✔ Hassle-Free Fundraising"),
          _buildBulletPoint("✔ Exclusive Startup Insights"),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.openSans(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
