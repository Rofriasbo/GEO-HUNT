import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import '../services/database_service.dart';
import '../services/fcm_service.dart';

import 'login.dart';
import '../services/notificaciones.dart';
import '../models/user.dart';
import '../models/tesoro.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// Paleta de colores global para mantener consistencia visual
const Color primaryColor = Color(0xFF91B1A8);
const Color backgroundColor = Color(0xFF97AAA6);
const Color secondaryColor = Color(0xFF8992D7);
const Color accentColor = Color(0xFF8CB9AC);
const Color cardColor = Color(0xFFE6F2EF);

// Pantalla Principal del Usuario (Dashboard).
//
// Contiene la barra de navegación curva y gestiona las 3 vistas principales:
// 1. Mapa (Caza).
// 2. Leaderboard (Ranking).
// 3. Perfil.
class WelcomeScreen extends StatefulWidget {
  final String username;
  const WelcomeScreen({super.key, required this.username});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  int _selectedIndex = 0;
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  // Guarda el Token FCM para notificaciones push y la última ubicación conocida.
  // Esto permite al servidor enviar alertas de "Tesoro Cerca" incluso si la app está cerrada.
  Future<void> saveFCMTokenAndLocation(String uid) async {
    final DatabaseService dbService = DatabaseService();

    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await dbService.updateUser(uid, {'fcmToken': token});
    }
    Position position = await Geolocator.getCurrentPosition();
    GeoPoint location = GeoPoint(position.latitude, position.longitude);
    await dbService.updateUser(uid, {'lastKnownLocation': location});
  }

  // Configura los listeners para Notificaciones Push (Firebase Cloud Messaging).
  void _initFCMListeners() {
    // 1. Notificación recibida en Primer Plano (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 Notificación recibida en Primer Plano: ${message.data}");

      String titulo = message.notification?.title ?? 'Alerta GeoHunt';
      String cuerpo = message.notification?.body ?? '¡Hay un tesoro cerca!';

      // Detección de tesoros temporales desde el payload de datos
      DateTime? fechaLimite;
      if (message.data.containsKey('limitedUntil')) {
        try {
          int millis = int.parse(message.data['limitedUntil']);
          fechaLimite = DateTime.fromMillisecondsSinceEpoch(millis);
          print("⏳ Fecha límite detectada: $fechaLimite");
        } catch (e) {
          print("⚠️ Error parseando fecha limite: $e");
        }
      }
      // Llama al servicio local para mostrar la alerta visual
      mostrarNotificacion(titulo, cuerpo, 'tesoro', fechaLimite: fechaLimite);
    });

    // 2. Notificación tocada cuando la app estaba en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Usuario tocó la notificación');
      // Aquí se podría implementar lógica para centrar el mapa en el tesoro
    });

    // 3. Notificación que abrió la app desde estado cerrado (Terminated)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App iniciada desde notificación (Terminated): ${message.data}');
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final FCMService _fcmService = FCMService();

  @override
  void initState() {
    super.initState();
    // Inicialización de servicios de mensajería
    _fcmService.setupFCMToken(_currentUid);
    _fcmService.initForegroundNotifications();
    _initFCMListeners();
  }

  @override
  Widget build(BuildContext context) {
    // Escucha en tiempo real cambios en el usuario (ej. Puntos ganados)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return  Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        UserModel currentUser = UserModel.fromMap(data, _currentUid);

        final List<Widget> _widgetOptions = <Widget>[
          UserMapView(user: currentUser),       // Vista 0
           LeaderboardView(),              // Vista 1
          UserProfileView(user: currentUser),   // Vista 2
        ];

        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [backgroundColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                title: Text(
                  'GeoHunt Explorador',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 4,
                actions: [
                  IconButton(
                    icon:  Icon(Icons.exit_to_app, color: Colors.white),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) =>  Login(),
                          ),
                              (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [backgroundColor, accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _widgetOptions.elementAt(_selectedIndex),
              ),
              bottomNavigationBar: Padding(
                padding: EdgeInsets.only(top: 20),
                child: CurvedNavigationBar(
                  key: _bottomNavigationKey,
                  index: _selectedIndex,
                  backgroundColor: Colors.transparent,
                  buttonBackgroundColor: secondaryColor,
                  color: secondaryColor,
                  animationCurve: Curves.easeInOut,
                  animationDuration: Duration(milliseconds: 400),
                  height: 65,
                  items: [
                    _buildNavItem(Icons.map, 'Cazar', 0),
                    _buildNavItem(Icons.emoji_events, 'Top 10', 1),
                    _buildNavItem(Icons.person, 'Perfil', 2),
                  ],
                  onTap: _onItemTapped,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: isSelected ? 32 : 26, color: Colors.white),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// VISTA 1: MAPA DEL USUARIO (Lógica Principal de Juego)
// Implementa Geolocalización, Geovallas y Detección de Sensores
// ---------------------------------------------------------------------------
class UserMapView extends StatefulWidget {
  final UserModel user;
  const UserMapView({super.key, required this.user});

  @override
  State<UserMapView> createState() => _UserMapViewState();
}

class _UserMapViewState extends State<UserMapView> {
  final LatLng _tepicCenter = const LatLng(21.5114, -104.8947);
  final MapController _mapController = MapController();
  final Distance _distanceCalculator =  Distance();
  final DatabaseService _dbService = DatabaseService();

  bool _showRoute = false;
  LatLng? _currentPosition;

  // Streams para manejo de datos asíncronos
  StreamSubscription<Position>? _positionStream;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription<QuerySnapshot>? _treasuresSubscription;

  List<TreasureModel> _allTreasures = [];
  TreasureModel? _treasureInRange; // Tesoro actual dentro del radio de 5m
  bool _isClaiming = false; // Flag para prevenir doble reclamo

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
    _initSensor();
    _listenToTreasures();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _accelerometerSubscription?.cancel(); // IMPORTANTE: Liberar sensor para ahorrar batería
    super.dispose();
  }

  // Escucha en tiempo real la colección de tesoros para mantener el mapa actualizado.
  void _listenToTreasures() {
    _treasuresSubscription = FirebaseFirestore.instance
        .collection('treasures')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _allTreasures = snapshot.docs
              .map((d) => TreasureModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList();
        });
      }
    });
  }

  // --- 1. LÓGICA DEL SENSOR (SHAKE) ---
  // Inicializa el acelerómetro del dispositivo.
  // Calcula la fuerza G total usando Pitágoras en 3 ejes (x, y, z).
  void _initSensor() {
    _accelerometerSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      // Fórmula de magnitud del vector de aceleración
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // Umbral de sensibilidad: > 15 m/s² se considera una sacudida fuerte
      if (acceleration > 15) {
        _onShakeDetected();
      }
    });
  }

  void _onShakeDetected() {
    // Regla de Negocio: Solo permite reclamar si hay un tesoro validado en rango
    if (_treasureInRange != null && !_isClaiming) {
      _claimTreasure(_treasureInRange!);
    }
  }

  // --- 2. RECLAMAR TESORO (TRANSACCIÓN) ---
  // Ejecuta la lógica de negocio para otorgar puntos.
  // Utiliza una TRANSACCIÓN DE FIRESTORE para garantizar atomicidad.
  // Esto previene "Race Conditions" (ej. reclamar el mismo tesoro dos veces simultáneamente).
  Future<void> _claimTreasure(TreasureModel treasure) async {
    setState(() { _isClaiming = true; });
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.user.uid);
      final treasureRef = FirebaseFirestore.instance.collection('treasures').doc(treasure.id);

      int pointsAwarded = await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(treasureRef);

        if (!snapshot.exists) {
          throw Exception("Este tesoro ya no existe (fue eliminado o expiró).");
        }

        // Obtener datos frescos del servidor para validar tiempo límite real
        final freshTreasure = TreasureModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);

        int pointsToAdd = 0;
        switch (freshTreasure.difficulty) {
          case 'Fácil': pointsToAdd = 100; break;
          case 'Medio': pointsToAdd = 300; break;
          case 'Difícil': pointsToAdd = 500; break;
          default: pointsToAdd = 100;
        }

        // Bonificación por Tiempo Límite si aún es válido
        if (freshTreasure.isLimitedTime && freshTreasure.limitedUntil != null) {
          if (DateTime.now().isBefore(freshTreasure.limitedUntil!)) {
            pointsToAdd += 200; // Bonus por velocidad
          }
        }

        // Actualización atómica del usuario
        transaction.update(userRef, {
          'score': FieldValue.increment(pointsToAdd),
          'foundTreasures': FieldValue.arrayUnion([freshTreasure.id]), // Añadir ID al array sin duplicados
        });

        return pointsToAdd;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title:  Text('¡TESORO ENCONTRADO! 🎉'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Icon(Icons.verified, color: Colors.green, size: 60),
                 SizedBox(height: 10),
                Text('Has ganado $pointsAwarded puntos.'),
                Text('Tesoro: ${treasure.title}'),
              ],
            ),
            actions: [
              TextButton(onPressed: () { Navigator.pop(ctx); }, child:  Text('¡Genial!')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title:  Text('Error al reclamar'),
            content: Text(e.toString().replaceAll("Exception: ", "")),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child:  Text('Entendido'))],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
          _treasureInRange = null; // Limpiar tesoro en rango tras reclamar
        });
      }
    }
  }

  // --- 3. LÓGICA GPS Y GEOVALLA ---
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

  void _startListeningLocation() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Máxima precisión para detectar los 5 metros
      distanceFilter: 2, // Actualizar cada 2 metros
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((pos) {
      if (mounted) {
        final newPosition = LatLng(pos.latitude, pos.longitude);

        // Filtrar solo tesoros NO encontrados
        final uncollected = _allTreasures.where((t) => !(widget.user.foundTreasures?.contains(t.id) ?? false)).toList();
        TreasureModel? foundInRange;

        // --- ALGORITMO DE GEOVALLA (GEOFENCING) ---
        for (var t in uncollected) {
          final double dist = _distanceCalculator.as(
            LengthUnit.Meter,
            newPosition,
            LatLng(t.location.latitude, t.location.longitude),
          );
          if (dist <= 5) { // Radio de colisión: 5 metros
            foundInRange = t;
            break;
          }
        }

        // Notificar al usuario si entra en el radio de un tesoro nuevo
        if (foundInRange?.id != _treasureInRange?.id) {
          if (foundInRange != null) {
            _vibratePhone();

            // Lógica de notificación diferenciada (Normal vs Temporal)
            if (foundInRange!.isLimitedTime && foundInRange!.limitedUntil != null) {
              mostrarNotificacion(
                '¡CORRE! Tesoro Temporal ⏳',
                'Se acaba el tiempo. ¡Agita rápido para reclamar!',
                'tesoro',
                fechaLimite: foundInRange!.limitedUntil,
              );
            } else {
              mostrarNotificacion(
                '¡Tesoro cerca! 🟢',
                'Agita tu teléfono para reclamar el tesoro',
                'tesoro',
              );
            }
          }
          setState(() { _treasureInRange = foundInRange; });
        }

        setState(() { _currentPosition = newPosition; });
        _saveLastKnownLocation(pos);
      }
    });
  }

  void _saveLastKnownLocation(Position position) {
    final GeoPoint geoPoint = GeoPoint(position.latitude, position.longitude);
    _dbService.updateUser(widget.user.uid, {'lastKnownLocation': geoPoint});
  }

  void _centerOnUser() {
    if (_currentPosition != null) _mapController.move(_currentPosition!, 18);
  }

  // Algoritmo Greedy para sugerir ruta óptima hacia los tesoros más cercanos.
  List<LatLng> _calculateOptimizedRoute(List<TreasureModel> uncollectedTreasures) {
    if (_currentPosition == null) return [];
    List<TreasureModel> nearby = uncollectedTreasures.where((t) => _distanceCalculator.as(LengthUnit.Meter, _currentPosition!, LatLng(t.location.latitude, t.location.longitude)) <= 200).toList();
    if (nearby.isEmpty) return [];

    List<LatLng> path = [_currentPosition!];
    LatLng current = _currentPosition!;
    List<TreasureModel> pending = List.from(nearby);

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

  void _showTreasureDetails(TreasureModel t, bool isFound) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.imageUrl != null && t.imageUrl!.isNotEmpty)
              Padding(
                padding:  EdgeInsets.only(bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(t.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            Text(t.description),
             SizedBox(height: 10),
            if (isFound)
               Chip(label: Text("YA ENCONTRADO"), backgroundColor: Colors.grey, labelStyle: TextStyle(color: Colors.white))
            else
              Chip(
                label: Text(t.difficulty),
                backgroundColor: t.difficulty == 'Difícil' ? Colors.red[100] : Colors.green[100],
              ),
            if (t.isLimitedTime)
               Chip(label: Text('¡Tiempo Limitado!'), backgroundColor: Colors.orangeAccent),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child:  Text('Cerrar'))],
      ),
    );
  }

  Future<void> _vibratePhone() async {
    try {
      bool canVibrate = await Vibration.hasVibrator() ?? false;
      if (canVibrate) Vibration.vibrate(duration: 500);
    } catch (e) {
      print('Error al intentar vibrar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];
    List<LatLng> routePoints = [];

    final uncollectedTreasures = _allTreasures
        .where((t) => !(widget.user.foundTreasures?.contains(t.id) ?? false))
        .toList();

    // Generación dinámica de marcadores según estado (encontrado, dificultad, tiempo)
    markers = _allTreasures.map((t) {
      bool isFound = widget.user.foundTreasures?.contains(t.id) ?? false;
      Color markerColor;
      if (isFound) markerColor = Colors.grey;
      else if (t.id == _treasureInRange?.id) markerColor = Colors.green; // Resaltar tesoro alcanzable
      else if (t.isLimitedTime) markerColor = Colors.amber;
      else markerColor = Colors.red;

      return Marker(
        point: LatLng(t.location.latitude, t.location.longitude),
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showTreasureDetails(t, isFound),
          child: Icon(Icons.location_on, color: markerColor, size: 50),
        ),
      );
    }).toList();

    if (_showRoute && _currentPosition != null) {
      routePoints = _calculateOptimizedRoute(uncollectedTreasures);
    }

    if (_currentPosition != null) {
      markers.add(Marker(point: _currentPosition!, width: 50, height: 50, child:  Icon(Icons.person_pin_circle, color: Colors.blue, size: 40)));
    }

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "routeBtn",
            backgroundColor: _showRoute ? Colors.deepPurple : Colors.white,
            onPressed: () => setState(() => _showRoute = !_showRoute),
            child: Icon(Icons.alt_route, color: _showRoute ? Colors.white : Colors.deepPurple),
          ),
           SizedBox(height: 10),
          FloatingActionButton(heroTag: "gpsBtn", onPressed: _centerOnUser, child:  Icon(Icons.my_location)),
        ],
      ),

      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _tepicCenter, initialZoom: 14),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.geohunt.app'),
              if (_showRoute && routePoints.isNotEmpty)
                PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 5, color: Colors.deepPurple)]),
              // Feedback visual de geovalla cuando estás en rango
              if (_treasureInRange != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(_treasureInRange!.location.latitude, _treasureInRange!.location.longitude),
                      radius: 15,
                      useRadiusInMeter: true,
                      color: Colors.green.withOpacity(0.3),
                      borderColor: Colors.green,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),
          // Banner flotante cuando hay tesoro listo para reclamar
          if (_treasureInRange != null)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Container(
                padding:  EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(15), boxShadow:  [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                child: Column(
                  children: [
                     Text("¡LISTO PARA CAZAR!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                     SizedBox(height: 5),
                    Text("Agita tu teléfono para reclamar: ${_treasureInRange!.title}", style:  TextStyle(color: Colors.white), textAlign: TextAlign.center),
                     Icon(Icons.vibration, color: Colors.white, size: 40),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VISTA 2: TOP 10 LEADERBOARD
// Muestra ranking en tiempo real consultando la colección 'users'
// ---------------------------------------------------------------------------
class LeaderboardView extends StatelessWidget {

  // Helper para asignar colores a las medallas (Oro, Plata, Bronce)
  Color getRankColor(int index, bool me) {
    if (me) return Colors.blue.shade300;
    if (index == 0) return Color(0xFFFFF3C4); // Oro suave
    if (index == 1) return Color(0xFFF0F0F0); // Plata suave
    if (index == 2) return Color(0xFFCE8C4E); // Bronce
    return Colors.white; // Resto
  }

  Widget getRankWidget(int index) {
    if (index == 0) return Text("🥇", style: TextStyle(fontSize: 24));
    if (index == 1) return Text("🥈", style: TextStyle(fontSize: 24));
    if (index == 2) return Text("🥉", style: TextStyle(fontSize: 24));

    return Container(
      width: 24, height: 24, alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400)),
      child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12)),
    );
  }

  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      margin:  EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding:  EdgeInsets.all(20),
            decoration: BoxDecoration(color: accentColor, borderRadius:  BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18))),
            width: double.infinity,
            child:  Text("🏆 Mejores Cazadores", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
          ),
          Expanded(
            // Stream optimizado: Solo trae los top 10 ordenados por puntaje
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'user')
                  .orderBy('score', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return  Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return  Center(child: Text("Aún no hay jugadores."));

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final bool userLogged = (snapshot.data!.docs[index].id == currentUid);

                    return Card(
                      color: getRankColor(index, userLogged),
                      elevation: index < 3 ? 4 : 1,
                      margin:  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: userLogged ?  BorderSide(color: Colors.purple, width: 3) : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                          width: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              getRankWidget(index),
                              Container(
                                padding:  EdgeInsets.all(2),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: index < 3 ? getRankColor(index, userLogged) : Colors.transparent),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: data['profileImageUrl'] != null ? NetworkImage(data['profileImageUrl']) : null,
                                  child: data['profileImageUrl'] == null ? Text(data['username']?[0] ?? '?', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)) : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: Text(data['username'] ?? 'Anónimo', style: TextStyle(fontWeight: index < 3 ? FontWeight.bold : FontWeight.w600, fontSize: index < 3 ? 18 : 16, color:  Color(0xFF333333))),
                        trailing: Container(
                          padding:  EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: index < 3 ? getRankColor(index, userLogged) : Color(0xFF8992D7), borderRadius: BorderRadius.circular(12)),
                          child: Text("${data['score'] ?? 0}", style: TextStyle(fontWeight: FontWeight.bold, color: index < 3 ? Colors.black87 : Colors.white)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VISTA 3: PERFIL DE USUARIO
// Gestión de datos personales y cálculo de nivel basado en puntaje.
// ---------------------------------------------------------------------------
class UserProfileView extends StatefulWidget {
  final UserModel user;
  const UserProfileView({super.key, required this.user});
  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  bool _isEditing = false;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _currentImageUrl = widget.user.profileImageUrl;
  }

  void _ActiveEdit() {
    setState(() { _isEditing = true; });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _usernameController.text = widget.user.username;
      _phoneController.text = widget.user.phoneNumber ?? '';
    });
  }

  // Selecciona una imagen y la sube a Firebase Storage.
  // Solo permitido si el modo edición está activo.
  Future<void> _pickAndUploadImage(ImageSource source) async {
    if (!_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Activa el modo "Editar" para cambiar tu foto.')));
      return;
    }
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 60, maxWidth: 512);
    if (image == null) return;

    final ref = FirebaseStorage.instance.ref().child('profile_images').child('${widget.user.uid}.jpg');
    await ref.putFile(File(image.path), SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({'profileImageUrl': url});
    setState(() { _currentImageUrl = url; });
  }

  Future<void> _updateProfile() async {
    if (_usernameController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
      'username': _usernameController.text,
      'phoneNumber': _phoneController.text,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Perfil actualizado correctamente')));
      setState(() { _isEditing = false; });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ---------------------------------------------
          // 1. CABECERA DE PERFIL
          // ---------------------------------------------
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 40, 20, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:  BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                // AVATAR CON EDICIÓN
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: secondaryColor.withOpacity(0.2), width: 4)),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null,
                        child: _currentImageUrl == null ? Icon(Icons.person, size: 60, color: Colors.grey.shade400) : null,
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.white,
                            shape:  RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (ctx) => Wrap(
                              children: [
                                ListTile(leading:  Icon(Icons.photo, color: secondaryColor), title:  Text('Galería'), onTap: () { Navigator.pop(ctx); _pickAndUploadImage(ImageSource.gallery); }),
                                ListTile(leading:  Icon(Icons.camera_alt, color: secondaryColor), title:  Text('Cámara'), onTap: () { Navigator.pop(ctx); _pickAndUploadImage(ImageSource.camera); }),
                              ],
                            ),
                          ),
                          child: Container(padding:  EdgeInsets.all(8), decoration:  BoxDecoration(color: secondaryColor, shape: BoxShape.circle), child:  Icon(Icons.camera_alt, color: Colors.white, size: 20)),
                        ),
                      ),
                  ],
                ),

                 SizedBox(height: 15),

                // NOMBRE Y NIVEL
                Text(widget.user.username, style:  TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                Text("Explorador Nivel ${(_calculateLevel(widget.user.score))}", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),

                 SizedBox(height: 25),

                // ESTADÍSTICAS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem("Puntaje", "${widget.user.score}", Icons.star_rounded, Colors.orangeAccent),
                    Container(height: 40, width: 1, color: Colors.grey.shade200),
                    _buildStatItem("Tesoros", "${widget.user.foundTreasures?.length ?? 0}", Icons.diamond_rounded, Colors.blueAccent),
                  ],
                ),
              ],
            ),
          ),

           SizedBox(height: 30),

          // ---------------------------------------------
          // 2. FORMULARIO DE EDICIÓN
          // ---------------------------------------------
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Información Personal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    if (_isEditing)
                      Container(padding:  EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)), child:  FittedBox(fit: BoxFit.scaleDown, child: Text("Editando...", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)))),
                  ],
                ),
                 SizedBox(height: 20),
                _InputsBuilder(_usernameController, "Nombre de Usuario", Icons.person_outline, enabled: _isEditing),
                 SizedBox(height: 15),
                _InputsBuilder(_phoneController, "Teléfono", Icons.phone_outlined, isPhone: true, enabled: _isEditing),
                 SizedBox(height: 30),

                // BOTONES DE ACCIÓN
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _isEditing ? _updateProfile : _ActiveEdit,
                          style: ElevatedButton.styleFrom(backgroundColor: _isEditing ? accentColor : secondaryColor, foregroundColor: Colors.white, elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          icon: Icon(_isEditing ? Icons.check_circle : Icons.edit),
                          label: Text(_isEditing ? 'Guardar Cambios' : 'Editar Perfil', style:  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    if (_isEditing) ...[
                       SizedBox(width: 15),
                      InkWell(
                        onTap: _cancelEdit,
                        borderRadius: BorderRadius.circular(15),
                        child: Container(height: 55, width: 55, decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(15)), child: Icon(Icons.close, color: Colors.red.shade700)),
                      ),
                    ],
                  ],
                ),
                 SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(padding:  EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
         SizedBox(height: 8),
        Text(value, style:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _InputsBuilder(TextEditingController controller, String label, IconData icon, {bool isPhone = false, bool enabled = true}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        boxShadow: enabled ? [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))] : [],
        border: enabled ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller, enabled: enabled, keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: TextStyle(fontWeight: FontWeight.w600, color: enabled ? const Color(0xFF2D3142) : Colors.grey.shade600),
        decoration: InputDecoration(
          labelText: label, labelStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: enabled ? secondaryColor : Colors.grey),
          border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide:  BorderSide(color: secondaryColor, width: 1.5)),
        ),
      ),
    );
  }

  // Calcula el nivel del usuario usando una escala logarítmica.
  // Fórmula: PuntosParaNivel(N) = Base * Multiplicador^(N-1)
  // Inversa para obtener N dado el Score: N = 1 + log(score / Base) / log(Multiplicador)
  int _calculateLevel(int? score) {
    if (score == null || score <= 0) return 0;
    const double base = 1000.0; // Puntos necesarios para nivel 1
    const double multiplicador = 1.5; // Curva de dificultad

    if (score < base) return 0;
    double nivel = 1 + (log(score / base) / log(multiplicador));
    return nivel.floor();
  }
}