import 'package:flutter/widgets.dart';

import '../../state/app_state.dart';
import '../shell.dart';
import 'browse_screens.dart';
import 'menu_screens.dart';
import 'order_screens.dart';
import 'parcel_screens.dart';
import 'range_screens.dart';
import 'rx_screens.dart';
import 'scan_screen.dart';
import 'start_screens.dart';
import 'stock_screens.dart';

typedef ScreenBuilder = ScreenView Function(BuildContext context, AppState s);

/// Every screen of the app, by the same names as the HTML prototype.
const Map<String, ScreenBuilder> screens = {
  'welcome': welcomeScreen,
  'login': loginScreen,
  'home': homeScreen,
  'shop': shopScreen,
  'lenstype': lensTypeScreen,
  'rx': rxScreen,
  'options': optionsScreen,
  'results': resultsScreen,
  'product': productScreen,
  'cart': cartScreen,
  'checkout': checkoutScreen,
  'placed': placedScreen,
  'orders': ordersScreen,
  'account': accountScreen,
  'brands': brandsScreen,
  'brand': brandScreen,
  'stocktype': stockTypeScreen,
  'stockpick': stockPickScreen,
  'stockrange': stockRangeScreen,
  'grid': gridScreen,
  'search': searchScreen,
  'wishlist': wishlistScreen,
  'rangetype': rangeTypeScreen,
  'rangelist': rangeListScreen,
  'rangeprods': rangeProdsScreen,
  'scan': scanScreen,
  // side menu
  'preorder': preorderScreen,
  'posters': postersScreen,
  'videos': videosScreen,
  'certs': certsScreen,
  'pricelist': priceListScreen,
  'ledger': ledgerScreen,
  'transactions': transactionsScreen,
  'invoices': invoicesScreen,
  'salesreport': salesReportScreen,
  'analysis': analysisScreen,
  'stafflogins': staffLoginsScreen,
  'weblogin': webLoginScreen,
  'language': languageScreen,
  'contact': contactScreen,
  'faq': faqScreen,
  'about': aboutScreen,
  'terms': termsScreen,
  // RX orders
  'rxhome': rxHomeScreen,
  'rxdetails': rxDetailsScreen,
};

ScreenView buildScreen(BuildContext context, AppState s) => (screens[s.screen] ?? homeScreen)(context, s);
