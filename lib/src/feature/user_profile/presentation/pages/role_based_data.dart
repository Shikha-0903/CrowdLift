import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crowdlift/src/feature/user_profile/presentation/pages/user_profile_screen.dart';
import 'package:crowdlift/src/core/utils/search_users.dart';

class FindData extends StatefulWidget {
  final String query;
  const FindData({super.key, required this.query});

  @override
  State<FindData> createState() => _FindDataState();
}

class _FindDataState extends State<FindData> {
  bool isSearching = false;
  List<Map<String, dynamic>> searchResults = [];
  final SearchUserService _searchService = SearchUserService();

  @override
  void initState() {
    super.initState();
    searchUsers(widget.query);
  }

  void searchUsers(String query) async {
    setState(() {
      isSearching = true;
    });

    try {
      debugPrint("Starting search for: '$query'");

      // Use the service to perform the search
      final results = await _searchService.searchUsers(query);

      debugPrint("Search complete. Found ${results.length} results");

      // Debug: Print the first few results if any
      if (results.isNotEmpty) {
        debugPrint("First result: ${results[0]}");
      }

      setState(() {
        searchResults = results;
        isSearching = false;
      });
    } catch (e) {
      debugPrint("Search error: $e");
      setState(() {
        isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("${widget.query}s",
            style: GoogleFonts.robotoSlab(color: Colors.white)),
        backgroundColor: const Color(0xFF070527),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFF070527)),
        child: Column(
          children: [
            Expanded(
              child: isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : searchResults.isEmpty
                      ? Center(
                          child: Text("No ${widget.query} found",
                              style: TextStyle(color: Colors.white)))
                      : ListView.builder(
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
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 10),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(15),
                                leading: CircleAvatar(
                                  backgroundColor: Color(0xFFA998F7),
                                  backgroundImage: user['profile_image'] != null
                                      ? NetworkImage(user['profile_image'])
                                      : null,
                                  child: user['profile_image'] == null
                                      ? Text(
                                          user['name'] != null &&
                                                  user['name'].isNotEmpty
                                              ? user['name'][0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 24,
                                              color: Colors.white),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  (user['name'] != null &&
                                          user['name'].isNotEmpty)
                                      ? (user['name'][0].toUpperCase() +
                                          user['name'].substring(1))
                                      : 'Unknown',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("📞 ${user['phone'] ?? 'N/A'}",
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                    Text(
                                        (user['role'] == "Investor")
                                            ? "🤵‍♂️ ${user['role'] ?? 'N/A'}"
                                            : "👨‍💼 ${user['role'] ?? 'N/A'}",
                                        style: const TextStyle(
                                            color: Colors.white70)),
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
                                              capacityAbout:
                                                  user['capacity_about'],
                                              interestExpect:
                                                  user['interest_expect'],
                                              description: user['description'],
                                              profileImage:
                                                  user['profile_image'],
                                              aim: user["aim"],
                                            )),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
