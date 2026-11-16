/// Simulated backend: the data and behaviour of the HTML prototype.
library;

import 'package:flutter/services.dart' show rootBundle;

import '../core/catalog_data.dart';
import '../core/stock.dart';
import 'content.dart';
import 'ordering_api.dart';

class MockOrderingApi implements OrderingApi {
  @override
  final StockService stock = StockService();

  @override
  Future<AppData> load() async {
    final catalog = CatalogData.parse(
      catalogJson: await rootBundle.loadString('assets/data/catalog.json'),
      superMastersJson: await rootBundle.loadString('assets/data/super_masters.json'),
      accountJson: await rootBundle.loadString('assets/data/simulated_account.json'),
    );
    return AppData(catalog, mockContent());
  }

  @override
  Future<void> requestOtp(String mobile) async {}

  @override
  Future<bool> verifyOtp(String mobile, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return true;
  }

  @override
  Future<PlacedOrder> placeOrder(OrderDraft order) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    return PlacedOrder('SO-1051', DateTime.now().add(const Duration(hours: 1)));
  }

  @override
  Future<void> cancelOrder(String number) async {}

  @override
  String? get demoMobile => null;
  @override
  String? get demoCode => null;
}

AccountContent mockContent() => AccountContent(
  ledger: const [
    LedgerEntry('1 Sep', 'Opening balance', false, 0, 0),
    LedgerEntry('5 Sep', 'Payment received · NEFT', false, 0, 120000),
    LedgerEntry('18 Sep', 'Invoice INV-2311 · SO-1042', true, 247968, 0),
    LedgerEntry('21 Sep', 'Invoice INV-2318 · SO-1046', true, 18960, 0),
    LedgerEntry('23 Sep', 'Invoice INV-2324 · SO-1048', true, 41280, 0),
    LedgerEntry('25 Sep', 'Credit note CN-118 · 6 pairs returned', false, 0, 7840),
    LedgerEntry('3 Oct', 'Payment received · cheque', false, 0, 150000),
    LedgerEntry('15 Oct', 'Payment received · UPI', false, 0, 50000),
  ],
  openingBalance: 145312,
  months: const [
    MonthSales('Apr', 412, 286400),
    MonthSales('May', 388, 271900),
    MonthSales('Jun', 455, 322700),
    MonthSales('Jul', 502, 351200),
    MonthSales('Aug', 476, 338900),
    MonthSales('Sep', 540, 384600),
    MonthSales('Oct', 214, 158300),
  ],
  videos: const [
    VideoItem('Fitting a progressive lens', '2:10', 'vishal1_face'),
    VideoItem('Bifocal or progressive: explaining it to your customer', '3:05', 'kopperx1_face'),
    VideoItem('Caring for coated lenses', '1:40', 'max1_face'),
    VideoItem('How to order on the Vishal app', '2:30', 'veriwide2_face'),
  ],
  faqs: const [
    Faq(
      'How do I know if a power is in stock?',
      'Every lens shows one of four labels: In stock, Sold out, Not kept in stock or Coming soon. Quantities are not shown.',
    ),
    Faq(
      'What if you have fewer pairs than I ordered?',
      'The cart tells you before you order, for example "You ordered 100 pairs; 20 are available". You can order the 20, change the quantity or remove the line. If you order anyway, what is available is sent and the rest is cancelled.',
    ),
    Faq('Can I change or cancel an order?', 'Yes, for one hour after placing it, from the order confirmation or from Orders.'),
    Faq(
      'When is my order delivered?',
      'We hand it to your courier and send you the courier receipt photo with the tracking number. From then on the parcel is with the courier.',
    ),
    Faq('Where are my bills?', 'Every invoice is in Invoices as a PDF you can download or share.'),
    Faq(
      'A power I need is not stocked. What can I do?',
      'The app offers the nearest stocked power (one step, 0.25, away on the sphere or the cylinder), marked "Different power: check before ordering". If nothing fits, send the power as an RX request and our staff will call you.',
    ),
    Faq('Can my staff order?', 'Yes. The owner gives each staff login its own switches: show prices, show availability, add to cart, place order.'),
  ],
  certificates: const [
    Certificate('Brand authorisation', 'Vishal Optical Co. is an authorised distributor for these brands'),
    Certificate('Lens test report: UV 420 and blue cut', 'For the Blu Safe and Air Smart ranges'),
    Certificate('Photochromic test report', 'For the Photo Fast range'),
    Certificate('Manufacturer quality certificate', 'From the lens manufacturer'),
  ],
  staffLogins: [
    StaffLogin('Ramesh (counter)', '+91 98290 11xxx', [true, true, true, false]),
    StaffLogin('Pooja (fitting)', '+91 98290 22xxx', [false, true, true, false]),
  ],
  rxLabOrders: const [
    RxLabOrder('SO-1044', 'RX progressive · R +1.75 / −1.25 × 70° · ADD +2.25', 'At the lab · in production', 'warn', 2),
    RxLabOrder('SO-1039', 'RX progressive · R −1.50 / −0.75 × 180° · ADD +2.00', 'Dispatched · DTDC', 'good', 4),
  ],
  rxStages: const ['Received', 'Price confirmed', 'At the lab', 'Quality check', 'Dispatched'],
  orderHistory: const [
    OrderRow('SO-1048', '23 Sep', 'Handed to courier', 'good', 36, 41280, courier: 'DTDC', repeatIndex: 0),
    OrderRow('SO-1046', '21 Sep', 'Picking', 'warn', 12, 18960),
    OrderRow('SO-1042', '18 Sep', 'Handed to courier', 'good', 168, 247968, courier: 'Shree Maruti', repeatIndex: 1),
  ],
  byBrand: const [
    SalesShare('VeriWide', 31),
    SalesShare('Air Smart', 22),
    SalesShare('Bold', 17),
    SalesShare('Photo Fast', 13),
    SalesShare('Blu Safe', 10),
    SalesShare('Others', 7),
  ],
  byLensType: const [SalesShare('Single vision', 58), SalesShare('Progressive', 27), SalesShare('KT', 15)],
  topPowers: const [('−1.00 / −0.50', 148), ('−2.00 / −0.50', 131), ('−1.50', 118), ('+1.50 / ADD +2.00', 96)],
  terms: const [
    ('Orders', 'An order can be changed or cancelled for one hour after it is placed. After that it is being picked.'),
    (
      'Short supply',
      'If a power is short when the order is picked, what is available is sent and the rest is cancelled. You are billed only for what is sent.',
    ),
    ('Delivery', 'Orders go by the courier on your account. Delivery is complete when the parcel is handed to the courier and the receipt photo is shared.'),
    ('Billing', 'Prices are per pair at your tier. Freight is added on the invoice.'),
  ],
  webAddress: 'order.vishaloptical.in',
  nextOrderNumber: 'SO-1051',
);
