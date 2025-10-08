import 'package:crowdlift/src/feature/auth/presentation/pages/log_out.dart';
import 'package:crowdlift/src/feature/auth/presentation/widgets/about_app.dart';
import 'package:crowdlift/src/feature/transaction/presentation/pages/transaction_history.dart';
import 'package:crowdlift/src/feature/transaction/presentation/pages/payment_received.dart';
import 'package:crowdlift/src/feature/user_profile/presentation/pages/my_profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:crowdlift/src/feature/user_profile/presentation/pages/user_profile_screen.dart';
import '../../../user_profile/presentation/pages/role_based_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crowdlift/src/core/utils/profile_avatar.dart';
import 'package:crowdlift/src/core/utils/search_users.dart'; // Import the new service

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "User";
  String role = "";
  String greeting = "Hello";
  Timer? _greetingTimer;
  Timer? _hintTextTimer;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  List<String> hintTexts = [
    "Search Investor,,",
    "Search Seeker..",
    "Search phone no..",
    "Search email.."
  ];
  int currentHintIndex = 0;
  bool _mounted = false;
  String userId = "";

  // Create an instance of the SearchUserService
  final SearchUserService _searchService = SearchUserService();

  @override
  void initState() {
    super.initState();
    _mounted = true;
    fetchUserName();
    updateGreeting();
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      updateGreeting();
    });
    _hintTextTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_mounted) {
        setState(() {
          currentHintIndex = (currentHintIndex + 1) % hintTexts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _hintTextTimer?.cancel();
    searchController.dispose();
    _mounted = false;
    super.dispose();
  }

  Future<void> fetchUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('crowd_user')
          .doc(uid)
          .get();
      if (_mounted) {
        setState(() {
          userId = "$uid";
          userName = (userDoc['name'][0].toUpperCase() +
                  userDoc['name'].substring(1)) ??
              "User";
          role = userDoc['role'] ?? "None";
        });
      }
    } catch (e) {
      debugPrint("Error fetching user name: $e");
    }
  }

  void updateGreeting() {
    final hour = DateTime.now().hour;
    String newGreeting;
    if (hour < 12) {
      newGreeting = "Good Morning";
    } else if (hour < 17) {
      newGreeting = "Good Afternoon";
    } else {
      newGreeting = "Good Evening";
    }
    if (newGreeting != greeting) {
      if (_mounted) {
        setState(() {
          greeting = newGreeting;
        });
      }
    }
  }

  // Updated to use the SearchUserService
  void searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    // Use the service to search for users
    final results = await _searchService.searchUsers(query);

    if (_mounted) {
      setState(() {
        searchResults = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF070527),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        title: Text(
          "CrowdLift",
          style: GoogleFonts.geologica(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              onChanged: searchUsers,
              decoration: InputDecoration(
                hintText: hintTexts[currentHintIndex],
                hintStyle: GoogleFonts.arima(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Color(0xFF070527)),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF070527)),
                        onPressed: () {
                          setState(() {
                            searchController.clear();
                            searchResults.clear();
                            isSearching = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF070527),
                boxShadow: [
                  BoxShadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Color(0xFFA998F7))
                ],
              ),
              child: SizedBox(
                height: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProfileAvatar(radius: 30, userId: userId),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        "Welcome, $userName",
                        style: GoogleFonts.robotoSlab(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      (role == "Investor")
                          ? "Role: 🤵‍♂️$role"
                          : "Role: 👨‍💼$role",
                      style: GoogleFonts.robotoSlab(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF070527)),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
              hoverColor: Color(0xFFA998F7),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF070527)),
              title: const Text("Profile"),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => MyProfile())),
              hoverColor: Color(0xFFA998F7),
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xFF070527)),
              title: const Text("About us"),
              hoverColor: Color(0xFFA998F7),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AboutApp()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF070527)),
              title: const Text("Transaction History"),
              hoverColor: Color(0xFFA998F7),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TransactionHistoryPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Color(0xFF070527)),
              title: const Text("Payment Receipt"),
              hoverColor: Color(0xFFA998F7),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TransactionReceiptPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF070527)),
              title: const Text("Logout"),
              hoverColor: Color(0xFFA998F7),
              onTap: () {
                LogoutHelper.showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
      body: isSearching
          ? ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final user = searchResults[index];
                return Card(
                  color: Color(0xFF2A2D5E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFA998F7),
                      backgroundImage: user['profile_image'] != null
                          ? NetworkImage(user['profile_image'])
                          : null,
                      child: user['profileImage'] == null
                          ? Text(
                              user['name'] != null && user['name'].isNotEmpty
                                  ? user['name'][0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 24, color: Colors.white),
                            )
                          : null,
                    ),
                    title: Text(
                      (user['name'][0].toUpperCase() +
                              user['name'].substring(1)) ??
                          'Unknown',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📞 ${user['phone'] ?? 'N/A'}",
                            style: const TextStyle(color: Colors.white70)),
                        Text(
                            (user['role'] == "Investor")
                                ? "🤵‍♂️ ${user['role'] ?? 'N/A'}"
                                : "👨‍💼 ${user['role'] ?? 'N/A'}",
                            style: const TextStyle(color: Colors.white70)),
                        Text("📧 ${user['email'] ?? 'N/A'}",
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            userId: user['uid'],
                            name: user['name'],
                            email: user['email'],
                            phone: user['phone'],
                            role: user['role'],
                            capacityAbout: user['capacity_about'],
                            interestExpect: user['interest_expect'],
                            description: user['description'],
                            profileImage: user['profile_image'],
                            aim: user['aim'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            )
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          "$greeting !!",
                          style: GoogleFonts.titanOne(
                            color: Color(0xFF070527),
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          userName,
                          style: GoogleFonts.smoochSans(
                            color: Color(0xFF070527),
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                    Lottie.asset("assets/animations/s1.json", height: 400),
                    const SizedBox(height: 20),
                    Text("Looking for investor? or seeker?",
                        style: TextStyle(color: Colors.grey)),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Material(
                              color: Color(0xFFFF7755),
                              borderRadius: BorderRadius.circular(12),
                              elevation: 4,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FindData(query: "Investor"),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      "Investors",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Material(
                              color: Color(0xFF3dc1ae),
                              borderRadius: BorderRadius.circular(12),
                              elevation: 4,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FindData(query: "Seeker"),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      "Seekers",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      backgroundColor: Colors.white,
    );
  }
}
