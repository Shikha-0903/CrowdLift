import 'dart:io';
import 'package:crowdlift/transaction/generate_receipt.dart';
import 'package:crowdlift/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:crowdlift/widgets/custom_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';


class PaymentGatewayScreen extends StatefulWidget {
  final String receiverName;
  final String receiverId;

  const PaymentGatewayScreen({super.key,required this.receiverName,required this.receiverId});

  @override
  _PaymentGatewayScreenState createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  late Razorpay _razorpay;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  /// Initialize Razorpay and event listeners
  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  /// Open Razorpay checkout with user-entered amount
  void _openCheckout() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showCustomSnackBar(context, "User not logged in.");
      return;
    }

    try {
      // Fetch user details from Firestore
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('crowd_user').doc(user.uid).get();

      if (!userDoc.exists) {
        showCustomSnackBar(context, "User details not found.");
        return;
      }

      // Extract user data
      String email = userDoc['email'] ?? user.email ?? "";
      String contact = userDoc['phone'] ?? ""; // Assuming 'phone' is stored in Firestore

      String amountText = _amountController.text.trim();
      if (amountText.isEmpty || double.tryParse(amountText) == null) {
        showCustomSnackBar(context, "Please enter a valid amount.");
        return;
      }

      int amountInPaise = (double.parse(amountText) * 100).toInt();

      Map<String, dynamic> options = {
        'key': 'rzp_test_6FEsYyFh2ySzFU', // Replace with your API key
        'amount': amountInPaise,
        'name': 'Test Payment',
        'description': 'Payment for demo app',
        'prefill': {
          'contact': contact,
          'email': email,
        },
        'theme': {'color': '#070527'},
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint("⚠️ Error fetching user data: $e");
      showCustomSnackBar(context, "Error fetching user details.");
    }
  }

  /// Handle successful payment
  /// Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint("✅ Payment Successful! Payment ID: ${response.paymentId}");

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showCustomSnackBar(context, "User not logged in.");
      return;
    }

    try {
      // Fetch current user details
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('crowd_user').doc(user.uid).get();

      if (!userDoc.exists) {
        showCustomSnackBar(context, "User details not found.");
        return;
      }

      // Extract user data
      String senderName = userDoc['name'] ?? "Unknown User";  // Assuming name field exists
      String receiverName = widget.receiverName;  // Passed from the screen
      String transactionId = response.paymentId ?? "Unknown";
      String amount = _amountController.text.trim();
      String transactionDate = DateTime.now().toIso8601String();

      // Create a transaction object
      Map<String, dynamic> transactionData = {
        'transactionId': transactionId,
        'receiverName': receiverName,
        'amount': amount,
        'transactionDate': transactionDate,
        'senderName': senderName
      };

      // Store transaction in Firestore under 'transactions' collection
      await FirebaseFirestore.instance
          .collection('crowd_user')
          .doc(user.uid)
          .collection('transactions') // Sub-collection for transactions
          .add(transactionData);
      await FirebaseFirestore.instance
          .collection('crowd_user')
          .doc(widget.receiverId)
          .collection('receipt') // Sub-collection for transactions
          .add(transactionData);
      debugPrint("📌 Transaction saved successfully!");

      // Show success message
      showCustomSnackBar(context, "Payment Successful!");

      // Generate the receipt PDF
      final pdfPath = await _generateReceipt(transactionId, amount, receiverName, senderName, transactionDate);

      // Clear the text field
      _amountController.clear();

      // Pop the screen after a short delay
      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pop(context);

        // Show share dialog after popping
        Future.delayed(Duration(milliseconds: 300), () {
          _showShareDialog(pdfPath, transactionData);

        });
      });

    } catch (e) {
      debugPrint("⚠️ Error saving transaction: $e");
      showCustomSnackBar(context, "Failed to save transaction.");
    }
  }



  /// Handle payment failure
  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("❌ Payment Failed: Code ${response.code}, Message: ${response.message}");
    showCustomSnackBar(context, "Payment Failed: ${response.message}");
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("💳 External Wallet Selected: ${response.walletName}");
    showCustomSnackBar(context, "Using Wallet: ${response.walletName}");
  }

  /// Generate PDF receipt
  Future<String> _generateReceipt(String transactionId, String amount,String receiverName,String senderName,String transactionDate) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Transaction Receipt",
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(), // Adds a separator line
              pw.SizedBox(height: 10),
              _transactionDetail("Sender", senderName),
              _transactionDetail("Sent to", receiverName),
              _transactionDetail("Transaction ID", transactionId),
              _transactionDetail("Date", _formatDate(transactionDate)),
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Amount:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Rs $amount", textAlign: pw.TextAlign.right,style: pw.TextStyle(color: PdfColors.green,fontWeight: pw.FontWeight.bold)),
                ],
              ),


            ],
          ),
        ),
      ),
    );


    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/receipt.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }
  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute}";
    } catch (e) {
      return "Invalid Date";
    }
  }
  pw.Widget _transactionDetail(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "$label: ",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  /// Show share receipt dialog
  void _showShareDialog(String filePath, Map<String, dynamic> transactionData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6750a4), Color(0xFF9575cd)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              const Icon(Icons.download_sharp, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              const Text(
                'Receipt Generated',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        content: const Text("Your payment receipt has been generated. Would you like to share it?"),
        actions: [
          _dialogButton("Cancel", () => Navigator.pop(context)),
          _dialogButton("Share", () async {
            await _shareReceipt(filePath);
            Navigator.pop(context);
          }),
          _dialogButton("Download", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReceiptScreen(transactionData: transactionData),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Helper method for dialog buttons to avoid redundancy
  Widget _dialogButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }

  /// Share receipt with error handling
  Future<void> _shareReceipt(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: "Here is your payment receipt.");
    } catch (e) {
      debugPrint("Share error: $e");
      showCustomSnackBar(context, "Could not share the receipt");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Payment to ${widget.receiverName}',
        style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFF070527),),
      body: Center(
        child: Container(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset("assets/animations/pay.json",height: 350,repeat: true,animate: true,),
                  ReusableTextField(controller: _amountController, hintText: "Enter amount",prefixIcon: Icons.currency_rupee,),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _openCheckout,
                    child: const Text('Pay Now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF070527),
    );
  }
}
