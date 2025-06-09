// lib/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'home_page.dart'; // Ana sayfanız

class SplashScreen extends StatefulWidget {
  final bool navigateToHome;
  final Duration duration;

  const SplashScreen({
    super.key,
    this.navigateToHome = true,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.navigateToHome) {
      _timer = Timer(widget.duration, () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.navigateToHome) {
      _timer?.cancel();
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını alalım
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        // Arka plan rengini resminize uygun bir renkle değiştirebilirsiniz
        // veya resmi tam ekran kaplatacaksanız bu renk görünmeyebilir.
        backgroundColor: Colors.black, // Örneğin siyah bir arka plan deneyebiliriz
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Resmi Gösterme
              Container(
                // Resim için bir boyut belirleyelim, ekran genişliğinin bir kısmı olabilir
                // Veya sabit bir boyut verebilirsiniz.
                width: screenWidth * 0.8, // Ekran genişliğinin %80'i
                // height: screenHeight * 0.4, // Yüksekliği de orantılı veya sabit ayarlayabilirsiniz
                constraints: BoxConstraints( // Maksimum yükseklik de verelim ki çok uzamasın
                  maxHeight: screenHeight * 0.5,
                ),
                decoration: BoxDecoration(
                  // İsteğe bağlı: Resme gölge ekleyebiliriz
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3), // Gölgenin pozisyonu
                    ),
                  ],
                  // İsteğe bağlı: Resmin köşelerini yuvarlayabiliriz
                  // borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect( // Eğer borderRadius kullanırsanız, resmi de kırpmak için ClipRRect
                  // borderRadius: BorderRadius.circular(15), // Yukarıdaki ile aynı olmalı
                  child: Image.asset(
                    'assets/image/hot.jpg', // Resmin yolu
                    fit: BoxFit.contain, // Resmin tamamını göster, orantıyı koru
                                        // BoxFit.cover da deneyebilirsiniz, alanı kaplar ama kırpabilir.
                    errorBuilder: (context, error, stackTrace) {
                      // Resim yüklenemezse gösterilecek widget
                      return const Icon(
                        Icons.image_not_supported_rounded,
                        size: 100,
                        color: Colors.white70,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30), // Resim ve yazı arasına boşluk
              Text(
                'Hot Wheels Katalog',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white, // Yazı rengi
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      // İsteğe bağlı: Yazıya da gölge
                      // shadows: [
                      //   Shadow(
                      //     blurRadius: 5.0,
                      //     color: Colors.black.withOpacity(0.5),
                      //     offset: Offset(1.0, 1.0),
                      //   ),
                      // ],
                    ),
              ),
              const SizedBox(height: 15),
              if (widget.navigateToHome && widget.duration > Duration.zero)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                  ),
                ),
              if (!widget.navigateToHome)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    children: [
                      Text(
                        'Bu uygulama bir Hot Wheels koleksiyonu takip aracıdır.\n\nGeliştirici: Murat Kuru instagram: muratdukkan\n\nSosyal Medyadan takip edebilirsiniz.\nYorumlarınız ile destek olabilirseniz programı beraber geliştirebiliriz.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '(Kapatmak için ekrana dokunun)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}