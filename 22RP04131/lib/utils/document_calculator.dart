import '../models/models.dart';

class DocumentCalculator {
  static double subtotal(List<DocumentItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  static double discountAmount(double subtotal, double discountPercent) {
    if (discountPercent <= 0) return 0.0;
    return subtotal * (discountPercent / 100);
  }

  static double afterDiscount(double subtotal, double discountPercent) {
    return subtotal - discountAmount(subtotal, discountPercent);
  }

  static double vatAmount(double afterDiscount, bool vatEnabled, double vatRate) {
    if (!vatEnabled) return 0.0;
    return afterDiscount * vatRate;
  }

  static double total({
    required List<DocumentItem> items,
    required double discountPercent,
    required bool vatEnabled,
    required double vatRate,
  }) {
    final sub = subtotal(items);
    final afterDisc = afterDiscount(sub, discountPercent);
    final vat = vatAmount(afterDisc, vatEnabled, vatRate);
    return (afterDisc + vat).clamp(0.0, double.infinity);
  }

  static Map<String, double> calculateAll({
    required List<DocumentItem> items,
    required double discountPercent,
    required bool vatEnabled,
    required double vatRate,
  }) {
    final sub = subtotal(items);
    final disc = discountAmount(sub, discountPercent);
    final afterDisc = afterDiscount(sub, discountPercent);
    final vat = vatAmount(afterDisc, vatEnabled, vatRate);
    final tot = (afterDisc + vat).clamp(0.0, double.infinity);
    return {
      'subtotal': sub,
      'discount': disc,
      'afterDiscount': afterDisc,
      'vat': vat,
      'total': tot,
    };
  }
} 