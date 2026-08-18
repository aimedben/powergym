import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';

class PricingService extends ChangeNotifier {
  static const Map<SubscriptionType, String> _defaultPrices = {
    SubscriptionType.monthly: '1500',
    SubscriptionType.quarterly: '4500',
    SubscriptionType.semester: '6000',
    SubscriptionType.annual: '15000',
  };

  Map<SubscriptionType, String> _prices = Map.from(_defaultPrices);

  Map<SubscriptionType, String> get prices => Map.unmodifiable(_prices);

  PricingService() {
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    final prefs = await SharedPreferences.getInstance();
    for (final type in SubscriptionType.values) {
      if (type == SubscriptionType.custom) continue;
      _prices[type] = prefs.getString('price_${type.name}') ?? _defaultPrices[type]!;
    }
    notifyListeners();
  }

  Future<void> updatePrice(SubscriptionType type, String price) async {
    _prices[type] = price;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('price_${type.name}', price);
    notifyListeners();
  }

  String getPrice(SubscriptionType type) {
    return _prices[type] ?? _defaultPrices[type] ?? '0';
  }

  double getPriceDouble(SubscriptionType type) {
    return double.tryParse(getPrice(type)) ?? 0.0;
  }
}
