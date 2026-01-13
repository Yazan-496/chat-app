import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'chats': 'Chats',
      'typing': 'typing...',
      'settings': 'Settings',
      'profile': 'Profile',
      'login': 'Login',
      'register': 'Register',
      'username': 'Username',
      'password': 'Password',
      'no_chats': 'No chats yet. Start by searching for users!',
      'new_message': 'New Message',
      'you_have_new_message': 'You have a new message',
    },
    'ar': {
      'chats': 'المحادثات',
      'typing': 'يكتب...',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'login': 'تسجيل الدخول',
      'register': 'تسجيل',
      'username': 'اسم المستخدم',
      'password': 'كلمة المرور',
      'no_chats': 'لا توجد محادثات بعد. ابدأ بالبحث عن مستخدمين!',
      'new_message': 'رسالة جديدة',
      'you_have_new_message': 'لديك رسالة جديدة',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
