/// An amount of money, stored in minor units (tiyin, cents, kopeks).
///
/// Why minor units and not `double`: binary floating point cannot represent
/// 0.1 exactly, so `0.1 + 0.2 != 0.3` and balances drift after enough
/// arithmetic. Integers of minor units are exact, which is why every payment
/// system on the wire transmits `"amount": 1050` rather than `10.50`.
///
/// `Decimal` would be the other correct choice; integers are chosen here
/// because the API already speaks minor units and converting at the boundary
/// would add a lossy step for no benefit.
class Money implements Comparable<Money> {
  const Money({required this.minorUnits, required this.currency});

  /// The amount, in the currency's smallest unit.
  final int minorUnits;

  /// ISO-4217 code, e.g. `KZT`, `UZS`, `USD`.
  final String currency;

  /// Most currencies have 2 decimal places, but not all — JPY has 0, and
  /// several Middle Eastern currencies have 3. Hardcoding `100` is a bug that
  /// only surfaces in a new market, so the exponent is looked up per currency.
  static const _exponents = <String, int>{
    'JPY': 0,
    'KRW': 0,
    'KWD': 3,
    'BHD': 3,
    'OMR': 3,
  };

  int get _exponent => _exponents[currency] ?? 2;

  /// For display only. Never feed this back into arithmetic — that is exactly
  /// the round trip through floating point this class exists to prevent.
  String format() {
    final exponent = _exponent;
    final negative = minorUnits < 0;
    final absolute = minorUnits.abs();

    if (exponent == 0) return '${negative ? '-' : ''}$absolute $currency';

    final divisor = _pow10(exponent);
    final whole = absolute ~/ divisor;
    final fraction = (absolute % divisor).toString().padLeft(exponent, '0');
    return '${negative ? '-' : ''}$whole.$fraction $currency';
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  /// Adding two different currencies is meaningless without an exchange rate,
  /// so it throws rather than silently producing a wrong number. Cross-currency
  /// arithmetic belongs in a service that knows the rate and its timestamp.
  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits: minorUnits + other.minorUnits, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits: minorUnits - other.minorUnits, currency: currency);
  }

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Cannot combine $currency with ${other.currency}');
    }
  }

  bool get isNegative => minorUnits < 0;

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => format();
}
