import 'package:flutter/material.dart';

import '../core/Utils/format.dart';
import '../core/Utils/js_compat.dart';
import '../core/Data/Model/stock.dart';
import '../state/app_scope.dart';
import 'icons.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

/// The prototype's notes column, kept as a debug menu (not for customers):
/// jump to a screen, "Viewing as" persona, what this screen does, this order's
/// totals, the stock simulation and the rules agreed so far.
class DebugMenuButton extends StatelessWidget {
  const DebugMenuButton({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Positioned(
      right: 10,
      bottom: 90 + MediaQuery.paddingOf(context).bottom,
      child: Semantics(
        button: true,
        label: 'Debug menu',
        child: GestureDetector(
          onTap: () => showAppSheet(context, (_) => const DebugMenu()),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.navy.withValues(alpha: .55), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: SvgIcon(Ic.bug, size: 18, color: c.onNavy),
          ),
        ),
      ),
    );
  }
}

const jumps = [
  ('welcome', 'Welcome'),
  ('home', 'Home'),
  ('shop', 'Shop'),
  ('rangetype', 'Shop by range'),
  ('rangelist', 'Range list'),
  ('scan', 'Scan QR'),
  ('search', 'Search'),
  ('wishlist', 'Favorites'),
  ('lenstype', 'Lens type'),
  ('rx', 'Parcel order: power'),
  ('options', 'Lens options'),
  ('results', 'Results'),
  ('product', 'Product'),
  ('cart', 'Cart'),
  ('checkout', 'Checkout'),
  ('loading', 'Loading animation'),
  ('placed', 'Order placed'),
  ('orders', 'Orders'),
  ('rxhome', 'RX order'),
  ('rxdetails', 'RX details'),
  ('stocktype', 'Bulk: lens type'),
  ('stockpick', 'Bulk: product'),
  ('grid', 'Power grid'),
  ('brands', 'Brands'),
  ('account', 'Account'),
  ('ledger', 'Ledger'),
  ('preorder', 'Pre-orders'),
  ('stafflogins', 'Staff logins'),
];

class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    final t = s.cartTotals;
    Widget chip(String label, bool on, VoidCallback onTap) => ChipBtn(label, on: on, onTap: onTap);
    Widget h(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11, letterSpacing: 1.54, fontWeight: FontWeight.w600, color: c.mute),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Prototype tools',
          style: TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w600, fontSize: 24, color: c.ink),
        ),
        const Muted('Debug builds only. Customers never see this menu.'),
        h('Jump to a screen'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final j in jumps)
              chip(j.$2, s.screen == j.$1, () {
                Navigator.of(context).pop();
                s.jump(j.$1);
              }),
          ],
        ),
        h('This screen'),
        Text(explain[s.screen] ?? '', style: TextStyle(fontSize: 13, color: c.ink2, height: 1.45)),
        h('Viewing as'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            chip('Shop owner', s.persona == 'owner', () => s.setPersona('owner')),
            chip('Staff login · cannot place orders', s.persona == 'staff', () => s.setPersona('staff')),
            chip('Sub-customer · no prices, orders via distributor', s.persona == 'sub', () => s.setPersona('sub')),
          ],
        ),
        const Muted(
          'The four switches Vishal sets for each account and staff login: show prices, show availability, add to cart, place order.',
          margin: EdgeInsets.only(top: 8),
        ),
        h('Stock'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            chip('Everything in stock (testing)', s.stock.mode == StockMode.allInStock, () => s.setStockMode(StockMode.allInStock)),
            chip('Simulated stock levels', s.stock.mode == StockMode.simulated, () => s.setStockMode(StockMode.simulated)),
          ],
        ),
        h('Cart reminders'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            chip('Normal: shake after 5 min, notification 10 min after leaving', !s.fastReminders, () => s.setFastReminders(false)),
            chip('Test: shake after 10 s, notification 30 s after leaving', s.fastReminders, () => s.setFastReminders(true)),
          ],
        ),
        const Muted(
          'With something in the cart, leave the app untouched for the shake, or press Home for the notification. Opening the app again cancels it.',
          margin: EdgeInsets.only(top: 8),
        ),
        h('This order'),
        Row(children: [_stat(context, jsNum(t.n), 'pairs in cart'), const SizedBox(width: 26), _stat(context, money(t.v), 'cart value')]),
        h('Agreed and shown here'),
        for (final a in agreed)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('•  $a', style: TextStyle(fontSize: 13, color: c.ink2, height: 1.4)),
          ),
      ],
    );
  }

  Widget _stat(BuildContext context, String v, String l) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        v,
        style: TextStyle(fontFamily: kSerif, fontSize: 30, fontWeight: FontWeight.w600, height: 1, color: context.c.ink, fontFeatures: kTabular),
      ),
      Text(l, style: TextStyle(fontSize: 12, color: context.c.mute)),
    ],
  );
}

const agreed = [
  'Two buttons up front: Parcel order (small quantity, from the power) and Stock order (bulk, on a power grid).',
  'Powers are set on scroll wheels, as in the Hansco app: one wheel each for SPH and CYL, plus AXIS and ADD for KT and progressive. Each step clicks. KT axis only 45°, 90°, 135° and 180°; progressive in 5° steps. Type keys in any value.',
  'Customers see status only: In stock, Sold out, Not kept in stock, Coming soon. No quantities while browsing (Q9).',
  'A shortfall shows in the cart: "You ordered 100; 20 are available". The customer orders what is available, changes the quantity or removes the line (Q11).',
  'An order can be changed or cancelled for one hour after it is placed (Q13).',
  'The last stage customers see is "Handed to courier", with the tracking photo (Q14).',
  'Nearest power within 0.50 is offered and marked "Different power: check before ordering" (Q15).',
  'Invoices arrive as PDFs in the app (Q35). Wishlist, posters and videos are in the first version.',
  "The side menu (☰ on Home) carries Hansco's menu: profile, orders, pre-orders, price list, ledger, transactions, sales report and analysis, posters, videos, certificates, web login, Hindi, contact, FAQ, about, terms. Left out: Pay Now (no payment at launch) and the QR scanner.",
];

/// "This screen": what each screen does and the rule behind it.
const explain = <String, String>{
  'welcome': 'The first screen after installing the app: the VeriWide poster in high resolution, full screen. Tap anywhere, or the arrow, to start.',
  'login': 'Login by mobile number and a one-time code. Vishal creates each account and staff login; there is no self sign-up.',
  'home':
      "Home, in the mood-board layout: the client's seven brand cards as a swipeable carousel (each opens that brand), quick links (Brands, Parcel order, Bulk ordering, RX order, Wishlist), featured brands, then posters and videos (the second set of brand cards, ready to download or share on WhatsApp). The bag at the top right opens the cart from anywhere.",
  'shop':
      'The first question for every new order: Parcel (small quantity, from the power) or Stock (bulk, box quantities on a power grid). The two paths stay separate from here to the cart, as in the original flow.',
  'lenstype':
      'Step 1 of the parcel path: the lens type. It decides which columns the power screen asks for (single vision: SPH and CYL; KT and progressive: SPH, CYL, axis and ADD).',
  'rx':
      "The parcel order's power screen. Single vision and KT: one power, ordered in pairs in steps of 0.5 (0.5 = one lens; right and left are the same lens). Progressive: choose Pair, Right eye only or Left eye only here; for a pair, left is the same as right until it is changed. Tap a value in the table to choose the field, then set it on the scroll wheels (as in the Hansco app): one wheel per field, side by side — flick or drag, each step clicks, and tapping a value moves to it. Plus powers sit above 0.00 and minus powers below; axis is KT only 45°, 90°, 135° and 180°, progressive in 5° steps, never 0°. Type keys in any value. Previous Rx fills the last power ordered. After a lens is added to the cart, this screen comes back for the same lens: dial the next power, set the quantity and tap Add, as many times as needed, then Review and check out.",
  'options':
      'Lens options, as on the mood board: index and coating, showing only what is stocked for this power. Leaving everything unticked shows every lens. This is the extra step the original flow had; it keeps the result list short.',
  'results':
      "Every lens that stocks the power, with status only (no quantities, Q9). For testing, every stocked power shows In stock. Then lenses with a power within 0.50, marked 'Different power: check before ordering' (Q15), then the made-to-order progressive. If nothing fits, the power goes as an RX request.",
  'product':
      "The product page: lens, price per pair at this shop's tier, three features, the facts that matter to an optician, and right / left quantities. The heart adds it to the wishlist.",
  'cart':
      "The cart. This is where a shortfall shows: 'You ordered 100 pairs; 20 are available'. The customer orders what is available, changes the quantity, or removes the line (Q11). Pencil edits, bin removes.",
  'checkout':
      'Checkout reads the order back in plain sentences, replacing the confirmation call. Delivery is by courier to the shop. Credit headroom shows before sending. Staff logins save to the shop cart; sub-customers send to their distributor.',
  'placed':
      'Order placed. A glass lens spins above an open envelope while its coating runs through Evergreen, Opal, Kopper X, Solara Gold, Volt and Shine, settling on the coating in this order. It drops in, the flap folds shut, the Vishal seal presses on and confetti rises: packed and on its way. Tap it to replay; anyone with reduced motion switched on sees the sealed envelope only. It can be changed or cancelled for one hour (Q13). Short lines go with what is available; the rest is cancelled (Q11).',
  'orders':
      "Orders and their stage. The last stage customers see is 'Handed to courier', with the courier receipt photo (Q14). Invoices are PDFs (Q35). Any order can be repeated.",
  'account': 'Account: credit, invoices, language (English and Hindi, Q52), staff logins and their four switches, support.',
  'brands':
      'All brands, filtered by lens type: the seven with brand cards first (photos from the client\'s brand set), then the rest of the price file with the lens art. Kopper X is a coating in the price file, so its page lists the lenses with that coating.',
  'brand': 'One brand: its products by lens type. Tapping a product opens it with both ways to order.',
  'stocktype':
      'Step 1 of the stock path: My products at the top go straight to their ranges (the usual case for a shop restocking). Otherwise choose the lens type, the same three cards as the parcel path. The type also decides the grid: single vision is sphere × cylinder, KT and progressive are power × ADD.',
  'stockpick': 'Step 2: the products of that lens type, grouped by brand, with a search box and chips to switch type. Tap a product to see its ranges.',
  'stockrange': "Step 2: the product's stocked ranges, straight from the price file, each with its exact block of powers, diameter and price.",
  'grid':
      "Step 3: the power grid for one range. Where the range belongs to a Super Master, the grid is that Super Master's full standard grid (for example −6/−2 for M05), and powers outside this product's own range are greyed out (hatched); this is how shops know the standard ranges (24 Oct). Lines with no shared Super Master show their own range. Tap a box and type the quantity: the phone's own number keyboard opens, and its Next key moves to the next box. Fill row and Same in all copy the selected quantity. Copy last order fills the grid from the previous order of this range. For testing, every power shows in stock.",
  'search':
      'One box for a coating (opal), a brand (photo), an index (1.67), a range code (−6−2) or a power (−2.00/−0.50). A power opens the parcel order with it filled in.',
  'wishlist':
      'Favorites: powers (saved with the heart beside an added power, when the side menu says Favorite; opening one works like scanning its QR), ranges and lenses saved with the heart.',
  'rangetype': 'Shop › Shop by range: choose single vision, KT or progressive, then the range code.',
  'rangelist':
      'Every range code of the lens type, grouped (minus, plus, compound, cross …), with how many lenses are made in it and the lowest price per pair.',
  'rangeprods':
      'Every lens made in the chosen range, by brand. Tap one to order in this range as a parcel (wheels or the power chart) or in bulk (the power grid).',
  'scan':
      'Scan QR, in the side menu. A QR code holds one lens, range and power (pair, right eye or left eye) as plain text, read against the catalogue on the phone, so it works offline. Scanning opens the product page with everything filled in; the customer types the quantity. Sample codes and the codes made on this phone can be tapped; a code can also be typed.',
  'preorder': "Hansco's Preorder Facility. Ranges marked coming soon in the price file can be pre-ordered; they are sent when the stock arrives.",
  'posters': "Hansco's Poster section: the client's brand cards, ready to download or share on WhatsApp.",
  'videos': "Hansco's Video section: training and product videos for the shop.",
  'certs': "Hansco's Certificate section: documents a shop can show its customers. Titles here are examples.",
  'pricelist': "Hansco's Price List: this shop's tier prices for every range, by brand, with a PDF. Hidden for sub-customers.",
  'ledger':
      "Hansco's Ledger: the account statement from the accounts system, with each invoice's PDF. Closing balance matches the outstanding on the Account tab.",
  'transactions': "Hansco's Transaction list: payments and credit notes received.",
  'invoices': 'Invoices as PDFs (Q35), to download or share.',
  'salesreport': "Hansco's Sales Report: what this shop bought from Vishal, month by month.",
  'analysis': "Hansco's Sales Analysis Report: share by brand and lens type, most ordered powers.",
  'stafflogins': 'Owners manage staff logins and the four switches here (agreed: owners only, delegation to staff optional).',
  'weblogin': "Hansco's Web Login: the same account on a computer. The web address is a placeholder.",
  'language': "Hansco's Translate to Hindi. Hindi and English both (Q52). In this model the menu, tab bar and home switch.",
  'contact': 'Contact Us, with the support routes agreed in Q53: phone, WhatsApp group, support tickets, remote help with staff approval.',
  'faq': 'FAQ written from the rules already agreed: stock labels, shortfall, the one-hour window, courier hand-over, invoices, staff switches.',
  'about': 'About Us. Text and photos to come from the client.',
  'terms': 'Terms and Conditions. Draft wording from the agreed rules, for the client to approve.',
  'rxhome':
      "RX orders are progressive only: the VeriWide RX progressive, made at the lab to the customer's power (sphere 0 to ±2.00, cylinder up to 2.00 at any axis in 10° steps, ADD +1.00 to +3.00). One button goes to the parcel order's power screen, with the lens type fixed to progressive. Below, the shop's RX orders and their lab stage.",
  'rxdetails':
      'RX details: the VeriWide RX progressive with its price when the power is in its range; otherwise an RX request that staff check with the lab. Patient reference and lab notes go with the line into the cart and the order. Single vision and KT are not made to order.',
  'loading':
      'The loading animation: the glass lens spins on its edge while the coating colours cycle (Evergreen, Opal, Kopper X, Solara Gold, Volt, Shine), over a soft paper veil, with one line saying what is happening. It appears when signing in, checking stock, finding lenses and placing an order. In the real app it shows only while waiting for the server.',
};
