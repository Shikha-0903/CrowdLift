import 'package:crowdlift/src/feature/home/presentation/pages/home_screen.dart';
import 'package:crowdlift/src/feature/transaction/presentation/pages/payment_received.dart';
import 'package:crowdlift/src/feature/transaction/presentation/pages/transaction_history.dart';
import 'package:crowdlift/src/feature/user_profile/presentation/pages/my_profile.dart';
import 'package:go_router/go_router.dart';

class HomeRoutes {
  static const String homePage = "/home-page";
  static const String myProfile = "/my-profile";
  static const String transactionHistoryPage = "/transaction-history-page";
  static const String transactionReceiptPage = "/transaction-receipt-page";
  static List<GoRoute> routes = [
    GoRoute(path: homePage, builder: (_, __) => HomeScreen()),
    GoRoute(path: myProfile, builder: (_, __) => MyProfile()),
    GoRoute(
        path: transactionHistoryPage,
        builder: (_, __) => TransactionHistoryPage()),
    GoRoute(
        path: transactionReceiptPage,
        builder: (_, __) => TransactionReceiptPage()),
  ];
}
