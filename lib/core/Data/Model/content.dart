/// Typed account and marketing content shown on the menu screens.
/// The mock API fills these with the prototype's simulated data; the real API
/// returns the shop's own ledger, invoices, sales and so on.
library;

class LedgerEntry {
  final String date;
  final String text;
  final bool isInvoice;
  final int debit; // bills
  final int credit; // payments and credit notes
  const LedgerEntry(this.date, this.text, this.isInvoice, this.debit, this.credit);
}

class MonthSales {
  final String month;
  final int pairs;
  final int value;
  const MonthSales(this.month, this.pairs, this.value);
}

class VideoItem {
  final String title;
  final String duration;
  final String image; // brand image key
  const VideoItem(this.title, this.duration, this.image);
}

class Faq {
  final String q;
  final String a;
  const Faq(this.q, this.a);
}

class Certificate {
  final String title;
  final String sub;
  const Certificate(this.title, this.sub);
}

class StaffLogin {
  final String name;
  final String mobile;
  final List<bool> switches; // show prices, show availability, add to cart, place order
  StaffLogin(this.name, this.mobile, this.switches);
}

class RxLabOrder {
  final String id;
  final String desc;
  final String status;
  final String kind; // pill colour: good | warn | bad | n
  final int stage; // index into rxStages
  const RxLabOrder(this.id, this.desc, this.status, this.kind, this.stage);
}

/// A row on the Orders tab (history from the ERP).
class OrderRow {
  final String id;
  final String date;
  final String status;
  final String kind;
  final int pairs;
  final int? value;
  final String? courier;
  final int? repeatIndex; // index into pastOrders for "Order again"
  const OrderRow(this.id, this.date, this.status, this.kind, this.pairs, this.value, {this.courier, this.repeatIndex});
}

class SalesShare {
  final String label;
  final int percent;
  const SalesShare(this.label, this.percent);
}

class AccountContent {
  final List<LedgerEntry> ledger;
  final int openingBalance;
  final List<MonthSales> months;
  final List<VideoItem> videos;
  final List<Faq> faqs;
  final List<Certificate> certificates;
  final List<StaffLogin> staffLogins;
  final List<RxLabOrder> rxLabOrders;
  final List<String> rxStages;
  final List<OrderRow> orderHistory;
  final List<SalesShare> byBrand;
  final List<SalesShare> byLensType;
  final List<(String, int)> topPowers;
  final List<(String, String)> terms;
  final String webAddress;
  final String nextOrderNumber;
  const AccountContent({
    required this.ledger,
    required this.openingBalance,
    required this.months,
    required this.videos,
    required this.faqs,
    required this.certificates,
    required this.staffLogins,
    required this.rxLabOrders,
    required this.rxStages,
    required this.orderHistory,
    required this.byBrand,
    required this.byLensType,
    required this.topPowers,
    required this.terms,
    required this.webAddress,
    required this.nextOrderNumber,
  });
}
