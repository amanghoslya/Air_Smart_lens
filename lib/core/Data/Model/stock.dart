/// Simulated stock, exactly as in the HTML prototype (30 Oct).
///
/// Four states per power, and the customer never sees a quantity:
/// Available · Low stock (still orderable) · Sold out (kept, but none now: can be pre-ordered) · N/A (not kept:
/// demand too low). For testing about 6% N/A, 9% sold out and 12% low stock.
///
/// The real app must take stock status from the ERP. Replace [StockService] with an API-backed version; the
/// quantity is used only for the cart's shortfall check and should come from the server at checkout.
library;

import '../../Utils/js_compat.dart';
import 'models.dart';

enum StockMode {
  /// The prototype's per-power simulation (default).
  simulated,

  /// Every power in stock (the 24 Oct testing mode); only the RX progressive keeps "Made to order".
  allInStock,
}

class StockService {
  StockMode mode;
  StockService({this.mode = StockMode.simulated});

  /// A range's status: made to order for the RX progressive, otherwise in stock (statuses are per power).
  StockStatus stockOf(Product p, int li) {
    if (p.rx) return const StockStatus('mto');
    return const StockStatus('in', qty: 999);
  }

  /// One power of a range, by its grid key (see `LensLogic.cellKey`).
  StockStatus cellStock(Product p, int li, String key) {
    if (p.rx) return const StockStatus('mto');
    if (mode == StockMode.allInStock) return const StockStatus('in', qty: 999);
    final r = jsHash('so:${p.id}:$li:$key');
    if (r < 0.06) return const StockStatus('na');
    if (r < 0.15) return StockStatus('zero', qty: 0, eta: '~${5 + (r * 120).floor()} days');
    final r2 = jsHash('q:${p.id}:$li:$key');
    return r < 0.27 ? StockStatus('in', low: true, qty: 2 + (r2 * 10).floor()) : StockStatus('in', qty: 30 + (r2 * 220).floor());
  }
}
