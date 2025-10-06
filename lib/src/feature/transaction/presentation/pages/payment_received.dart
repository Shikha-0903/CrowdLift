import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/generate_receipt.dart';

class TransactionReceiptPage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF070527),
        title: Text(
          'Payment Received',
          style: GoogleFonts.robotoSlab(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? Center(child: Text("User not logged in"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('crowd_user')
                  .doc(user!.uid)
                  .collection('receipt')
                  .orderBy('transactionDate', descending: true) // Latest first
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text(
                    "No transactions found.",
                    style: TextStyle(color: Colors.white),
                  ));
                }

                var transactions = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    var transactionData =
                        transactions[index].data() as Map<String, dynamic>;
                    return TransactionTile(transactionData);
                  },
                );
              },
            ),
      backgroundColor: Color(0xFF070527),
    );
  }
}

// 🏷️ Display Each Transaction
class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const TransactionTile(this.data, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Icon(Icons.account_balance_wallet, color: Colors.redAccent),
        title: Row(
          children: [
            Text("Amount: "),
            Text(
              "₹${data['amount']}",
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            )
          ],
        ),
        subtitle: Text("Date: ${_formatDate(data['transactionDate'])}"),
        trailing: IconButton(
          icon: Icon(Icons.receipt_long, color: Colors.blue),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReceiptScreen(transactionData: data),
              ),
            );
          },
        ),
      ),
    );
  }

  // 📅 Format Date Properly
  String _formatDate(dynamic dateData) {
    try {
      DateTime date;
      if (dateData is Timestamp) {
        date = dateData.toDate();
      } else if (dateData is String) {
        date = DateTime.parse(dateData);
      } else {
        return "Invalid Date";
      }
      return DateFormat('dd-MM-yyyy hh:mm a').format(date);
    } catch (e) {
      return "Invalid Date";
    }
  }
}
