import 'package:crowdlift/src/core/widgets/custom_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

void showFileInApp(BuildContext context, String fileUrl, String fileName) {
  // Get file extension
  String fileExtension = fileName.split('.').last.toLowerCase();

  // Determine file type
  bool isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension);
  bool isPdf = fileExtension == 'pdf';
  bool isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(fileExtension);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF070527),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    // Download button
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.white),
                      onPressed: () async {
                        if (await canLaunch(fileUrl)) {
                          await launch(fileUrl);
                        } else {
                          showCustomSnackBar(
                              context, "Could not download file");
                        }
                      },
                    ),
                    // Close button
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // File content
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: isImage
                  // Image viewer
                  ? Center(
                      child: InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4,
                        child: Image.network(
                          fileUrl,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error,
                                      color: Colors.red, size: 50),
                                  SizedBox(height: 16),
                                  Text(
                                    "Failed to load image",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  // For PDF and other files, show a preview card
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPdf
                                ? Icons.picture_as_pdf
                                : isVideo
                                    ? Icons.video_file
                                    : Icons.insert_drive_file,
                            color: Colors.white,
                            size: 80,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "This file type cannot be previewed in-app",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: Icon(Icons.open_in_new),
                            label: Text("Open in External App"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Color(0xFF5E46C1),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              if (await canLaunch(fileUrl)) {
                                await launch(fileUrl);
                              } else {
                                showCustomSnackBar(
                                    context, "Could not open file");
                              }
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
