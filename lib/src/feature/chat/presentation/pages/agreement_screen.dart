import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crowdlift/src/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/a_model.dart';
import 'generate_pdf.dart';
import 'package:url_launcher/url_launcher.dart';

class AgreementFormScreen extends StatefulWidget {
  final String chatId;
  final bool isSeeker;

  AgreementFormScreen({required this.chatId, required this.isSeeker});

  @override
  _AgreementFormScreenState createState() => _AgreementFormScreenState();
}

class _AgreementFormScreenState extends State<AgreementFormScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController seekerNameController = TextEditingController();
  TextEditingController investorNameController = TextEditingController();
  TextEditingController businessNameController = TextEditingController();
  TextEditingController investmentAmountController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController profitSharingController1 = TextEditingController();
  TextEditingController profitSharingController2 = TextEditingController();
  TextEditingController termsController = TextEditingController();

  bool seekerCompleted = false;
  bool investorCompleted = false;
  bool agreementLocked = false;
  bool isLoading = true;

  Timestamp? seekerUpdatedAt;
  Timestamp? investorUpdatedAt;

  @override
  void initState() {
    super.initState();
    _fetchAgreementData();
  }

  Future<void> _fetchAgreementData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('agreements')
          .doc(widget.chatId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          seekerNameController.text = data['seekerName'] ?? '';
          investorNameController.text = data['investorName'] ?? '';
          businessNameController.text = data['businessName'] ?? '';
          investmentAmountController.text = data['investmentAmount'].toString();
          durationController.text = data['duration'] ?? '';
          profitSharingController1.text = data['profitSharingI'] ?? '';
          profitSharingController2.text = data['profitSharingS'] ?? '';
          termsController.text = data['terms'] ?? '';
          seekerCompleted = data['seekerCompleted'] ?? false;
          investorCompleted = data['investorCompleted'] ?? false;
          agreementLocked = data['agreementLocked'] ?? false;
          seekerUpdatedAt = data['seekerUpdatedAt'];
          investorUpdatedAt = data['investorUpdatedAt'];
        });
      }
    } catch (e) {
      print("Error fetching agreement: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveAgreementData(
      {bool isSeeker = false, bool isInvestor = false}) async {
    try {
      Map<String, dynamic> updateData = {
        'seekerName': seekerNameController.text,
        'investorName': investorNameController.text,
        'businessName': businessNameController.text,
        'investmentAmount':
            double.tryParse(investmentAmountController.text) ?? 0.0,
        'duration': durationController.text,
        'profitSharingI': profitSharingController1.text,
        'profitSharingS': profitSharingController2.text,
        'terms': termsController.text,
        'seekerCompleted': seekerCompleted,
        'investorCompleted': investorCompleted,
        'agreementLocked': seekerCompleted && investorCompleted,
      };

      if (widget.isSeeker) {
        updateData['seekerUpdatedAt'] = FieldValue.serverTimestamp();
      } else {
        updateData['investorUpdatedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('agreements')
          .doc(widget.chatId)
          .set(updateData, SetOptions(merge: true));
      showCustomSnackBar(context, "Agreement saved successfully!");
    } catch (e) {
      print("Error saving agreement: $e");
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Not updated yet";
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF070527),
      appBar: AppBar(
        title: Text(
          "Create Agreement",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF070527),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            buildTextField("Seeker Name", seekerNameController),
                            buildTextField(
                                "Investor Name", investorNameController),
                            buildTextField(
                                "Business Name", businessNameController),
                            buildTextField(
                                "Investment Amount", investmentAmountController,
                                keyboardType: TextInputType.number),
                            buildTextField(
                                "Duration (Years)", durationController,
                                keyboardType: TextInputType.number),
                            buildTextField("Profit Sharing (Investor %)",
                                profitSharingController1,
                                keyboardType: TextInputType.number),
                            buildTextField("Profit Sharing (Seeker %)",
                                profitSharingController2,
                                keyboardType: TextInputType.number),
                            buildTextField(
                                "Terms & Conditions", termsController,
                                maxLines: 4),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Divider(),
                    SizedBox(height: 10),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            buildSwitchTile(
                                "Seeker Agreement Completed", seekerCompleted,
                                (value) {
                              setState(() => seekerCompleted = value);
                              _saveAgreementData(isSeeker: true);
                            }, formatDate(seekerUpdatedAt)),
                            buildSwitchTile("Investor Agreement Completed",
                                investorCompleted, (value) {
                              setState(() => investorCompleted = value);
                              _saveAgreementData(isInvestor: true);
                            }, formatDate(investorUpdatedAt)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: agreementLocked
                              ? null
                              : () {
                                  if (int.parse(profitSharingController1.text) >
                                          100 ||
                                      int.parse(
                                              profitSharingController1.text) <=
                                          0 ||
                                      int.parse(profitSharingController2.text) >
                                          100 ||
                                      int.parse(
                                              profitSharingController2.text) <=
                                          0) {
                                    showCustomSnackBar(context,
                                        "profit sharing must be less than 100 and greater than 0");
                                    return;
                                  } else {
                                    _saveAgreementData();
                                  }
                                },
                          child: Text(
                            "update",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: agreementLocked
                                ? Colors.grey
                                : Theme.of(context).primaryColor,
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 24),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              if (int.parse(profitSharingController1.text) >
                                      100 ||
                                  int.parse(
                                          profitSharingController1.text) <=
                                      0 ||
                                  int.parse(profitSharingController2.text) >
                                      100 ||
                                  int.parse(profitSharingController2.text) <=
                                      0) {
                                showCustomSnackBar(context,
                                    "profit sharing must be less than 100 and greater than 0");
                                return;
                              } else {
                                //_saveAgreementData();
                                Agreement agreement = Agreement(
                                  id: widget.chatId,
                                  seekerName: seekerNameController.text,
                                  investorName: investorNameController.text,
                                  businessName: businessNameController.text,
                                  investmentAmount: double.parse(
                                      investmentAmountController.text),
                                  duration: durationController.text,
                                  profitSharingI: profitSharingController1.text,
                                  profitSharingS: profitSharingController2.text,
                                  terms: termsController.text,
                                  seekerCompleted: seekerCompleted,
                                  investorCompleted: investorCompleted,
                                  agreementLocked:
                                      seekerCompleted && investorCompleted,
                                );
                                showDialog(
                                    context: context,
                                    builder: (context) => GeneratePdfScreen(
                                        agreement: agreement,
                                        chatId: widget.chatId));
                              }
                            }
                          },
                          child: Text(
                            "Generate Agreement PDF",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "If both parties lock the agreement, no further changes can be made.",
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: "shikha992003@gmail.com",
                          queryParameters: {
                            'subject': 'Unlock\tForm',
                            'body':
                                'We\twanted\tto\tunlock\tform\n\nthis\tis\tour\tagreementId:\n${widget.chatId}\n\nMy\trole:${widget.isSeeker ? "Seeker" : "Investor"}'
                          },
                        );

                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        } else {
                          print("Could not launch email app");
                        }
                      },
                      child: Text("Contact admin for changes"),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration:
            InputDecoration(labelText: label, border: OutlineInputBorder()),
        validator: (value) => value!.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  Widget buildSwitchTile(
      String title, bool value, Function(bool) onChanged, String lastUpdated) {
    return Column(
      children: [
        SwitchListTile(
            title: Text(title),
            value: value,
            onChanged: agreementLocked ? null : onChanged),
        Text("Last Updated: $lastUpdated",
            style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
