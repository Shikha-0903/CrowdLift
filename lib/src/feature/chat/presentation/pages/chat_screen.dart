import 'dart:typed_data';
import 'package:crowdlift/src/feature/chat/presentation/pages/agreement_screen.dart';
import 'package:crowdlift/src/feature/chat/presentation/widgets/payment_gateway.dart';
import 'package:crowdlift/src/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/emoji_pick.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' as io;
import '../widgets/show_inapp.dart';
// Import the notification service
import 'package:crowdlift/src/core/utils/notification.dart'; // Update this to your actual path

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen(
      {super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Add notification service instance
  final NotificationService _notificationService = NotificationService();
  bool _isSeeker = false;
  bool _isTyping = false;
  String? _replyTo;
  Map<String, dynamic>? _replyMessage;

  @override
  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _messageController.addListener(_onTypingChanged);

    // Mark notifications as read when opening this chat
    _markNotificationsAsRead();
  }

  // Add this method to mark notifications as read when chat opens
  void _markNotificationsAsRead() {
    String chatId = getChatId(_auth.currentUser!.uid, widget.receiverId);
    _notificationService.markNotificationsAsRead(chatId);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    // No need to call _setUserOffline here as that would affect the entire app
    // Only reset the notification state for this specific chat
    super.dispose();
  }

  void _onTypingChanged() {
    final isCurrentlyTyping = _messageController.text.isNotEmpty;
    if (isCurrentlyTyping != _isTyping) {
      setState(() {
        _isTyping = isCurrentlyTyping;
      });
    }
  }

  Future<void> _checkUserRole() async {
    try {
      String userId = _auth.currentUser!.uid;
      DocumentSnapshot docSnapshot =
          await _firestore.collection('crowd_user').doc(userId).get();

      if (docSnapshot.exists) {
        setState(() {
          // Here the role check assumes that if the user's role is 'Investor', then _isSeeker is true.
          _isSeeker = (docSnapshot.get('role') ?? '') == 'Investor';
        });
      }
    } catch (e) {
      debugPrint("Error fetching role: $e");
      setState(() {
        _isSeeker = false;
      });
    }
  }

  String getChatId(String user1, String user2) {
    List<String> users = [user1, user2]..sort();
    return users.join("_");
  }

  void sendMessage() async {
    if (_messageController.text.isEmpty) {
      showCustomSnackBar(context, "Please write some message");
      return;
    }

    try {
      String senderId = _auth.currentUser!.uid;
      String receiverId = widget.receiverId;
      String message = _messageController.text.trim();
      String chatId = getChatId(senderId, receiverId);

      Map<String, dynamic> messageData = {
        'message': message,
        'senderId': senderId,
        'receiverId': receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'isDeleted': false,
      };

      // Add reply data if replying to a message
      if (_replyTo != null && _replyMessage != null) {
        messageData['replyTo'] = _replyTo;
        messageData['replyMessage'] = _replyMessage!['message'] ?? '';
        messageData['replySenderId'] = _replyMessage!['senderId'] ?? '';
      }

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Send notification using cached sender name if available
      // This avoids an unnecessary database read on every message
      if (_cachedSenderName == null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('crowd_user').doc(senderId).get();

        if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          _cachedSenderName = userData['name'] ?? "User";
        } else {
          _cachedSenderName = "User";
        }
      }

      // Send notification to the receiver
      await _notificationService.sendChatNotification(
        receiverId: receiverId,
        message: message,
        senderName: _cachedSenderName!,
        chatId: chatId,
      );
      if (!mounted) return;

      _messageController.clear();
      // Reset reply state
      setState(() {
        _replyTo = null;
        _replyMessage = null;
      });
    } catch (e) {
      showCustomSnackBar(context, "Error sending message: ${e.toString()}");
    }
  }

// Add this property to your _ChatScreenState class
  String? _cachedSenderName;
  void setReplyMessage(String messageId, Map<String, dynamic> message) {
    setState(() {
      _replyTo = messageId;
      _replyMessage = message;
    });
  }

  void cancelReply() {
    setState(() {
      _replyTo = null;
      _replyMessage = null;
    });
  }

  // Delete message functionality
  void deleteMessage(String messageId, Map<String, dynamic> message) async {
    try {
      String chatId = getChatId(_auth.currentUser!.uid, widget.receiverId);

      // If it's a file, decide whether to delete from storage
      if (message.containsKey('fileUrl') && message['fileUrl'] != null) {
        // Optional: Delete file from storage
        // Uncomment if you want to delete the actual file
        // try {
        //   Reference fileRef = _storage.refFromURL(message['fileUrl']);
        //   await fileRef.delete();
        // } catch (e) {
        //   print("Error deleting file: $e");
        // }
      }

      // For WhatsApp-like behavior, we mark the message as deleted instead of removing it
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true});
      if (!mounted) return;
      showCustomSnackBar(context, "Message deleted");
    } catch (e) {
      showCustomSnackBar(context, "Error deleting message: $e");
    }
  }

  // Updated File Picker & Upload Functionality
  Future<void> _pickAndUploadFile() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (!mounted) return;

      if (result == null) {
        showCustomSnackBar(context, "No file selected!");
        return;
      }

      PlatformFile file = result.files.first;

      // Handle file data differently based on platform
      Uint8List? fileBytes;
      if (file.bytes != null) {
        // Web platform already provides bytes
        fileBytes = file.bytes;
      } else if (file.path != null) {
        // For mobile/desktop, we need to read the file
        final filePath = file.path!;
        // Use dart:io File, not package:file/file.dart
        final ioFile = io.File(filePath);
        fileBytes = await ioFile.readAsBytes();
      }
      if (!mounted) return;

      if (fileBytes == null) {
        showCustomSnackBar(context, "Failed to read file bytes.");
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Upload to Firebase Storage
      String senderId = _auth.currentUser!.uid;
      String receiverId = widget.receiverId;
      String chatId = getChatId(senderId, receiverId);
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_files/$chatId/${file.name}');

      UploadTask uploadTask = storageRef.putData(fileBytes);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});

      // Get file URL
      String fileUrl = await snapshot.ref.getDownloadURL();
      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Save file message to Firestore
      Map<String, dynamic> fileMessageData = {
        'fileUrl': fileUrl,
        'fileName': file.name,
        'senderId': senderId,
        'receiverId': receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'isDeleted': false,
      };

      // Add reply data if replying to a message
      if (_replyTo != null && _replyMessage != null) {
        fileMessageData['replyTo'] = _replyTo;
        fileMessageData['replyMessage'] = _replyMessage!['message'] ?? '';
        fileMessageData['replySenderId'] = _replyMessage!['senderId'] ?? '';
      }

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(fileMessageData);

      // Get sender name for the notification
      DocumentSnapshot userDoc =
          await _firestore.collection('crowd_user').doc(senderId).get();
      String senderName = "User";
      if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        senderName = userData['name'] ?? "User";
      }

      // Send notification about the file
      await _notificationService.sendChatNotification(
        receiverId: receiverId,
        message: "📎 Sent a file: ${file.name}",
        senderName: senderName,
        chatId: chatId,
      );

      // Reset reply state
      setState(() {
        _replyTo = null;
        _replyMessage = null;
      });
      if (!mounted) return;

      showCustomSnackBar(context, "File sent successfully!");
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      showCustomSnackBar(context, "Error: ${e.toString()}");
      debugPrint("File Upload Error: $e");
    }
  }

  // Get username from userId
  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('crowd_user').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.get('name') ?? "User";
      }
      return "User";
    } catch (e) {
      debugPrint("Error fetching username: $e");
      return "User";
    }
  }

  @override
  Widget build(BuildContext context) {
    String chatId = getChatId(_auth.currentUser!.uid, widget.receiverId);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AgreementFormScreen(
                          chatId: chatId, isSeeker: _isSeeker)),
                );
              },
              icon: Icon(Icons.create)),
        ],
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(widget.receiverName, style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF070527),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070527), Color(0xFF16213E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Message List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text("No messages yet.",
                            style: TextStyle(color: Colors.white70)));
                  }

                  var messages = snapshot.data!.docs;
                  String? lastDate;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var msgSnapshot = messages[index];
                      final String messageId = msgSnapshot.id;
                      final Map<String, dynamic> msg =
                          msgSnapshot.data() as Map<String, dynamic>;
                      bool isMe = msg['senderId'] == _auth.currentUser!.uid;
                      bool isDeleted = msg['isDeleted'] == true;

                      Timestamp? timestamp = msg['timestamp'] as Timestamp?;
                      DateTime messageDate =
                          timestamp?.toDate() ?? DateTime.now();
                      String formattedDate =
                          DateFormat('dd MMM yyyy').format(messageDate);
                      String formattedTime =
                          DateFormat('hh:mm a').format(messageDate);

                      bool showDate = lastDate != formattedDate;
                      if (showDate) lastDate = formattedDate;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showDate)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          GestureDetector(
                            onLongPress: isDeleted
                                ? null
                                : () {
                                    if (isMe) {
                                      // Show dialog for delete options
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: Color(0xFF16213E),
                                          title: Text("Message Options",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: Icon(Icons.delete,
                                                    color: Colors.redAccent),
                                                title: Text("Delete",
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  deleteMessage(messageId, msg);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Show options for messages from others
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: Color(0xFF16213E),
                                          title: Text("Message Options",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: Icon(Icons.reply,
                                                    color: Colors.blueAccent),
                                                title: Text("Reply",
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  setReplyMessage(
                                                      messageId, msg);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    // Reply preview, if this message is a reply
                                    if (msg.containsKey('replyTo') &&
                                        !isDeleted)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 4),
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            FutureBuilder<String>(
                                                future: getUserName(
                                                    msg['replySenderId']),
                                                builder: (context, snapshot) {
                                                  return Text(
                                                    snapshot.data ?? "User",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  );
                                                }),
                                            SizedBox(height: 2),
                                            Text(
                                              msg['replyMessage'] ?? "",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Main message content
                                    if (isDeleted)
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black38,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.not_interested,
                                                color: Colors.white70,
                                                size: 16),
                                            SizedBox(width: 8),
                                            Text(
                                              "This message was deleted",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (msg.containsKey('fileUrl') &&
                                        msg['fileUrl'] != null)
                                      GestureDetector(
                                        onTap: () {
                                          showFileInApp(context, msg['fileUrl'],
                                              msg['fileName'] ?? "File");
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? Color(0xFF5E46C1)
                                                : Color(0xFFA998F7),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.attach_file,
                                                  color: Colors.white),
                                              SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  msg['fileName'] ?? "File",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Color(0xFF5E46C1)
                                              : Color(0xFFA998F7),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                            bottomLeft: isMe
                                                ? Radius.circular(16)
                                                : Radius.circular(0),
                                            bottomRight: isMe
                                                ? Radius.circular(0)
                                                : Radius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          msg['message'] ?? "",
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),

                                    // Time and status indicators
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formattedTime,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white54),
                                        ),
                                        if (isMe)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 4.0),
                                            child: Icon(
                                              Icons.done_all,
                                              size: 16,
                                              color: Colors.blue[200],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Reply preview bar
            if (_replyTo != null && _replyMessage != null)
              Container(
                color: Colors.black38,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.reply, color: Colors.white70),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _replyMessage!['senderId'] == _auth.currentUser!.uid
                                ? "You"
                                : widget.receiverName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _replyMessage!.containsKey('message')
                                ? _replyMessage!['message']
                                : _replyMessage!.containsKey('fileName')
                                    ? "File: ${_replyMessage!['fileName']}"
                                    : "Message",
                            style: TextStyle(color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white70),
                      onPressed: cancelReply,
                    ),
                  ],
                ),
              ),

            // Message Input Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 45, right: 70),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              border: InputBorder.none,
                            ),
                            maxLines: null, // Allows text to go to a new line
                            keyboardType: TextInputType
                                .multiline, // Enables multiline input
                          ),
                        ),
                        // Emoji Icon (Left Side)
                        Positioned(
                          left: 1,
                          child: IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined,
                                color: Color(0xFF5E46C1)),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => EmojiPickerWidget(
                                  onEmojiSelected: (String emoji) {
                                    _messageController.text += emoji;
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        // Attachment Icon (Right Side)
                        Positioned(
                          right: 40,
                          child: IconButton(
                            icon: const Icon(Icons.attach_file,
                                color: Color(0xFF5E46C1)),
                            onPressed: _pickAndUploadFile,
                          ),
                        ),
                        // Rupee Icon (Right Side; shown based on role)
                        Positioned(
                          right: 5,
                          child: IconButton(
                            icon: const Icon(Icons.currency_rupee,
                                color: Colors.green),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentGatewayScreen(
                                      receiverName: widget.receiverName,
                                      receiverId: widget.receiverId),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  // Send Button
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFF5E46C1),
                    child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: sendMessage),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
