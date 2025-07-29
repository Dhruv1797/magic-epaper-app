import 'dart:io';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:magic_epaper_app/ndef_screen/app_nfc/app_data_model.dart';

class AppLauncherService {
  static List<AppData> _cachedApps = [];

  static Future<List<AppData>> getInstalledApps() async {
    if (_cachedApps.isNotEmpty) {
      return _cachedApps;
    }

    try {
      if (Platform.isAndroid) {
        return await _getAndroidApps();
      } else if (Platform.isIOS) {
        return await _getIOSApps();
      }
    } catch (e) {
      print('Error getting installed apps: $e');
    }

    return [];
  }

  static Future<List<AppData>> _getAndroidApps() async {
    try {
      // Using installed_apps package for Android
      final List<AppInfo> apps = await InstalledApps.getInstalledApps();

      _cachedApps = apps
          .where((app) => app.packageName.isNotEmpty && app.name.isNotEmpty)
          .map((app) => AppData(
                appName: app.name,
                packageName: app.packageName,
              ))
          .toList();

      // Sort alphabetically by app name
      _cachedApps.sort((a, b) => a.appName.compareTo(b.appName));

      return _cachedApps;
    } catch (e) {
      print('Error getting Android apps: $e');
      return [];
    }
  }

  static Future<List<AppData>> _getIOSApps() async {
    // iOS has strict limitations on listing installed apps due to privacy restrictions
    // We provide common app URL schemes that are publicly known
    _cachedApps = [
      // Built-in iOS apps
      AppData(appName: 'Safari', packageName: 'http://'),
      AppData(appName: 'Mail', packageName: 'mailto:'),
      AppData(appName: 'Phone', packageName: 'tel:'),
      AppData(appName: 'Messages', packageName: 'sms:'),
      AppData(appName: 'Maps', packageName: 'maps:'),
      AppData(appName: 'App Store', packageName: 'itms-apps:'),
      AppData(appName: 'Settings', packageName: 'app-settings:'),
      AppData(appName: 'Camera', packageName: 'camera:'),
      AppData(appName: 'Photos', packageName: 'photos-redirect:'),
      AppData(appName: 'Music', packageName: 'music:'),
      AppData(appName: 'Calendar', packageName: 'calshow:'),
      AppData(appName: 'Contacts', packageName: 'contacts:'),
      AppData(appName: 'Notes', packageName: 'mobilenotes:'),
      AppData(appName: 'Reminders', packageName: 'x-apple-reminder:'),
      AppData(appName: 'Clock', packageName: 'clock-worldclock:'),
      AppData(appName: 'Weather', packageName: 'weather:'),
      AppData(appName: 'Stocks', packageName: 'stocks:'),
      AppData(appName: 'Calculator', packageName: 'calc:'),
      AppData(appName: 'Voice Memos', packageName: 'voicememos:'),
      AppData(appName: 'Compass', packageName: 'compass:'),
      AppData(appName: 'Measure', packageName: 'measure:'),
      AppData(appName: 'Health', packageName: 'x-apple-health:'),
      AppData(appName: 'Wallet', packageName: 'shoebox:'),
      AppData(appName: 'Find My', packageName: 'findmy:'),
      AppData(appName: 'Files', packageName: 'shareddocuments:'),
      AppData(appName: 'Shortcuts', packageName: 'shortcuts:'),

      // Popular third-party apps (if installed)
      AppData(appName: 'WhatsApp', packageName: 'whatsapp:'),
      AppData(appName: 'Telegram', packageName: 'tg:'),
      AppData(appName: 'Instagram', packageName: 'instagram:'),
      AppData(appName: 'Twitter/X', packageName: 'twitter:'),
      AppData(appName: 'Facebook', packageName: 'fb:'),
      AppData(appName: 'YouTube', packageName: 'youtube:'),
      AppData(appName: 'Gmail', packageName: 'googlegmail:'),
      AppData(appName: 'Google Maps', packageName: 'comgooglemaps:'),
      AppData(appName: 'Google Drive', packageName: 'googledrive:'),
      AppData(appName: 'Spotify', packageName: 'spotify:'),
      AppData(appName: 'Apple Music', packageName: 'music:'),
      AppData(appName: 'Netflix', packageName: 'nflx:'),
      AppData(appName: 'Amazon', packageName: 'amazon:'),
      AppData(appName: 'Uber', packageName: 'uber:'),
      AppData(appName: 'Lyft', packageName: 'lyft:'),
      AppData(appName: 'PayPal', packageName: 'paypal:'),
      AppData(appName: 'Venmo', packageName: 'venmo:'),
      AppData(appName: 'Zoom', packageName: 'zoomus:'),
      AppData(appName: 'Microsoft Teams', packageName: 'msteams:'),
      AppData(appName: 'Slack', packageName: 'slack:'),
      AppData(appName: 'Discord', packageName: 'discord:'),
      AppData(appName: 'TikTok', packageName: 'snssdk1233:'),
      AppData(appName: 'Snapchat', packageName: 'snapchat:'),
      AppData(appName: 'LinkedIn', packageName: 'linkedin:'),
      AppData(appName: 'Pinterest', packageName: 'pinterest:'),
      AppData(appName: 'Reddit', packageName: 'reddit:'),
      AppData(appName: 'Twitch', packageName: 'twitch:'),
      AppData(appName: 'Dropbox', packageName: 'dbapi-1:'),
      AppData(appName: 'OneDrive', packageName: 'ms-onedrive:'),
      AppData(appName: 'Adobe Creative Cloud', packageName: 'cc:'),
      AppData(appName: 'Evernote', packageName: 'evernote:'),
      AppData(appName: 'Notion', packageName: 'notion:'),
      AppData(appName: '1Password', packageName: 'onepassword:'),
      AppData(appName: 'LastPass', packageName: 'lastpass:'),
    ];

    // Sort alphabetically by app name
    _cachedApps.sort((a, b) => a.appName.compareTo(b.appName));

    return _cachedApps;
  }

  static List<AppData> searchApps(List<AppData> apps, String query) {
    if (query.isEmpty) return apps;

    final lowercaseQuery = query.toLowerCase();
    return apps
        .where((app) =>
            app.appName.toLowerCase().contains(lowercaseQuery) ||
            app.packageName.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  static bool isValidPackageName(String packageName) {
    if (packageName.isEmpty) return false;

    // Basic validation for Android package names
    if (Platform.isAndroid) {
      final regex =
          RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)*$');
      return regex.hasMatch(packageName);
    }

    // For iOS, accept URL schemes
    if (Platform.isIOS) {
      return packageName.contains(':');
    }

    return true;
  }

  static void clearCache() {
    _cachedApps.clear();
  }

  // Additional helper method to check if an app can be launched
  static Future<bool> canLaunchApp(String packageName) async {
    try {
      if (Platform.isAndroid) {
        // For Android, you can use url_launcher to check if the package can be launched
        // Return true for now, as installed_apps already filters launchable apps
        return packageName.isNotEmpty;
      } else if (Platform.isIOS) {
        // For iOS, you can use url_launcher's canLaunchUrl to check URL schemes
        return packageName.contains(':');
      }
      return false;
    } catch (e) {
      print('Error checking if app can be launched: $e');
      return false;
    }
  }

  // Method to get app with icon (if needed)
  static Future<List<AppData>> getInstalledAppsWithIcons() async {
    if (Platform.isAndroid) {
      try {
        final List<AppInfo> apps = await InstalledApps.getInstalledApps();

        return apps
            .where((app) => app.packageName.isNotEmpty && app.name.isNotEmpty)
            .map((app) => AppData(
                  appName: app.name,
                  packageName: app.packageName,
                  // You might need to add icon property to your AppData model
                  // icon: app.icon,
                ))
            .toList();
      } catch (e) {
        print('Error getting Android apps with icons: $e');
        return [];
      }
    }

    // For iOS, return the same list as icons are handled differently
    return await _getIOSApps();
  }
}
