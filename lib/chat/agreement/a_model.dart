class Agreement {
  String id;
  String seekerName;
  String investorName;
  String businessName;
  double investmentAmount;
  String terms;
  String duration;
  String profitSharingI;
  String profitSharingS;
  bool seekerCompleted;
  bool investorCompleted;
  bool agreementLocked;

  Agreement({
    required this.id,
    required this.seekerName,
    required this.investorName,
    required this.businessName,
    required this.investmentAmount,
    required this.terms,
    required this.duration,
    required this.profitSharingI,
    required this.profitSharingS,
    required this.seekerCompleted,
    required this.investorCompleted,
    required this.agreementLocked,
  });

  Map<String, dynamic> toJson() {
    return {
      'seekerName': seekerName,
      'investorName': investorName,
      'businessName': businessName,
      'investmentAmount': investmentAmount,
      'terms': terms,
      'duration': duration,
      'profitSharingI': profitSharingI,
      'profitSharingS': profitSharingS,
      'seekerCompleted': seekerCompleted,
      'investorCompleted': investorCompleted,
      'agreementLocked': agreementLocked,
    };
  }

  factory Agreement.fromJson(Map<String, dynamic> json, String id) {
    return Agreement(
      id: id,
      seekerName: json['seekerName'],
      investorName: json['investorName'],
      businessName: json['businessName'],
      investmentAmount: json['investmentAmount'],
      terms: json['terms'],
      duration: json['duration'],
      profitSharingI: json['profitSharingI'],
      profitSharingS: json['profitSharingS'],
      seekerCompleted: json['seekerCompleted'],
      investorCompleted: json['investorCompleted'],
      agreementLocked: json['agreementLocked'],
    );
  }
}
