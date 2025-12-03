import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/tesoro.dart';
import '../models/admin_model.dart';
import '../models/user.dart';
import 'login.dart';

/// Pantalla principal del Administrador.
///
/// Gestiona la navegación general, el Drawer lateral y mantiene la sesión
/// del usuario sincronizada con Firebase Firestore en tiempo real.
class AdminScreen extends StatefulWidget {
  final AdminModel adminUser;

  const AdminScreen({super.key, required this.adminUser});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  /// Cierra la sesión en Firebase Auth y redirige al Login limpiando la pila de navegación.
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) =>  Login()),
            (Route<dynamic> route) => false,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
    Navigator.pop(context); // Cierra el drawer al seleccionar
  }

  @override
  Widget build(BuildContext context) {
    // STREAMBUILDER: Escucha activa de cambios en el documento del admin.
    // Esto asegura que si se cambia la foto o el nombre, se actualice la UI automáticamente.
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.adminUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return  Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final currentAdmin = AdminModel.fromMap(data, widget.adminUser.uid);

        // Vistas disponibles para la navegación
        final List<Widget> _widgetOptions = <Widget>[
          TreasuresMapView(adminUid: currentAdmin.uid), // Mapa interactivo
          TreasuresListView(),                          // Lista CRUD simple
          UsersListView(),                              // Monitoreo de usuarios
          ProfileEditView(adminUser: currentAdmin),     // Edición de perfil
          AdminManualView(),                            // Ayuda estática
        ];

        final List<String> _titles = [
          'GEO HUNT - Mapa Admin',
          'Inventario de Tesoros',
          'Gestión de Exploradores',
          'Perfil Admin',
          'Manual de Usuario'
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _titles[_selectedIndex],
              style:  TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: [Shadow(blurRadius: 16, color: Colors.black54, offset: Offset(0, 4))],
              ),
            ),
            backgroundColor: const Color(0xFF91B1A8),
            elevation: 6,
            centerTitle: true,
          ),
          // Drawer para navegación principal
          drawer: Drawer(
            child: Container(
              decoration:  BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF91B1A8), Color(0xFF8992D7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration:  BoxDecoration(color: Colors.transparent),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.white,
                          // Carga condicional de imagen de perfil o inicial del nombre
                          backgroundImage: (currentAdmin.profileImageUrl != null && currentAdmin.profileImageUrl!.isNotEmpty)
                              ? NetworkImage(currentAdmin.profileImageUrl!)
                              : null,
                          child: (currentAdmin.profileImageUrl == null || currentAdmin.profileImageUrl!.isEmpty)
                              ? Text(
                            currentAdmin.username.isNotEmpty ? currentAdmin.username[0].toUpperCase() : 'A',
                            style:  TextStyle(fontSize: 32.0, color: Color(0xFF91B1A8)),
                          )
                              : null,
                        ),
                        SizedBox(height: 15),
                        Text(
                          currentAdmin.username,
                          style:  TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ListTile(leading:  Icon(Icons.map, color: Colors.white), title:  Text('Mapa y Rutas', style: TextStyle(color: Colors.white)), selected: _selectedIndex == 0, onTap: () => _onItemTapped(0)),
                  ListTile(leading:  Icon(Icons.diamond, color: Colors.white), title:  Text('Lista de Tesoros', style: TextStyle(color: Colors.white)), selected: _selectedIndex == 1, onTap: () => _onItemTapped(1)),
                  ListTile(leading:  Icon(Icons.people, color: Colors.white), title:  Text('Exploradores', style: TextStyle(color: Colors.white)), selected: _selectedIndex == 2, onTap: () => _onItemTapped(2)),
                  ListTile(leading:  Icon(Icons.person, color: Colors.white), title:  Text('Modificar Perfil', style: TextStyle(color: Colors.white)), selected: _selectedIndex == 3, onTap: () => _onItemTapped(3)),
                  Divider(color: Colors.white70),
                  ListTile(
                      leading:  Icon(Icons.menu_book, color: Color(0xFF8992D7)),
                      title:  Text('Manual de Usuario', style: TextStyle(color: Colors.white)),
                      selected: _selectedIndex == 4,
                      onTap: () => _onItemTapped(4)
                  ),
                  ListTile(leading:  Icon(Icons.logout, color: Colors.red), title:  Text('Cerrar Sesión', style: TextStyle(color: Colors.white)), onTap: _signOut),
                ],
              ),
            ),
          ),
          body: Container(
            decoration:  BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE6F2EF), Color(0xFF97AAA6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// VISTA 1: MAPA DE TESOROS
// Lógica principal de Geolocalización y Gestión Visual de Tesoros
// ---------------------------------------------------------------------------
class TreasuresMapView extends StatefulWidget {
  final String adminUid;
  const TreasuresMapView({super.key, required this.adminUid});

  @override
  State<TreasuresMapView> createState() => _TreasuresMapViewState();
}

class _TreasuresMapViewState extends State<TreasuresMapView> {
  final LatLng _tepicCenter = const LatLng(21.5114, -104.8947); // Coordenada base
  final MapController _mapController = MapController();
  final Distance _distanceCalculator =  Distance();

  bool _showRoutes = false; // Toggle para modo ruta
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  File? _selectedTreasureImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // IMPORTANTE: Cancelar stream para evitar fugas de memoria
    super.dispose();
  }

  /// Verifica y solicita permisos de ubicación en tiempo de ejecución.
  /// Si se otorga, inicia el stream de posición.
  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    _startListeningLocation();
  }

  /// Escucha cambios en la posición del GPS con alta precisión.
  void _startListeningLocation() {
    const LocationSettings locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((pos) {
      if (mounted) setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
    });
  }

  void _centerOnUser() {
    if (_currentPosition != null) _mapController.move(_currentPosition!, 16);
    else _checkLocationPermissions();
  }

  /// Algoritmo "Greedy" (Codicioso) para optimización de rutas.
  /// Calcula la ruta conectando siempre el tesoro más cercano al punto actual.
  /// 1. Filtra tesoros a 200m a la redonda.
  /// 2. Itera buscando el vecino más cercano no visitado.
  List<LatLng> _calculateOptimizedRoute(List<TreasureModel> allTreasures) {
    if (_currentPosition == null) return [];

    // Filtrado por radio de cercanía (optimización de rendimiento)
    List<TreasureModel> nearby = allTreasures.where((t) => _distanceCalculator.as(LengthUnit.Meter, _currentPosition!, LatLng(t.location.latitude, t.location.longitude)) <= 200).toList();
    if (nearby.isEmpty) return [];

    List<LatLng> path = [_currentPosition!];
    LatLng current = _currentPosition!;
    List<TreasureModel> pending = List.from(nearby);

    // Lógica del vecino más cercano
    while (pending.isNotEmpty) {
      TreasureModel? nearest;
      double minD = double.infinity;
      for (var t in pending) {
        double d = _distanceCalculator.as(LengthUnit.Meter, current, LatLng(t.location.latitude, t.location.longitude));
        if (d < minD) {
          minD = d;
          nearest = t;
        }
      }
      if (nearest != null) {
        LatLng p = LatLng(nearest.location.latitude, nearest.location.longitude);
        path.add(p);
        current = p;
        pending.remove(nearest);
      }
    }
    return path;
  }

  // --- LÓGICA DE IMAGEN DEL TESORO ---
  // Utiliza ImagePicker para seleccionar de galería
  Future<void> _pickTreasureImage(StateSetter setDialogState) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compresión para ahorrar datos
        maxWidth: 1024
    );

    if (image != null) {
      setDialogState(() {
        _selectedTreasureImage = File(image.path);
      });
    }
  }

  /// Sube la imagen seleccionada a Firebase Storage y retorna la URL pública.
  Future<String?> _uploadTreasureImage(File imageFile) async {
    try {
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final storageRef = FirebaseStorage.instance.ref().child('treasure_images').child(fileName);
      // Metadatos para caché y tipo
      await storageRef.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      return null;
    }
  }

  /// Diálogo principal para Crear o Editar Tesoros.
  /// Maneja validaciones de formulario, subida de imágenes y lógica de dificultad.
  void _showTreasureForm(BuildContext context, {LatLng? location, TreasureModel? treasureToEdit}) {
    final isEditing = treasureToEdit != null;
    final formKey = GlobalKey<FormState>();

    // Inicialización de controladores
    final titleController = TextEditingController(text: isEditing ? treasureToEdit.title : '');
    final descController = TextEditingController(text: isEditing ? treasureToEdit.description : '');
    String difficulty = isEditing ? treasureToEdit.difficulty : 'Medio';
    bool isLimited = isEditing ? treasureToEdit.isLimitedTime : false;

    _selectedTreasureImage = null;
    String? existingImageUrl = isEditing ? treasureToEdit.imageUrl : null;

    final LatLng finalLocation = isEditing
        ? LatLng(treasureToEdit.location.latitude, treasureToEdit.location.longitude)
        : (location ?? _tepicCenter);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder necesario para actualizar el estado DENTRO del diálogo (ej. switch o carga de imagen)
        builder: (context, setDialogState) {
          // Regla de negocio: No se permiten fotos en dificultad 'Difícil'
          bool canAddPhoto = (difficulty == 'Fácil' || difficulty == 'Medio');

          return AlertDialog.adaptive(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFFF2F5F4),
            elevation: 10,
            titlePadding: EdgeInsets.zero,
            contentPadding:  EdgeInsets.fromLTRB(24, 20, 24, 0),
            actionsPadding:  EdgeInsets.all(16.0),
            title: Container(
              padding:  EdgeInsets.all(20),
              decoration:  BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                gradient: LinearGradient(colors: [Color(0xFF91B1A8), Color(0xFF8992D7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Text(isEditing ? 'Editar Tesoro' : 'Nuevo Tesoro', style:  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Wrap(
                  runSpacing: 16,
                  children: [
                    Text('Ubicación: ${finalLocation.latitude.toStringAsFixed(5)}, ${finalLocation.longitude.toStringAsFixed(5)}', style:  TextStyle(fontSize: 12, color: Colors.grey)),
                    TextFormField(
                      controller: titleController,
                      decoration:  InputDecoration(labelText: 'Título'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: descController,
                      decoration:  InputDecoration(labelText: 'Descripción'),
                      maxLines: 2,
                    ),
                    // Dropdown para Dificultad
                    DropdownButtonFormField<String>(
                      initialValue: difficulty,
                      decoration:  InputDecoration(labelText: 'Dificultad'),
                      items: ['Fácil', 'Medio', 'Difícil'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setDialogState(() {
                        difficulty = v!;
                        // Si cambia a difícil, se descarta la imagen seleccionada
                        if (difficulty == 'Difícil') _selectedTreasureImage = null;
                      }),
                    ),
                    SwitchListTile(
                      title:  Text('Tiempo Limitado'),
                      value: isLimited,
                      onChanged: (v) => setDialogState(() => isLimited = v),
                    ),

                    // Lógica visual para carga de fotos condicionada
                    if (canAddPhoto) ...[
                      Divider(),
                      Text("Pista Visual (Opcional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      SizedBox(height: 10),

                      if (_selectedTreasureImage != null)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.file(_selectedTreasureImage!, height: 120, width: double.infinity, fit: BoxFit.cover),
                            IconButton(icon:  Icon(Icons.cancel, color: Colors.red), onPressed: () => setDialogState(() => _selectedTreasureImage = null)),
                          ],
                        )
                      else if (existingImageUrl != null)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.network(existingImageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
                            IconButton(icon:  Icon(Icons.delete, color: Colors.red), onPressed: () => setDialogState(() => existingImageUrl = null)),
                          ],
                        )
                      else
                        Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                          child: Center(child: TextButton.icon(icon:  Icon(Icons.add_photo_alternate), label:  Text("Agregar Foto"), onPressed: () => _pickTreasureImage(setDialogState))),
                        ),
                      Text("* Solo disponible en Fácil/Medio", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ] else
                      Text("🚫 Sin fotos en nivel Difícil", style: TextStyle(color: Colors.redAccent, fontSize: 12)),

                    if (_isUploadingImage)  Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                  icon:  Icon(Icons.cancel),
                  label:  Text('Cancelar'),
                  onPressed: () => Navigator.pop(ctx)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8992D7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isUploadingImage ? null : () async {
                  if (formKey.currentState!.validate()) {
                    setDialogState(() => _isUploadingImage = true);

                    // Subida de imagen a Storage si aplica
                    String? finalImageUrl = existingImageUrl;
                    if (_selectedTreasureImage != null && canAddPhoto) {
                      finalImageUrl = await _uploadTreasureImage(_selectedTreasureImage!);
                    }
                    if (!canAddPhoto) finalImageUrl = null;

                    try {
                      final now = DateTime.now();
                      DateTime? limitedUntil;

                      // Lógica de expiración del tesoro
                      if (isLimited) {
                        // Duración dinámica según dificultad
                        int minutes = 0;
                        switch (difficulty) {
                          case 'Fácil':
                            minutes = 4;
                            break;
                          case 'Medio':
                            minutes = 3;
                            break;
                          case 'Difícil':
                            minutes = 2;
                            break;
                        }
                        limitedUntil = now.add(Duration(minutes: minutes));
                      }

                      // Construcción del objeto para Firestore
                      final data = {
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'difficulty': difficulty,
                        'isLimitedTime': isLimited,
                        'location': GeoPoint(finalLocation.latitude, finalLocation.longitude),
                        'creatorUid': widget.adminUid,
                        'imageUrl': finalImageUrl,
                        "notificationSent": false,
                        if (!isEditing) 'creationDate': Timestamp.now(),
                        // Solo incluye el campo si está activo el tiempo limitado
                        if (isLimited && limitedUntil != null)
                          'limitedUntil': Timestamp.fromDate(limitedUntil),
                      };

                      // Guardado en Firestore
                      if (isEditing) {
                        await FirebaseFirestore.instance.collection('treasures').doc(treasureToEdit.id).update(data);
                      } else {
                        await FirebaseFirestore.instance.collection('treasures').add(data);
                      }

                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Actualizado' : 'Creado')));
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    } finally {
                      setDialogState(() => _isUploadingImage = false);
                    }
                  }
                },
                child: Text(isEditing ? 'Guardar' : 'Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTreasureDetails(TreasureModel t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        titlePadding: EdgeInsets.zero,
        contentPadding:  EdgeInsets.all(24),
        actionsPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Container(
          padding:  EdgeInsets.all(20),
          decoration:  BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            gradient: LinearGradient(colors: [Color(0xFF91B1A8), Color(0xFF8992D7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Text(t.title, style:  TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.description),
            SizedBox(height: 10),
            Row(
              children: [
                Chip(label: Text('Dificultad: ${t.difficulty}')),
                SizedBox(width: 8),
                if (t.isLimitedTime)  Chip(label: Text('Limitado'), backgroundColor: Colors.orangeAccent),
              ],
            ),
            if (t.imageUrl != null && t.imageUrl!.isNotEmpty)
              Padding(
                padding:  EdgeInsets.only(top: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(t.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>  Icon(Icons.broken_image, color: Colors.grey, size: 50)),
                ),
              ),
          ],
        ),
        actions: [
          TextButton.icon(
              icon:  Icon(Icons.edit),
              onPressed: () {
                Navigator.pop(ctx);
                _showTreasureForm(context, treasureToEdit: t);
              },
              label:  Text('Editar', style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF8992D7))),
          TextButton.icon(
              icon: Icon(Icons.delete_forever),
              label:  Text('Eliminar'),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('treasures').doc(t.id).delete();
                if(mounted) Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        // Barra de navegación inferior para cambiar entre Modo Mapa y Modo Ruta
        bottomNavigationBar: CurvedNavigationBar(
          index: _showRoutes ? 1 : 0,
          height: 60.0,
          items:  <Widget>[
            Icon(Icons.map, size: 30, color: Colors.white),
            Icon(Icons.alt_route, size: 30, color: Colors.white),
          ],
          color: const Color(0xFF91B1A8), // Color de fondo de la barra
          buttonBackgroundColor: const Color(0xFF8992D7), // Color del botón seleccionado
          backgroundColor: const Color(0xFFE6F2EF), // Color de fondo del Scaffold
          animationCurve: Curves.easeInOut,
          animationDuration:  Duration(milliseconds: 400),
          onTap: (index) {
            if (index == 1 && _currentPosition == null) {
              ScaffoldMessenger.of(context).showSnackBar( SnackBar(
                  content: Text('Activa el GPS para calcular la ruta'),
                  backgroundColor: Colors.orangeAccent));
            }
            setState(() => _showRoutes = (index == 1));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _centerOnUser,
          child:  Icon(Icons.my_location, color: Colors.blueAccent),
        ),
        body: Stack(
          children: [
            // StreamBuilder: Dibuja marcadores en tiempo real desde Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('treasures').snapshots(),
              builder: (context, snapshot) {
                List<Marker> markers = [];
                List<LatLng> routePoints = [];

                if (snapshot.hasData) {
                  final allTreasures = snapshot.data!.docs.map((d) => TreasureModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

                  markers = allTreasures.map((t) => Marker(
                    point: LatLng(t.location.latitude, t.location.longitude),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _showTreasureDetails(t),
                      child:  Icon(Icons.location_on, color: Colors.red, size: 50),
                    ),
                  )).toList();

                  // Cálculo de ruta solo si está activo el modo y hay posición GPS
                  if (_showRoutes && _currentPosition != null) {
                    routePoints = _calculateOptimizedRoute(allTreasures);
                  }
                }

                if (_currentPosition != null) {
                  markers.add(Marker(point: _currentPosition!, width: 50, height: 50, child:  Icon(Icons.person_pin_circle, color: Colors.blue, size: 40)));
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: _tepicCenter, initialZoom: 14, onTap: (_, p) => _showTreasureForm(context, location: p)),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.geohunt.app'),
                    // Capas opcionales de ruta
                    if (_showRoutes && _currentPosition != null)
                      CircleLayer(circles: [CircleMarker(point: _currentPosition!, radius: 200, useRadiusInMeter: true, color: Colors.blue.withOpacity(0.1), borderColor: Colors.blue, borderStrokeWidth: 1)]),
                    if (routePoints.isNotEmpty)
                      PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 5, color: Colors.deepPurpleAccent, isDotted: true)]),
                    MarkerLayer(markers: markers),
                  ],
                );
              },
            ),
            if (_showRoutes)
              Positioned(top: 10, right: 10, child: Container(padding:  EdgeInsets.all(8), color: Colors.white70, child:  Text("Modo Ruta Activo", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 2. VISTA DE LISTA DE TESOROS CON FOTO
// Vista alternativa al mapa para gestión rápida de inventario.
// =============================================================================
class TreasuresListView extends StatelessWidget {
  const TreasuresListView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('treasures').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return  Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return  Center(child: Text('No hay tesoros'));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final t = TreasureModel.fromMap(snapshot.data!.docs[index].data() as Map<String, dynamic>, snapshot.data!.docs[index].id);
            return Card(
              margin:  EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color:  Color(0xFFE6F2EF),
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: t.imageUrl != null
                    ? CircleAvatar(backgroundImage: NetworkImage(t.imageUrl!), radius: 28)
                    :  CircleAvatar(child: Icon(Icons.diamond), radius: 28),
                title: Text(t.title, style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(t.difficulty, style:  TextStyle(color: Color(0xFF8992D7), fontWeight: FontWeight.w500)),
                trailing: IconButton(
                  icon:  Icon(Icons.delete, color: Colors.red),
                  onPressed: () => FirebaseFirestore.instance.collection('treasures').doc(t.id).delete(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// 3. VISTA DE GESTIÓN DE USUARIOS
// Permite al admin ver los exploradores registrados y sus puntajes.
// =============================================================================
class UsersListView extends StatelessWidget {
  const UsersListView({super.key});

  void _showUserDetails(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        titlePadding: EdgeInsets.zero,
        contentPadding:  EdgeInsets.fromLTRB(24, 20, 24, 24),
        actionsPadding:  EdgeInsets.only(right: 16, bottom: 8),
        title: Container(
            padding:  EdgeInsets.all(20),
            decoration:  BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              gradient: LinearGradient(colors: [Color(0xFF91B1A8), Color(0xFF8992D7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Row(children: [
              CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white12,
                  backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                  child: user.profileImageUrl == null ?  Icon(Icons.person, color: Color(0xFF91B1A8), size: 30) : null),
              SizedBox(width: 12),
              Expanded(child: Text(user.username, style:  TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22)))
            ])),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(leading:  Icon(Icons.email_outlined, color: Color(0xFF8992D7)), title:  Text('Email'), subtitle: Text(user.email ?? 'No disponible'), dense: true),
              ListTile(leading:  Icon(Icons.phone_outlined, color: Color(0xFF8992D7)), title:  Text('Teléfono'), subtitle: Text(user.phoneNumber ?? "No especificado"), dense: true),
              Divider(height: 25, thickness: 1),
              ListTile(leading:  Icon(Icons.star_border, color: Colors.amber), title:  Text('Puntaje'), subtitle: Text('${user.score} pts', style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), dense: true),
              ListTile(leading:  Icon(Icons.diamond_outlined, color: Colors.teal), title:  Text('Tesoros Hallados'), subtitle: Text('${user.foundTreasures?.length ?? 0}'), dense: true),
            ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child:  Text('CERRAR', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8992D7))))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FILTRO: Solo muestra usuarios con rol 'user', ignorando otros admins.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return  Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return  Center(child: Text('No hay exploradores registrados.'));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final user = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            return Card(
              margin:  EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color:  Color(0xFFE6F2EF),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:  Color(0xFF91B1A8),
                  backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                  child: user.profileImageUrl == null ? Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?', style:  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                  radius: 28,
                ),
                title: Text(user.username, style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(user.email ?? 'Sin correo', style:  TextStyle(color: Color(0xFF8992D7))),
                trailing: Container(
                  padding:  EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF8992D7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${user.score} pts', style:  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                onTap: () => _showUserDetails(context, user),
              ),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// 4. VISTA DE PERFIL ADMIN
// Permite actualizar datos personales e imagen de perfil del Admin.
// =============================================================================
class ProfileEditView extends StatefulWidget {
  final AdminModel adminUser;
  const ProfileEditView({super.key, required this.adminUser});
  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.adminUser.username);
    _phoneController = TextEditingController(text: widget.adminUser.phoneNumber ?? '');
    _currentImageUrl = widget.adminUser.profileImageUrl;
  }

  // Actualiza los campos si el widget padre envía nuevos datos (Reactividad)
  @override
  void didUpdateWidget(covariant ProfileEditView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adminUser != widget.adminUser) {
      _usernameController.text = widget.adminUser.username;
      _phoneController.text = widget.adminUser.phoneNumber ?? '';
      _currentImageUrl = widget.adminUser.profileImageUrl;
    }
  }

  void _showSelectionDialog() {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Wrap(children: [
      ListTile(leading:  Icon(Icons.photo_library), title:  Text('Galería'), onTap: () { Navigator.pop(ctx); _checkPermissionAndPick(ImageSource.gallery); }),
      ListTile(leading:  Icon(Icons.photo_camera), title:  Text('Cámara'), onTap: () { Navigator.pop(ctx); _checkPermissionAndPick(ImageSource.camera); }),
    ])));
  }

  // Manejo robusto de permisos para Android (Galería vs Almacenamiento)
  Future<void> _checkPermissionAndPick(ImageSource source) async {
    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      status = Platform.isAndroid ? await Permission.photos.request() : await Permission.photos.request();
      // Fallback para versiones antiguas de Android
      if (Platform.isAndroid && (status.isPermanentlyDenied || status.isDenied)) status = await Permission.storage.request();
    }

    if (status.isGranted || status.isLimited) {
      _pickAndUploadImage(source);
    } else if (status.isPermanentlyDenied) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Habilita permisos en ajustes'), action: SnackBarAction(label: 'Ir', onPressed: openAppSettings)));
    }
  }

  // Flujo completo: Seleccionar -> Subir Storage -> Obtener URL -> Actualizar Firestore
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source, imageQuality: 60, maxWidth: 512);
      if (image == null) return;

      setState(() => _isLoading = true);

      final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${widget.adminUser.uid}.jpg');
      await storageRef.putFile(File(image.path), SettableMetadata(contentType: 'image/jpeg'));
      final String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(widget.adminUser.uid).update({'profileImageUrl': downloadUrl});

      if(mounted) ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Imagen actualizada')));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.adminUser.uid).update({
        'username': _usernameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Actualizado')));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration:  BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE6F2EF), Color(0xFF97AAA6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        SingleChildScrollView(
          padding:  EdgeInsets.all(24),
          child: Column(
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _showSelectionDialog,
                child: CircleAvatar(
                  radius: 62,
                  backgroundColor: const Color(0xFF91B1A8),
                  backgroundImage: (_currentImageUrl != null) ? NetworkImage(_currentImageUrl!) : null,
                  child: _currentImageUrl == null ?  Icon(Icons.person, size: 70, color: Colors.white) : null,
                ),
              ),
              SizedBox(height: 22),
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding:  EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        enabled: false,
                        controller: TextEditingController(text: widget.adminUser.email),
                        decoration: InputDecoration(
                          labelText: 'Correo',
                          prefixIcon:  Icon(Icons.email, color: Color(0xFF8992D7)),
                          filled: true,
                          fillColor: Color(0xFFE6F2EF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon:  Icon(Icons.person, color: Color(0xFF91B1A8)),
                          filled: true,
                          fillColor: Color(0xFFE6F2EF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8992D7)), borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon:  Icon(Icons.phone, color: Color(0xFF91B1A8)),
                          filled: true,
                          fillColor: Color(0xFFE6F2EF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8992D7)), borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8992D7),
                            foregroundColor: Colors.white,
                            padding:  EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle:  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          onPressed: _isLoading ? null : _updateProfile,
                          child:  Text('Guardar Cambios'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 5. MANUAL DE USUARIO
// =============================================================================
class AdminManualView extends StatelessWidget {
  const AdminManualView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding:  EdgeInsets.all(16),
      children:  [
        ListTile(leading: Icon(Icons.map), title: Text("1. Mapa"), subtitle: Text("Toca para crear. Si es Fácil/Medio, añade foto.")),
        ListTile(leading: Icon(Icons.alt_route), title: Text("2. Rutas"), subtitle: Text("Activa 'Ruta' para ver el camino óptimo.")),
        ListTile(leading: Icon(Icons.people), title: Text("3. Usuarios"), subtitle: Text("Gestiona exploradores.")),
        ListTile(leading: Icon(Icons.person), title: Text("4. Perfil"), subtitle: Text("Actualiza tu foto.")),
      ],
    );
  }
}