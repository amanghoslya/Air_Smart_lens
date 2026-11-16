/// The boundary between the app and Vishal Optical's ERP.
///
/// The HTML prototype has no server: everything below is simulated by
/// [MockOrderingApi]. Replace it with an implementation that calls the real
/// backend. Keep secrets (API keys, signing keys, database passwords) on the
/// server: the app only ever holds the signed-in user's session token, which
/// should be stored with platform secure storage.
library;

import '../catalog_data.dart';
import '../models.dart';
import '../stock.dart';
import '../../data/content.dart';

/// What the app needs after sign-in.
class AppData {
  final CatalogData catalog;
  final AccountContent content;
  const AppData(this.catalog, this.content);
}

/// One order as sent to the ERP.
class OrderDraft {
  final List<CartLine> lines;
  final String remark;
  final String persona; // owner places; staff saves to shop cart; sub sends to distributor
  const OrderDraft({required this.lines, required this.remark, required this.persona});
}

class PlacedOrder {
  final String number;
  final DateTime changeableUntil; // one hour after placing (Q13)
  const PlacedOrder(this.number, this.changeableUntil);
}

abstract class OrderingApi {
  /// Catalogue, prices, Super Masters and the account's content.
  Future<AppData> load();

  /// Stock status source. Customers see status only (Q9), never quantities.
  StockService get stock;

  /// Login by mobile number and a one-time code. Vishal creates every account;
  /// there is no self sign-up.
  Future<void> requestOtp(String mobile);
  Future<bool> verifyOtp(String mobile, String code);

  Future<PlacedOrder> placeOrder(OrderDraft order);
  Future<void> cancelOrder(String number);

  /// The prototype's demo login, pre-filled on the login screen. A real
  /// implementation returns null so the fields start empty.
  String? get demoMobile;
  String? get demoCode;
}
