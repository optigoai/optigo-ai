import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class FeatureFlagService extends ChangeNotifier {
  static final FeatureFlagService _instance = FeatureFlagService._internal();
  factory FeatureFlagService() => _instance;
  FeatureFlagService._internal();

  Map<String, bool> _flags = {
    'ai_cmo_chat': true,
    'content_studio': true,
    'smart_creatives': true,
    'firecrawl_crawler': true,
    'gsc_integration': true,
    'auto_reviews_reply': true,
    'seo_optimizer': true,
    'scheduled_campaigns': true,
  };

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  Map<String, bool> get flags => Map.unmodifiable(_flags);

  bool isEnabled(String featureName, {bool defaultValue = true}) {
    return _flags[featureName] ?? defaultValue;
  }

  Future<void> syncFlags() async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.features}');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _flags = data.map((key, value) => MapEntry(key, value == true));
        notifyListeners();
      }
    } catch (_) {
      // Retain safe defaults on network error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
