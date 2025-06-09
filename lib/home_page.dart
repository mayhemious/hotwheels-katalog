// lib/home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FilteringTextInputFormatter için
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'car_model.dart';
import 'splash_screen.dart'; // SplashScreen importu

enum SortOption { byNameAsc, byNameDesc, byDateAsc, byDateDesc }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Car> _addedCars = [];
  List<Car> _filteredCars = []; // Arama ve filtre sonuçlarını tutacak liste

  final TextEditingController _carNameController = TextEditingController();
  final TextEditingController _carCodeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Kategori seçimi için state değişkenleri
  CarCategory1 _selectedCategory1 = CarCategory1.undefined;
  CarCategory2 _selectedCategory2 = CarCategory2.regular;

  // Arama ve filtreleme için state değişkenleri
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";
  CarCategory1? _filterCategory1;
  CarCategory2? _filterCategory2;

  SortOption _currentSortOption = SortOption.byDateDesc; // Varsayılan sıralama

  @override
  void initState() {
    super.initState();
    _loadCars().then((_) {
      _applyFiltersAndSearch(); // Arabalar yüklendikten sonra filtreleri ve sıralamayı uygula
    });
    _searchController.addListener(() {
      // Listener içinde setState çağırmak yerine, değeri alıp applyFiltersAndSearch içinde setState çağırıyoruz
      // Bu, gereksiz rebuild'leri önleyebilir.
      if (_searchTerm != _searchController.text) {
        _searchTerm = _searchController.text;
        _applyFiltersAndSearch();
      }
    });
  }

  @override
  void dispose() {
    _carNameController.dispose();
    _carCodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Veri Kaydetme ve Yükleme ---
  Future<void> _saveCars() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> carsJsonList = _addedCars.map((car) => car.toJson()).toList();
    await prefs.setStringList('hotwheels_cars', carsJsonList);
    print("Arabalar kaydedildi!");
  }

  Future<void> _loadCars() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? carsJsonList = prefs.getStringList('hotwheels_cars');
    if (carsJsonList != null && carsJsonList.isNotEmpty) {
      final loadedCars = carsJsonList.map((carJson) => Car.fromJson(carJson)).toList();
      // setState burada çağrılmıyor, _applyFiltersAndSearch içinde çağrılacak
      _addedCars.clear();
      _addedCars.addAll(loadedCars);
      print("Arabalar yüklendi: ${_addedCars.length} adet");
    } else {
      _addedCars.clear(); // Eğer kayıt yoksa listeyi boşalt
      print("Kaydedilmiş araba bulunamadı.");
    }
    // _applyFiltersAndSearch(); // initState'teki .then bloğuna taşındı
  }

  // --- Fotoğraf İşlemleri ---
  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      return result.isGranted;
    }
  }

  Future<bool> _requestGalleryPermissionAndroid13Plus() async {
    // Android 13 (API 33) ve üzeri için Permission.photos
    // Android 12 (API 32) ve altı için Permission.storage
    // Bu kontrol için device_info_plus paketi kullanılıyor
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return await _requestPermission(Permission.photos);
      } else {
        return await _requestPermission(Permission.storage);
      }
    }
    return false; // Diğer platformlar için şimdilik false
  }


  Future<String?> _processAndSaveImage(String filePath) async {
    try {
      final File originalFile = File(filePath);
      final img.Image? image = img.decodeImage(await originalFile.readAsBytes());
      if (image == null) return null;
      img.Image resizedImage = (image.width > 800) ? img.copyResize(image, width: 800) : image;
      final List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 70);
      final Directory directory = await getApplicationDocumentsDirectory();
      final String fileName = 'hw_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newPath = '${directory.path}/$fileName';
      await File(newPath).writeAsBytes(compressedBytes);
      return newPath;
    } catch (e) {
      print('Fotoğraf işleme hatası: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fotoğraf işlenemedi: $e')));
      return null;
    }
  }

  Future<String?> _pickImage(ImageSource source, BuildContext dialogContext) async {
    bool permissionGranted = false;
    if (source == ImageSource.camera) {
      permissionGranted = await _requestPermission(Permission.camera);
    } else {
      if (Platform.isAndroid) {
        permissionGranted = await _requestGalleryPermissionAndroid13Plus();
      } else if (Platform.isIOS) {
        permissionGranted = await _requestPermission(Permission.photos);
      }
    }

    if (!permissionGranted) {
      if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Gerekli izinler verilmedi.')));
      return null;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) return await _processAndSaveImage(pickedFile.path);
    } catch (e) {
      if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Fotoğraf seçilemedi: $e')));
    }
    return null;
  }

  // --- Araba Ekleme, Silme, Sıralama, Filtreleme ---
  Future<void> _showAddCarDialog() async {
    _carNameController.clear();
    _carCodeController.clear();
    String? tempImagePath;
    _selectedCategory1 = CarCategory1.undefined;
    _selectedCategory2 = CarCategory2.regular;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Yeni Araba Bilgisi', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Araba Adı:', style: Theme.of(context).textTheme.bodyMedium),
                    TextField(controller: _carNameController, autofocus: true, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(hintText: 'Örn: TOYOTA SUPRA', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0)), prefixIcon: Icon(Icons.label_important_outline_rounded, color: Theme.of(context).colorScheme.secondary)), textInputAction: TextInputAction.next),
                    const SizedBox(height: 16),
                    Text('Kutunun Arkasında KIRMIZI yazan Kod:', style: Theme.of(context).textTheme.bodyMedium),
                    TextField(controller: _carCodeController, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(hintText: 'Örn: CFH90', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0)), prefixIcon: Icon(Icons.qr_code_scanner_rounded, color: Theme.of(context).colorScheme.secondary)), textInputAction: TextInputAction.done, onSubmitted: (_) => _addCarToList(dialogContext, tempImagePath, _selectedCategory1, _selectedCategory2)),
                    const SizedBox(height: 20),
                    Text('Fotoğraf Ekle (Opsiyonel):', style: Theme.of(context).textTheme.bodyMedium),
                    if (tempImagePath == null)
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        ElevatedButton.icon(icon: const Icon(Icons.camera_alt_rounded), label: const Text('Kamera'), onPressed: () async { final path = await _pickImage(ImageSource.camera, dialogContext); if (path != null) setDialogState(() => tempImagePath = path); }),
                        ElevatedButton.icon(icon: const Icon(Icons.photo_library_rounded), label: const Text('Galeri'), onPressed: () async { final path = await _pickImage(ImageSource.gallery, dialogContext); if (path != null) setDialogState(() => tempImagePath = path); }),
                      ])
                    else ...[
                      Stack(alignment: Alignment.topRight, children: [
                        ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.file(File(tempImagePath!), height: 120, width: double.infinity, fit: BoxFit.contain, errorBuilder: (ctx, err, st) => const Center(child: Text("Önizleme yok")))),
                        IconButton(icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 18)), onPressed: () => setDialogState(() => tempImagePath = null)),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    Text('Aracın Cinsi:', style: Theme.of(context).textTheme.titleMedium),
                    Wrap(spacing: 4.0, runSpacing: 0.0, children: CarCategory1.values.map((category) => ChoiceChip(label: Text(Car(id: '', name: '', code: '', createdAt: DateTime.now(), category1: category).category1DisplayName), selected: _selectedCategory1 == category, onSelected: (bool selected) => setDialogState(() { if (selected) _selectedCategory1 = category; }), selectedColor: Theme.of(context).colorScheme.primaryContainer, labelStyle: TextStyle(color: _selectedCategory1 == category ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface))).toList()),
                    const SizedBox(height: 16),
                    Text('Treasure Hunt:', style: Theme.of(context).textTheme.titleMedium),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: CarCategory2.values.map((category) => ChoiceChip(label: Text(Car(id: '', name: '', code: '', createdAt: DateTime.now(),category2: category).category2DisplayName), selected: _selectedCategory2 == category, onSelected: (bool selected) => setDialogState(() { if (selected) _selectedCategory2 = category; }), selectedColor: Theme.of(context).colorScheme.secondaryContainer, labelStyle: TextStyle(color: _selectedCategory2 == category ? Theme.of(context).colorScheme.onSecondaryContainer : Theme.of(context).colorScheme.onSurface))).toList()),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(child: Text('İptal', style: TextStyle(color: Theme.of(context).colorScheme.error)), onPressed: () => Navigator.of(dialogContext).pop()),
                ElevatedButton(onPressed: () => _addCarToList(dialogContext, tempImagePath, _selectedCategory1, _selectedCategory2), child: const Text('Ekle')),
              ],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            );
          },
        );
      },
    );
  }

  void _addCarToList(BuildContext dialogContext, String? imagePath, CarCategory1 cat1, CarCategory2 cat2) {
    final String name = _carNameController.text.trim();
    final String code = _carCodeController.text.trim(); // textCapitalization zaten büyük harf yapıyor

    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: const Text('Lütfen hem araba adını hem de kodu girin.'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    if (_addedCars.any((car) => car.code == code)) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Bu kod ($code) zaten kullanımda.'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }

    final newCar = Car(id: code, name: name, code: code, imagePath: imagePath, createdAt: DateTime.now(), category1: cat1, category2: cat2);
    
    _addedCars.add(newCar);
    _saveCars();
    _applyFiltersAndSearch(); // Ekleme sonrası listeyi ve filtreleri güncelle

    Navigator.of(dialogContext).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${newCar.name} (${newCar.code}) eklendi!'), backgroundColor: Theme.of(context).colorScheme.primary));
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, Car carToDelete) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Araba Sil'),
          content: Text('"${carToDelete.name}" adlı arabayı silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(child: const Text('İptal'), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error), child: const Text('Sil'), onPressed: () { _deleteCar(carToDelete); Navigator.of(dialogContext).pop(); }),
          ],
        );
      },
    );
  }

  void _deleteCar(Car carToDelete) {
    _addedCars.removeWhere((car) => car.id == carToDelete.id);
    _saveCars();
    _applyFiltersAndSearch(); // Silme sonrası listeyi ve filtreleri güncelle

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${carToDelete.name} silindi.'), backgroundColor: Theme.of(context).colorScheme.error));
  }

  void _sortCars(SortOption option) {
    _currentSortOption = option; // Kullanıcının seçtiği sıralamayı sakla
    _applyFiltersAndSearch(); // Filtreleri uygula, bu fonksiyon içinde sıralama da yapılacak
  }

  void _applyFiltersAndSearch() {
    List<Car> tempFilteredCars = List.from(_addedCars);

    if (_filterCategory1 != null && _filterCategory1 != CarCategory1.undefined) {
      tempFilteredCars = tempFilteredCars.where((car) => car.category1 == _filterCategory1).toList();
    }
    if (_filterCategory2 != null) {
      tempFilteredCars = tempFilteredCars.where((car) => car.category2 == _filterCategory2).toList();
    }
    if (_searchTerm.isNotEmpty) {
      String lowerSearchTerm = _searchTerm.toLowerCase();
      tempFilteredCars = tempFilteredCars.where((car) => car.name.toLowerCase().contains(lowerSearchTerm) || car.code.toLowerCase().contains(lowerSearchTerm)).toList();
    }

    // Sıralamayı burada uygula
    switch (_currentSortOption) {
      case SortOption.byNameAsc:
        tempFilteredCars.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.byNameDesc:
        tempFilteredCars.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOption.byDateAsc:
        tempFilteredCars.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.byDateDesc:
        tempFilteredCars.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    setState(() {
      _filteredCars = tempFilteredCars;
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hot Wheels Koleksiyonum'),
        actions: <Widget>[
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: "Sırala",
            initialValue: _currentSortOption,
            onSelected: (SortOption result) => _sortCars(result),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(value: SortOption.byNameAsc, child: Text('İsme Göre (A-Z)')),
              const PopupMenuItem<SortOption>(value: SortOption.byNameDesc, child: Text('İsme Göre (Z-A)')),
              const PopupMenuDivider(),
              const PopupMenuItem<SortOption>(value: SortOption.byDateDesc, child: Text('Tarihe Göre (Yeni-Eski)')),
              const PopupMenuItem<SortOption>(value: SortOption.byDateAsc, child: Text('Tarihe Göre (Eski-Yeni)')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: "Diğer",
            onSelected: (String result) {
              if (result == 'about') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SplashScreen(navigateToHome: false, duration: Duration.zero)));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'about', child: Text('Hakkında')),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'İsim veya Kod ile Ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    suffixIcon: _searchTerm.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear()) : null,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<CarCategory1?>(
                        decoration: InputDecoration(labelText: 'Aracın Cinsi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        value: _filterCategory1,
                        items: [
                          const DropdownMenuItem<CarCategory1?>(value: null, child: Text('Tümü')),
                          ...CarCategory1.values.map((cat) => DropdownMenuItem<CarCategory1?>(value: cat, child: Text(Car(id: '', name: '', code: '', createdAt: DateTime.now(), category1: cat).category1DisplayName))).toList(),
                        ],
                        onChanged: (val) => setState(() { _filterCategory1 = val; _applyFiltersAndSearch(); }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<CarCategory2?>(
                        decoration: InputDecoration(labelText: 'Treasure Hunt', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        value: _filterCategory2,
                        items: [
                          const DropdownMenuItem<CarCategory2?>(value: null, child: Text('Tümü')),
                          ...CarCategory2.values.map((cat) => DropdownMenuItem<CarCategory2?>(value: cat, child: Text(Car(id: '', name: '', code: '', createdAt: DateTime.now(), category2: cat).category2DisplayName))).toList(),
                        ],
                        onChanged: (val) => setState(() { _filterCategory2 = val; _applyFiltersAndSearch(); }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Buton için padding ayarlandı
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
              label: const Text('Yeni Araba Ekle'),
              onPressed: _showAddCarDialog,
            ),
          ),
          Expanded(
            child: _filteredCars.isEmpty && (_searchTerm.isNotEmpty || _filterCategory1 != null || _filterCategory2 != null)
                ? Center(child: Text('Bu kriterlere uygun araba bulunamadı.', style: theme.textTheme.titleMedium, textAlign: TextAlign.center))
                : _filteredCars.isEmpty && _addedCars.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.directions_car_filled_rounded, size: 80, color: colorScheme.secondary.withOpacity(0.7)),
                          const SizedBox(height: 16),
                          Text('Henüz araba eklenmemiş!', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8))),
                          const SizedBox(height: 8),
                          Text('Yukarıdaki butona tıklayarak koleksiyonunu oluşturmaya başla.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        ]),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.60), // Aspect ratio ayarlandı
                        itemCount: _filteredCars.length,
                        itemBuilder: (context, index) {
                          final car = _filteredCars[index];
                          return InkWell(
                            onLongPress: () => _showDeleteConfirmationDialog(context, car),
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: car.imagePath != null && car.imagePath!.isNotEmpty
                                        ? Image.file(File(car.imagePath!), fit: BoxFit.cover, errorBuilder: (ctx, err, st) => Container(color: Colors.grey[300], child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey[600])))
                                        : Container(color: colorScheme.surfaceVariant.withOpacity(0.5), child: Icon(Icons.no_photography_rounded, size: 50, color: colorScheme.onSurfaceVariant.withOpacity(0.5))),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Text(car.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text('Kod: ${car.code}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text('${car.category1DisplayName} / ${car.category2DisplayName}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}