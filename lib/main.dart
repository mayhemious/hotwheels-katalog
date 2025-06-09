import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts paketini import ediyoruz
import 'home_page.dart'; // Ana sayfamız
import 'splash_screen.dart'; // Splash ekranını import et

void main() {
  runApp(const HotWheelsCatalogApp());
}

// ... (önceki importlar ve kodlar) ...

class HotWheelsCatalogApp extends StatelessWidget {
  const HotWheelsCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Temel metin temasını alıyoruz, üzerine Google Fonts uygulayacağız
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'Hot Wheels Katalog',
      debugShowCheckedModeBanner: false, // Debug banner'ını kaldırır
      theme: ThemeData(
        useMaterial3: true, // Modern Material 3 bileşenlerini kullan
        brightness: Brightness.light, // Açık tema

        // RENK PALETİ
        primaryColor: const Color(0xFFFF6F00),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6F00),
          primary: const Color(0xFFFF6F00),
          onPrimary: Colors.white,
          secondary: const Color(0xFF007BFF),
          onSecondary: Colors.white,
          error: const Color(0xFFD32F2F),
          onError: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF333333),
          background: const Color(0xFFF5F5F5),
          onBackground: const Color(0xFF333333),
        ),

        // FONT AİLESİ ve METİN STİLLERİ
        fontFamily: GoogleFonts.nunito().fontFamily,
        textTheme: GoogleFonts.nunitoTextTheme(textTheme).copyWith(
          displayLarge: GoogleFonts.bangers(
              textStyle: textTheme.displayLarge
                  ?.copyWith(color: const Color(0xFFFF6F00), letterSpacing: 1.5, fontSize: 50)),
          displayMedium: GoogleFonts.bangers(
              textStyle: textTheme.displayMedium
                  ?.copyWith(color: const Color(0xFFFF6F00), letterSpacing: 1.2, fontSize: 42)),
          displaySmall: GoogleFonts.bangers(
              textStyle: textTheme.displaySmall
                  ?.copyWith(color: const Color(0xFFFF6F00), letterSpacing: 1.0, fontSize: 34)),
          headlineMedium: GoogleFonts.bangers(
              textStyle: textTheme.headlineMedium
                  ?.copyWith(color: Colors.white, fontSize: 28, letterSpacing: 1.2)),
          headlineSmall: GoogleFonts.bangers(
              textStyle: textTheme.headlineSmall
                  ?.copyWith(color: const Color(0xFF007BFF), fontSize: 26, letterSpacing: 1.0)),
          titleLarge: GoogleFonts.nunito(
              textStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
          titleMedium: GoogleFonts.nunito(
              textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
          bodyLarge: GoogleFonts.nunito(textStyle: textTheme.bodyLarge?.copyWith(fontSize: 16)),
          bodyMedium: GoogleFonts.nunito(textStyle: textTheme.bodyMedium?.copyWith(fontSize: 14)),
          labelLarge: GoogleFonts.nunito(
              textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
        ),

        // APPBAR TEMASI
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFFF6F00),
          foregroundColor: Colors.white,
          elevation: 4.0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.bangers(
            fontSize: 28,
            fontWeight: FontWeight.normal,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),

        // ELEVATED BUTTON TEMASI
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007BFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 3,
          ),
        ),

        // CARD TEMASI - BURASI DÜZELTİLDİ
        cardTheme: CardThemeData( // CardTheme -> CardThemeData olarak değiştirildi
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),

        // ICON TEMASI
        iconTheme: const IconThemeData(
          color: Color(0xFF007BFF),
          size: 28,
        ),

        // SAYFA GEÇİŞ ANİMASYONLARI
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashScreen(), // Başlangıçta SplashScreen'i göster
    );
  }
}