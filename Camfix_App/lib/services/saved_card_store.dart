import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The customer's saved payment card - display details only (last 4 digits,
/// brand guess, expiry). This is a mock checkout with no real card
/// processor, so the full card number and CVV are never captured past the
/// "Add card" form itself and never stored anywhere.
class SavedCard {
  const SavedCard({
    required this.holderName,
    required this.last4,
    required this.expiry,
  });

  final String holderName;
  final String last4;

  /// "MM/YY".
  final String expiry;
}

class SavedCardStore extends ChangeNotifier {
  SavedCardStore._();
  static final SavedCardStore instance = SavedCardStore._();

  static const _kHolder = 'payment_card_holder';
  static const _kLast4 = 'payment_card_last4';
  static const _kExpiry = 'payment_card_expiry';

  SavedCard? _card;
  SavedCard? get card => _card;
  bool get hasCard => _card != null;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last4 = prefs.getString(_kLast4);
      if (last4 != null && last4.isNotEmpty) {
        _card = SavedCard(
          holderName: prefs.getString(_kHolder) ?? '',
          last4: last4,
          expiry: prefs.getString(_kExpiry) ?? '',
        );
      }
    } catch (_) {
      _card = null;
    }
    notifyListeners();
  }

  Future<void> save(SavedCard card) async {
    _card = card;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kHolder, card.holderName);
      await prefs.setString(_kLast4, card.last4);
      await prefs.setString(_kExpiry, card.expiry);
    } catch (_) {/* keep it in memory even if the write fails */}
  }
}
