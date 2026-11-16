/// Brand photography, names and the brand ordering used across the app.
library;

import '../../Utils/format.dart';
import 'models.dart';

const cardBrands = [
  ('VERIWIDE', 'veriwide'),
  ('AIR SMART', 'airsmart'),
  ('KOPPERX', 'kopperx'),
  ('VISHAL', 'vishal'),
  ('LORDS', 'lords'),
  ('MAXX', 'max'),
  ('BOLD', 'bold'),
];

const brandImage = <String, String>{
  'SLX': 'slx1_face',
  'CLEAR': 'clear1_face',
  'OPAL': 'opal2_face',
  'VERIWIDE': 'veriwide3_face',
  'AIR SMART': 'airsmart3_face',
  'KOPPERX': 'kopperx3_face',
  'VISHAL': 'vishal3_face',
  'LORDS': 'lords3_face',
  'MAXX': 'max2_face',
  'BOLD': 'bold2_face',
  'PHOTO FAST': 'photofast3_face',
  'BLU SAFE': 'blusafe3_face',
  // brands with no brand photo yet show their first envelope (2 Nov price file)
  'VOLT': 'volt_env',
  'CROMA': 'croma_env',
  'RAPID': 'rapid_env',
};

const _bName = <String, String>{
  'VERIWIDE': 'VeriWide',
  'AIR SMART': 'Air Smart',
  'KOPPERX': 'Kopper X',
  'MAXX': 'Max',
  'PHOTO FAST': 'Photo Fast',
  'BLU SAFE': 'Blu Safe',
  'SLX': 'SLX',
  'VOLT': 'Volt',
  'CROMA': 'Croma',
  'RAPID': 'Rapid',
};

/// Brand images that are really an envelope photo (brands with no brand photo yet).
const envAlias = <String, String>{'volt_env': 'r34', 'croma_env': 'r367', 'rapid_env': 'r454'};

String bname(String b) => _bName[b] ?? titlecase(b);

const brandLine = <String, String>{
  'SLX': 'Smarter vision for everyday life',
  'CLEAR': 'Clearer everyday vision',
  'VERIWIDE': 'A clearer tomorrow for everyone',
  'AIR SMART': 'Light on eyes. Ahead in life.',
  'KOPPERX': 'Built to protect. Made to perform.',
  'VISHAL': 'Trusted clarity for every journey',
  'LORDS': 'Timeless vision for a modern world',
  'MAXX': 'More vision. More possibilities.',
  'BOLD': 'See life bolder',
  'PHOTO FAST': 'Adapts to light. Designed for life.',
  'BLU SAFE': 'Built for screens. Designed for life.',
  'OPAL': 'Clarity for a brighter you',
  'VOLT': 'No yellow tint, blue cut',
  'CROMA': 'Round top KT, hard coated',
  'RAPID': 'Your world, our vision',
};

/// Home carousel: the client's brand cards (using clean text-free background images).
const heroCards = [
  ('VISHAL', 'vishal_bg'),
  ('VERIWIDE', 'welcome_bg'),
  ('AIR SMART', 'airsmart_bg'),
  ('KOPPERX', 'kopperx_bg'),
  ('SLX', 'slx_bg'),
  ('CLEAR', 'clear_bg'),
  ('OPAL', 'opal_bg'),
  ('LORDS', 'lords_bg'),
  ('MAXX', 'max_bg'),
  ('BOLD', 'bold_bg'),
];

/// Every poster the client has sent.
final posters = <(String, String)>[
  ('LORDS', 'lords3_full'),
  ('VISHAL', 'vishal3_full'),
  ('AIR SMART', 'airsmart3_full'),
  ('VERIWIDE', 'veriwide3_full'),
  ('BLU SAFE', 'blusafe3_full'),
  ('PHOTO FAST', 'photofast3_full'),
  ('KOPPERX', 'kopperx3_full'),
  ('SLX', 'slx1_full'),
  ('SLX', 'slx2_full'),
  ('CLEAR', 'clear1_full'),
  ('CLEAR', 'clear2_full'),
  ('OPAL', 'opal1_full'),
  ('OPAL', 'opal2_full'),
  for (final b in cardBrands) (b.$1, '${b.$2}2_card'),
  for (final b in cardBrands) (b.$1, '${b.$2}1_card'),
];

/// Aspect ratio (width / height) of a brand image, so posters keep their full design.
double imageAspect(String k, Map<String, double> known) {
  final v = known[k];
  if (v != null) return v;
  if (k.endsWith('_bg')) return 768 / 1376;
  if (k.endsWith('_full')) return 941 / 1672;
  if (k.endsWith('1_card')) return 227 / 524;
  return 226 / 448;
}

/// Products of a brand. Kopper X is a coating in the price file.
List<Product> brandProducts(String b, List<Product> catalog) =>
    b == 'KOPPERX' ? catalog.where((p) => coatKey(p) == 'KOPPERX').toList() : catalog.where((p) => p.brand == b).toList();

/// The seven with brand cards first, then SLX, Clear and Opal, then the rest by size.
List<String> brandOrder(List<Product> catalog) {
  final photo = [...cardBrands.map((x) => x.$1), 'SLX', 'CLEAR', 'OPAL'];
  final rest = <String>[];
  for (final p in catalog) {
    if (!photo.contains(p.brand) && !rest.contains(p.brand)) rest.add(p.brand);
  }
  final sized = rest.map((b) => (b, brandProducts(b, catalog).length)).toList();
  // stable sort by size, descending
  final idx = {for (var i = 0; i < sized.length; i++) sized[i].$1: i};
  sized.sort((a, b) {
    final d = b.$2 - a.$2;
    return d != 0 ? d : idx[a.$1]!.compareTo(idx[b.$1]!);
  });
  return [...photo, ...sized.map((e) => e.$1)];
}

/// Three feature icons for the product page, from the base and the features text.
List<(String icon, String label)> featIcons(Product p) {
  const want = [
    (r'uv|420', 'sun', 'UV protection'),
    (r'blue|screen|digital|eye strain', 'screen', 'Blue light protection'),
    (r'photo|sun|dark', 'sun', 'Darkens in sunlight'),
    (r'scratch|hard|durable', 'shield', 'Scratch resistant'),
    (r'dust|water|smudge|oil', 'drop', 'Dust and water repellent'),
    (r'clarity|clear|vision|wide', 'eye', 'High clarity'),
  ];
  final base = '${p.base} ${p.features ?? ''}';
  final pick = <(String, String)>[];
  for (final w in want) {
    if (pick.length < 3 && RegExp(w.$1, caseSensitive: false).hasMatch(base) && !pick.any((x) => x.$2 == w.$3 || x.$1 == w.$2 && w.$2 == 'sun')) {
      pick.add((w.$2, w.$3));
    }
  }
  if (pick.length < 3) pick.add(('shield', 'Hard coated'));
  if (pick.length < 3) pick.add(('eye', 'High clarity'));
  return pick.take(3).toList();
}

/// Coatings the order-placed animation cycles through.
const coats = [
  ('Evergreen', [76, 150, 70]),
  ('Opal', [70, 120, 196]),
  ('Kopper X', [190, 104, 36]),
  ('Solara Gold', [206, 164, 40]),
  ('Volt', [48, 66, 150]),
  ('Shine', [56, 158, 146]),
];

const coatIndex = <String, int>{
  'GREEN': 0,
  'OPAL': 1,
  'OPAL (LOW REFLECTION BLUE)': 1,
  'KOPPERX': 2,
  'SOLARA GOLD': 3,
  'DARK BLUE': 4,
  'VOLT': 4,
  'SHINE': 5,
  'BLUE-GREEN': 5,
  'SHINE (BLUE-GREEN)': 5,
};

/// Hindi for the menu, tab bar and home screen (the full app is translated in the build, Q52).
const hindi = <String, String>{
  'Home': 'होम',
  'Shop': 'खरीदें',
  'Orders': 'ऑर्डर',
  'Account': 'खाता',
  'Profile': 'प्रोफ़ाइल',
  'Pre-orders': 'प्री-ऑर्डर',
  'Favorites': 'पसंदीदा',
  'Scan QR': 'QR स्कैन',
  'Price list': 'मूल्य सूची',
  'Ledger': 'खाता बही',
  'Transactions': 'लेन-देन',
  'Invoices': 'बिल',
  'Sales report': 'बिक्री रिपोर्ट',
  'Sales analysis': 'बिक्री विश्लेषण',
  'Posters': 'पोस्टर',
  'Videos': 'वीडियो',
  'Certificates': 'प्रमाणपत्र',
  'Staff logins': 'स्टाफ लॉगिन',
  'Web login': 'वेब लॉगिन',
  'Language': 'भाषा',
  'Contact us': 'संपर्क करें',
  'FAQ': 'सामान्य प्रश्न',
  'About us': 'हमारे बारे में',
  'Terms and conditions': 'नियम और शर्तें',
  'Dark mode': 'डार्क मोड',
  'Button beside each power': 'हर पावर के पास बटन',
  'Make a QR label for it': 'उसका QR लेबल बनाएं',
  'Save it to Favorites': 'पसंदीदा में सहेजें',
  'QR code': 'QR कोड',
  'Favorite': 'पसंदीदा',
  'Display': 'डिस्प्ले',
  'Sign out': 'साइन आउट',
  'Ordering': 'ऑर्डरिंग',
  'Money': 'हिसाब',
  'Marketing': 'मार्केटिंग',
  'Settings': 'सेटिंग्स',
  'Help': 'सहायता',
  'Brands': 'ब्रांड',
  'Prescription lenses': 'प्रिस्क्रिप्शन लेंस',
  'Bulk ordering': 'थोक ऑर्डर',
  'Bulk order': 'थोक ऑर्डर',
  'Parcel order': 'पार्सल ऑर्डर',
  'Featured brands': 'मुख्य ब्रांड',
  'Posters and videos': 'पोस्टर और वीडियो',
  'See all': 'सभी देखें',
  'Good morning': 'सुप्रभात',
  'See every power,\norder in a minute': 'हर पावर देखें,\nएक मिनट में ऑर्डर करें',
  'How would you like to order?': 'आप कैसे ऑर्डर करना चाहेंगे?',
  'Parcel order\n(small quantity)': 'पार्सल ऑर्डर\n(कम मात्रा)',
  'Stock order\n(bulk)': 'स्टॉक ऑर्डर\n(थोक)',
  'RX order': 'आरएक्स ऑर्डर',
  'RX progressive\n(made to order)': 'आरएक्स प्रोग्रेसिव\n(लैब में बना)',
};
