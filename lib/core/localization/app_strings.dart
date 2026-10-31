/// Simple string lookup table for the working Urdu/English toggle.
/// Covers Home, bottom nav labels, and Settings — the highest-visibility
/// screens for a demo. To cover more screens, add more keys here and call
/// AppStrings.of(context, 'key') at the relevant Text widgets — same
/// pattern throughout.
class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _strings = {
    'nav_home': {'en': 'Home', 'ur': 'ہوم'},
    'nav_history': {'en': 'History', 'ur': 'ریکارڈ'},
    'nav_trends': {'en': 'Trends', 'ur': 'رجحانات'},
    'nav_map': {'en': 'Map', 'ur': 'نقشہ'},
    'nav_settings': {'en': 'Settings', 'ur': 'ترتیبات'},

    'home_greeting_consumer': {'en': 'What would you like to test today?', 'ur': 'آج آپ کیا ٹیسٹ کرنا چاہتے ہیں؟'},
    'home_greeting_vendor': {'en': 'Verify your shop\'s quality before you sell', 'ur': 'بیچنے سے پہلے اپنی دکان کے معیار کی تصدیق کریں'},
    'home_greeting_admin': {'en': 'Manage users and monitor community data', 'ur': 'صارفین کا نظم کریں اور کمیونٹی ڈیٹا کی نگرانی کریں'},
    'home_water': {'en': 'Water', 'ur': 'پانی'},
    'home_milk': {'en': 'Milk', 'ur': 'دودھ'},
    'home_insights': {'en': 'Community Insights', 'ur': 'کمیونٹی بصیرت'},
    'home_recent_activity': {'en': 'Recent Activity', 'ur': 'حالیہ سرگرمی'},

    'settings_title': {'en': 'Settings', 'ur': 'ترتیبات'},
    'settings_profile': {'en': 'Profile', 'ur': 'پروفائل'},
    'settings_notifications': {'en': 'Hotspot Notifications', 'ur': 'ہاٹ سپاٹ نوٹیفیکیشن'},
    'settings_dark_mode': {'en': 'Dark Mode', 'ur': 'ڈارک موڈ'},
    'settings_urdu': {'en': 'Urdu Language', 'ur': 'اردو زبان'},
    'settings_text_size': {'en': 'Text Size', 'ur': 'تحریر کا سائز'},
    'settings_logout': {'en': 'Logout', 'ur': 'لاگ آؤٹ'},
    'settings_help': {'en': 'How to use HIFAZAT', 'ur': 'حفاظت کیسے استعمال کریں'},

    // Vendor / admin
    'home_my_business': {'en': 'My Business', 'ur': 'میرا کاروبار'},
    'home_verified_vendors': {'en': 'Verified Vendors', 'ur': 'تصدیق شدہ فروخت کنندگان'},
    'home_admin': {'en': 'Admin Dashboard', 'ur': 'ایڈمن ڈیش بورڈ'},

    // Verdicts — these MUST stay accurate in Urdu. A mistranslated safety
    // verdict is worse than an untranslated one.
    'verdict_safe': {'en': 'SAFE', 'ur': 'محفوظ'},
    'verdict_caution': {'en': 'CAUTION', 'ur': 'احتیاط'},
    'verdict_unsafe': {'en': 'UNSAFE', 'ur': 'غیر محفوظ'},
    'verdict_inconclusive': {'en': 'INCONCLUSIVE', 'ur': 'غیر حتمی'},
    'verdict_retest': {'en': 'Please re-test', 'ur': 'دوبارہ ٹیسٹ کریں'},

    'milk_purity': {'en': 'Milk Purity', 'ur': 'دودھ کی خالصیت'},
    'pure': {'en': 'pure', 'ur': 'خالص'},
    'impure': {'en': 'impure', 'ur': 'ناخالص'},
  };

  static String get(String key, {required bool isUrdu}) {
    final entry = _strings[key];
    if (entry == null) return key;
    return isUrdu ? (entry['ur'] ?? entry['en']!) : entry['en']!;
  }
}
