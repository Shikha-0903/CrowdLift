import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileAvatar extends StatefulWidget {
  final double radius;
  final String userId;

  const ProfileAvatar({super.key, this.radius = 50, required this.userId});

  @override
  ProfileAvatarState createState() => ProfileAvatarState();
}

class ProfileAvatarState extends State<ProfileAvatar> {
  String imageUrl = '';
  bool isLoading = true;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    // Short delay to avoid race conditions during widget initialization
    Future.delayed(Duration(milliseconds: 100), listenForProfileChanges);
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If userId changes, cancel old subscription and create a new one
    if (oldWidget.userId != widget.userId) {
      _profileSubscription?.cancel();
      listenForProfileChanges();
    }
  }

  void listenForProfileChanges() {
    // Validate userId before setting up the stream
    if (widget.userId.isEmpty) {
      setState(() {
        isLoading = false;
        imageUrl = '';
      });
      return;
    }

    // Cancel any existing subscription first to prevent duplicates
    _profileSubscription?.cancel();

    _profileSubscription = FirebaseFirestore.instance
        .collection('crowd_user')
        .doc(widget.userId)
        .snapshots()
        .listen((userDoc) {
      // Use Future.microtask to defer the setState call
      Future.microtask(() {
        if (!mounted) return;

        if (mounted) {
          setState(() {
            imageUrl = (userDoc.exists && userDoc.data() != null)
                ? userDoc.data()!['profile_image'] ?? ''
                : '';
            isLoading = false;
          });
        }
      });
    }, onError: (error) {
      Future.microtask(() {
        if (!mounted) return;

        debugPrint("⚠️ Error fetching profile image: $error");
        if (mounted) {
          setState(() {
            imageUrl = '';
            isLoading = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    // Make sure to cancel the subscription to prevent memory leaks
    _profileSubscription?.cancel();
    super.dispose();
  }

  void showFullImage(BuildContext context) {
    if (imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: false,
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    errorWidget: (context, url, error) =>
                        Image.asset('assets/images/img.png'),
                  )
                : Image.asset('assets/images/img.png'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? CircleAvatar(
            radius: widget.radius,
            child: CircularProgressIndicator(),
          )
        : GestureDetector(
            onTap: () => showFullImage(context),
            child: CircleAvatar(
              radius: widget.radius,
              backgroundImage: imageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(imageUrl) as ImageProvider
                  : const AssetImage('assets/images/img.png'),
              onBackgroundImageError: (_, __) {
                if (mounted) {
                  setState(() {
                    imageUrl = '';
                  });
                }
              },
            ),
          );
  }
}
