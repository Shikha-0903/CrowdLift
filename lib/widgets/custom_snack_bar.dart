import 'package:flutter/material.dart';

void showCustomSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.white),
          SizedBox(width: 10),
          Expanded( // Prevents overflow
            child: Text(
              message,
              overflow: TextOverflow.ellipsis, // Handles long text gracefully
              maxLines: 2, // Limit lines to avoid excessive height
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xFF6750a4), // Default color
      duration: Duration(seconds: 1),
    ),
  );
}
