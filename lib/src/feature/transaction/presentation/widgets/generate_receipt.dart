import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> transactionData;

  ReceiptScreen({required this.transactionData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        "Transaction Receipt",
        style: TextStyle(fontWeight: FontWeight.bold),
      )),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(),
            SizedBox(height: 10),
            _detail("Sender", transactionData['senderName']),
            _detail("Sent to", transactionData['receiverName']),
            _detail("Transaction ID", transactionData['transactionId']),
            _detail("Date", _formatDate(transactionData['transactionDate'])),
            SizedBox(height: 40),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Amount:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "Rs ${transactionData['amount']}",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _generatePDF(context),
        child: Icon(Icons.download),
      ),
    );
  }

  // Format Date Properly
  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.day}-${date.month}-${date.year} ${DateFormat('hh:mm a').format(date)}";
    } catch (e) {
      return "Invalid Date";
    }
  }

  // 🖨 Generate PDF Receipt
  Future<void> _generatePDF(BuildContext context) async {
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
                style:
                    pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(), // Adds a separator line
              pw.SizedBox(height: 10),
              _transactionDetail("Sender", transactionData['senderName']),
              _transactionDetail("Sent to", transactionData['receiverName']),
              _transactionDetail(
                  "Transaction ID", transactionData['transactionId']),
              _transactionDetail(
                  "Date", _formatDate(transactionData['transactionDate'])),
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Amount:",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Rs ${transactionData['amount']}",
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                          color: PdfColors.green,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final output = await getExternalStorageDirectory();
    final file =
        File("${output!.path}/receipt_${transactionData['transactionId']}.pdf");
    await file.writeAsBytes(await pdf.save());

    OpenFile.open(file.path);
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

  Widget _detail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
