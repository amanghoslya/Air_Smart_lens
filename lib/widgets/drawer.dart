import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import 'icons.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

/// The side menu (☰ on Home): Hansco's menu without Pay Now (no payment at launch), plus Scan QR, Favorites and
/// Display (dark mode; the button beside each power: QR code or Favorite).
class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  static List<(String, List<(String, String, String)>)> groups(String persona) {
    final money = persona != 'sub';
    return [
      (
        'Ordering',
        [
          ('scan', 'qr', 'Scan QR'),
          ('account', 'user', 'Profile'),
          ('orders', 'box', 'Orders'),
          ('preorder', 'clock', 'Pre-orders'),
          ('wishlist', 'heart', 'Favorites'),
          if (money) ('pricelist', 'tag', 'Price list'),
        ],
      ),
      if (money) ('Money', [('ledger', 'book', 'Ledger'), ('transactions', 'swap', 'Transactions'), ('invoices', 'file', 'Invoices')]),
      ('Marketing', [('posters', 'image', 'Posters'), ('videos', 'video', 'Videos'), ('certs', 'award', 'Certificates')]),
      ('Settings', [if (persona == 'owner') ('stafflogins', 'team', 'Staff logins'), ('weblogin', 'globe', 'Web login'), ('language', 'lang', 'Language')]),
      ('Help', [('contact', 'phone', 'Contact us'), ('faq', 'help', 'FAQ'), ('about', 'info', 'About us'), ('terms', 'doc', 'Terms and conditions')]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    final open = s.drawerOpen;
    final role = s.persona == 'owner'
        ? 'Owner'
        : s.persona == 'staff'
        ? 'Staff login'
        : 'Sub-customer';
    return IgnorePointer(
      ignoring: !open,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: open ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: GestureDetector(
                onTap: s.closeDrawer,
                child: ColoredBox(color: c.scrim),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.ease,
            top: 0,
            bottom: 0,
            left: open ? 0 : -MediaQuery.sizeOf(context).width * .84 - 40,
            width: MediaQuery.sizeOf(context).width * .84,
            child: Container(
              decoration: BoxDecoration(
                color: c.paper,
                boxShadow: [BoxShadow(color: c.shade, blurRadius: 60, offset: const Offset(24, 0), spreadRadius: -18)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(22, MediaQuery.paddingOf(context).top + 24, 22, 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.line)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Air Smart Lens',
                          style: TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w600, fontSize: 28, height: 1, color: c.ink),
                        ),
                        const SizedBox(height: 4),
                        Text('BY VISHAL OPTICAL CO.', style: TextStyle(fontSize: 10, letterSpacing: 2.4, color: c.ink2)),
                        const SizedBox(height: 14),
                        Text(
                          s.cust.name,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                        ),
                        Text('$role · ${s.cust.tier}', style: TextStyle(fontSize: 12.5, color: c.ink2)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
                      children: [
                        for (final g in groups(s.persona)) ...[
                          _grp(context, s.tr(g.$1)),
                          for (final it in g.$2) _item(context, Ic.mi[it.$2]!, s.tr(it.$3), () => s.menuGo(it.$1)),
                        ],
                        _grp(context, s.tr('Display')),
                        Builder(
                          builder: (context) {
                            final dk = s.dark ?? Theme.of(context).brightness == Brightness.dark; // follows the phone until switched
                            return Semantics(
                              toggled: dk,
                              child: _item(context, Ic.mi['moon']!, s.tr('Dark mode'), () => s.setDark(!dk), trailing: Toggle(on: dk)),
                            );
                          },
                        ),
                        _PowerButtonPick(s.qrMake, s.setQrMake),
                        _grp(context, ''),
                        _item(context, Ic.mi['out']!, s.tr('Sign out'), () {
                          s.closeDrawer();
                          showSignOutDialog(context, s);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grp(BuildContext context, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
    child: Text(
      t.toUpperCase(),
      style: TextStyle(fontSize: 10.5, letterSpacing: 1.47, fontWeight: FontWeight.w600, color: context.c.mute),
    ),
  );

  Widget _item(BuildContext context, IconDef icon, String label, VoidCallback onTap, {Widget? trailing}) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SvgIcon(icon, size: 20, color: context.c.ink2),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 14, color: context.c.ink)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    ),
  );
}

/// `.dpick`: "Button beside each power": QR code (make a label for it) or Favorite (save it to Favorites).
class _PowerButtonPick extends StatelessWidget {
  final bool qr;
  final ValueChanged<bool> onPick;
  const _PowerButtonPick(this.qr, this.onPick);
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgIcon(Ic.mi[qr ? 'qr' : 'heart']!, size: 20, color: c.ink2),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.tr('Button beside each power'), style: TextStyle(fontSize: 14, color: c.ink)),
                    Text(s.tr(qr ? 'Make a QR label for it' : 'Save it to Favorites'), style: TextStyle(fontSize: 12, color: c.ink2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Seg(items: [('1', s.tr('QR code')), ('0', s.tr('Favorite'))], value: qr ? '1' : '0', onTap: (v) => onPick(v == '1')),
          ),
        ],
      ),
    );
  }
}
