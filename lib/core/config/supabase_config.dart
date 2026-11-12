import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  /// URL Project Supabase resmi
  static const String supabaseUrl = "https://oztpzkaxpiupwrosgquq.supabase.co";

  /// Publishable Key resmi (Aman dipakai di client/web dengan perlindungan RLS)
  static const String publishableKey = "sb_publishable_wLPt5v_Pz3UUMESwhwNJXQ_vo5HUlnM";

  /// Flag penanda apakah Supabase aktif terhubung
  static bool isConfigured = false;

  /// Inisialisasi Supabase SDK
  static Future<void> initialize({String? customUrl}) async {
    final url = customUrl ?? supabaseUrl;
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: publishableKey,
      );
      isConfigured = true;
    } catch (e) {
      // Menangani error inisialisasi jika URL belum terkonfigurasi di server
      isConfigured = false;
    }
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}

