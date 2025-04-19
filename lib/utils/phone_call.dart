import 'package:url_launcher/url_launcher.dart';

class PhoneUtils {
  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri callUri = Uri.parse('tel:$phoneNumber');

    if (!await launchUrl(callUri)) {
      throw 'Could not launch $phoneNumber';
    }
  }
}
