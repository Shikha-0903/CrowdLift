import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'a_model.dart';

class GeneratePdfScreen extends StatefulWidget {
  final Agreement agreement;
  final String chatId;

  GeneratePdfScreen({required this.agreement, required this.chatId});

  @override
  _GeneratePdfScreenState createState() => _GeneratePdfScreenState();
}

class _GeneratePdfScreenState extends State<GeneratePdfScreen> {
  bool _isLoading = false;

  /// Generates the agreement PDF and returns the file
  Future<File> _generatePdf() async {
    setState(() => _isLoading = true);

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Divider(),
            _buildTitle("Business Agreement"),
            pw.Divider(),
            _buildSection("Seeker", widget.agreement.seekerName),
            _buildSection("Investor", widget.agreement.investorName),
            _buildSection("Business Name", widget.agreement.businessName),
            _buildSection("Investment Amount", "Rs ${widget.agreement.investmentAmount}"),
            _buildSection("Duration", "${widget.agreement.duration} years"),
            _buildSection("Profit Sharing (Investor)", "${widget.agreement.profitSharingI}%"),
            _buildSection("Profit Sharing (Seeker)", "${widget.agreement.profitSharingS}%"),
            pw.SizedBox(height: 16),
            pw.Divider(),
            _buildSubtitle("Terms & Conditions"),
            pw.Divider(),
            pw.Wrap(
              children: [pw.Text(widget.agreement.terms, style: _textStyle(fontSize: 14))],
            ),
            pw.SizedBox(height: 200),
            pw.Divider(),
            _buildSection("Seeker Agreement Completed", widget.agreement.seekerCompleted ? 'Yes' : 'No'),
            _buildSection("Investor Agreement Completed", widget.agreement.investorCompleted ? 'Yes' : 'No'),
            _buildSection("Agreement Locked", widget.agreement.agreementLocked ? 'Yes' : 'No', isBold: true),
          ],
        ),
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File("${output.path}/agreement_${widget.chatId}.pdf");

    await file.writeAsBytes(await pdf.save());

    setState(() => _isLoading = false);
    return file;
  }

  /// Generates title text for the PDF
  pw.Widget _buildTitle(String text) {
    return pw.Text(text, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold));
  }

  /// Generates subtitle text for sections
  pw.Widget _buildSubtitle(String text) {
    return pw.Text(text, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold));
  }

  /// Generates section content in key-value format
  pw.Widget _buildSection(String key, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Text("$key: ", style: _textStyle(isBold: true)),
          pw.Text(value, style: _textStyle(isBold: isBold)),
        ]
      )
    );
  }

  /// Returns a consistent text style for the PDF
  pw.TextStyle _textStyle({bool isBold = false, double fontSize = 16}) {
    return pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFFA998F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text("Generate Agreement PDF", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Download or share the business agreement as a PDF document.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
            onPressed: () async {
              final file = await _generatePdf();
              await Printing.sharePdf(
                  bytes: await file.readAsBytes(), filename: "agreement_${widget.chatId}.pdf");
            },
            icon: const Icon(Icons.download),
            label: const Text("Download & Share PDF"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
