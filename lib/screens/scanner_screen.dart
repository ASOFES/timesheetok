import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/user.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? cameraController;
  bool _isProcessing = false;
  bool _scannerActive = true;
  String? _lastScannedData;
  DateTime? _lastScanTime;
  User? _currentUser;
  
  // 📍 ÉTATS GPS ET CAMÉRA
  bool _isGpsActive = false;
  bool _isCameraActive = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadUserData();
    _checkDeviceStates();
  }

  // 📱 INITIALISATION SÉCURISÉE DE LA CAMÉRA
  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isInitializing = true;
      });
      
      // Créer le contrôleur de caméra
      cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      
      print('📷 Contrôleur caméra créé avec succès');
      
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('❌ Erreur création contrôleur caméra: $e');
      setState(() {
        _isInitializing = false;
        _isCameraActive = false;
      });
    }
  }

  // 📍 VÉRIFIER ÉTATS GPS ET CAMÉRA
  Future<void> _checkDeviceStates() async {
    // Vérifier l'état de la caméra
    if (cameraController != null) {
      try {
        await cameraController!.start();
        setState(() {
          _isCameraActive = true;
        });
        print('📷 Caméra: ACTIVE');
      } catch (e) {
        setState(() {
          _isCameraActive = false;
        });
        print('📷 Caméra: INACTIVE - $e');
      }
    } else {
      print('❌ Contrôleur caméra non initialisé');
      setState(() {
        _isCameraActive = false;
      });
    }

    // Vérifier l'état du GPS (permission)
    try {
      // Import Geolocator nécessaire - sera ajouté plus tard
      setState(() {
        _isGpsActive = true; // Pour l'instant, supposons actif
      });
      print('📍 GPS: ACTIVE');
    } catch (e) {
      setState(() {
        _isGpsActive = false;
      });
      print('📍 GPS: INACTIVE - $e');
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await ApiService.getUser();
      setState(() {
        _currentUser = user;
      });
      print('👤 Utilisateur chargé: ${user?.displayName ?? 'Inconnu'}');
    } catch (e) {
      print('❌ Erreur chargement utilisateur: $e');
      setState(() {
        _currentUser = null;
      });
    }
  }

  void _onQRCodeDetected(BarcodeCapture capture) async {
    // 🔒 PROTECTION ABSOLUE - VERROUS MULTIPLES
    
    // 🛡️ VERROU 1: Traitement en cours
    if (_isProcessing) {
      print('🚫 PROTECTION 1: Traitement en cours, scan BLOQUÉ');
      return;
    }

    // 🛡️ VERROU 2: Scanner désactivé
    if (!_scannerActive) {
      print('🚫 PROTECTION 2: Scanner désactivé, scan BLOQUÉ');
      return;
    }

    // 🛡️ VERROU 3: Caméra non initialisée
    if (cameraController == null) {
      print('🚫 PROTECTION 3: Caméra non initialisée, scan BLOQUÉ');
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) {
      print('⚠️ QR vide ou invalide');
      return;
    }

    // 🛡️ VERROU 4: Anti-doublon temporel STRICT
    final now = DateTime.now();
    if (_lastScannedData == qrData && _lastScanTime != null) {
      final timeDiff = now.difference(_lastScanTime!).inMilliseconds;
      if (timeDiff < 3000) {  // 3 secondes minimum entre scans identiques
        print('🚫 PROTECTION 4: Même QR dans les ${timeDiff}ms, scan BLOQUÉ');
        _showMessage('⚠️ SCAN TROP RAPIDE', 'Attendez 3 secondes entre les scans', Colors.orange);
        return;
      }
    }

    // 🔒 VERROUILLAGE TOTAL IMMÉDIAT - AUCUN AUTRE SCAN POSSIBLE
    setState(() {
      _isProcessing = true;
      _scannerActive = false;
      _lastScannedData = qrData;
      _lastScanTime = now;
    });

    print('🔒 VERROUILLAGE ABSOLU: Scanner 100% désactivé');
    print('📱 QR Code détecté: $qrData');
    
    // 🔒 ARRÊT FORCÉ ET IMMÉDIAT DE LA CAMÉRA
    try {
      await cameraController!.stop();
      setState(() {
        _isCameraActive = false;
      });
      print('📷 CAMÉRA ARRÊTÉE IMMÉDIATEMENT');
    } catch (e) {
      print('⚠️ Erreur arrêt caméra: $e');
    }

    // 🎯 TRAITEMENT DU QR CODE
    await _processQRCode(qrData);
  }

  // 🎯 FONCTION D'AFFICHAGE DE MESSAGES CLAIRS
  void _showMessage(String title, String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(message, style: const TextStyle(fontSize: 14)),
            ],
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _processQRCode(String qrData) async {
    try {
      // 🔍 VÉRIFICATION UTILISATEUR
      if (_currentUser == null) {
        print('❌ ERREUR: Utilisateur non connecté');
        _showMessage('❌ ERREUR CONNEXION', 'Utilisateur non connecté. Reconnectez-vous.', Colors.red);
        _showErrorDialog('❌ Erreur de connexion', 'Utilisateur non connecté');
        return;
      }

      print('👤 Utilisateur connecté: ${_currentUser?.displayName ?? 'Inconnu'} (ID: ${_currentUser?.id ?? 'N/A'})');
      
      // 🔍 AFFICHAGE MESSAGE DE TRAITEMENT
      _showMessage('🔍 ANALYSE EN COURS', 'Vérification du QR code...', Colors.blue);

      // 🔒 VÉRIFICATION ANTI-DOUBLON QUOTIDIEN
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      print('📅 Date du scan: $todayString');
      print('🔍 QR Code: $qrData');

      // 🎯 ANALYSE DU QR CODE
      if (qrData.contains('ENTREE') || qrData.contains('entrée') || qrData.contains('IN')) {
        await _processEntry(qrData, todayString);
      } else if (qrData.contains('SORTIE') || qrData.contains('sortie') || qrData.contains('OUT')) {
        await _processExit(qrData, todayString);
      } else {
        print('⚠️ QR Code non reconnu: $qrData');
        _showMessage('⚠️ QR INCONNU', 'Format de QR code non reconnu', Colors.orange);
        _showErrorDialog('⚠️ QR Code non reconnu', 'Le format de ce QR code n\'est pas reconnu par l\'application.');
      }

    } catch (e) {
      print('❌ Erreur traitement QR: $e');
      _showMessage('❌ ERREUR TRAITEMENT', 'Erreur lors du traitement du QR code', Colors.red);
      _showErrorDialog('❌ Erreur de traitement', 'Une erreur est survenue lors du traitement du QR code: $e');
    } finally {
      // 🔓 DÉVERROUILLAGE ET RÉACTIVATION
      await _reactivateScanner();
    }
  }

  // 🔓 RÉACTIVATION DU SCANNER
  Future<void> _reactivateScanner() async {
    try {
      // Réactiver la caméra
      if (cameraController != null) {
        await cameraController!.start();
        setState(() {
          _isCameraActive = true;
        });
        print('📷 Caméra réactivée');
      }
    } catch (e) {
      print('⚠️ Erreur réactivation caméra: $e');
    }

    // Réactiver le scanner
    setState(() {
      _isProcessing = false;
      _scannerActive = true;
    });
    
    print('🔓 Scanner réactivé et prêt');
  }

  // 🚪 TRAITEMENT ENTRÉE
  Future<void> _processEntry(String qrData, String date) async {
    try {
      print('🚪 Traitement ENTRÉE pour la date: $date');
      
      // 🔍 VÉRIFICATION ANTI-DOUBLON ENTRÉE
      final hasEntryToday = await _checkEntryExists(date, 'ENTREE');
      if (hasEntryToday) {
        print('⚠️ Entrée déjà enregistrée aujourd\'hui');
        _showMessage('⚠️ ENTRÉE DÉJÀ ENREGISTRÉE', 'Vous avez déjà pointé l\'entrée aujourd\'hui', Colors.orange);
        return;
      }

      // 📝 ENREGISTREMENT ENTRÉE
      final success = await _recordTimesheet(qrData, date, 'ENTREE');
      if (success) {
        print('✅ Entrée enregistrée avec succès');
        _showMessage('✅ ENTRÉE ENREGISTRÉE', 'Pointage d\'entrée validé !', Colors.green);
        _showSuccessDialog('✅ Entrée enregistrée', 'Votre pointage d\'entrée a été enregistré avec succès.');
      } else {
        print('❌ Échec enregistrement entrée');
        _showMessage('❌ ÉCHEC ENREGISTREMENT', 'Erreur lors de l\'enregistrement', Colors.red);
      }

    } catch (e) {
      print('❌ Erreur traitement entrée: $e');
      _showMessage('❌ ERREUR ENTRÉE', 'Erreur lors du traitement de l\'entrée', Colors.red);
    }
  }

  // 🚪 TRAITEMENT SORTIE
  Future<void> _processExit(String qrData, String date) async {
    try {
      print('🚪 Traitement SORTIE pour la date: $date');
      
      // 🔍 VÉRIFICATION PRÉALABLE ENTRÉE
      final hasEntryToday = await _checkEntryExists(date, 'ENTREE');
      if (!hasEntryToday) {
        print('⚠️ Aucune entrée enregistrée aujourd\'hui');
        _showMessage('⚠️ AUCUNE ENTRÉE', 'Vous devez d\'abord pointer l\'entrée', Colors.orange);
        return;
      }

      // 🔍 VÉRIFICATION ANTI-DOUBLON SORTIE
      final hasExitToday = await _checkEntryExists(date, 'SORTIE');
      if (hasExitToday) {
        print('⚠️ Sortie déjà enregistrée aujourd\'hui');
        _showMessage('⚠️ SORTIE DÉJÀ ENREGISTRÉE', 'Vous avez déjà pointé la sortie aujourd\'hui', Colors.orange);
        return;
      }

      // 📝 ENREGISTREMENT SORTIE
      final success = await _recordTimesheet(qrData, date, 'SORTIE');
      if (success) {
        print('✅ Sortie enregistrée avec succès');
        _showMessage('✅ SORTIE ENREGISTRÉE', 'Pointage de sortie validé !', Colors.green);
        _showSuccessDialog('✅ Sortie enregistrée', 'Votre pointage de sortie a été enregistré avec succès.');
      } else {
        print('❌ Échec enregistrement sortie');
        _showMessage('❌ ÉCHEC ENREGISTREMENT', 'Erreur lors de l\'enregistrement', Colors.red);
      }

    } catch (e) {
      print('❌ Erreur traitement sortie: $e');
      _showMessage('❌ ERREUR SORTIE', 'Erreur lors du traitement de la sortie', Colors.red);
    }
  }

  // 🔍 VÉRIFICATION EXISTANCE POINTAGE
  Future<bool> _checkEntryExists(String date, String type) async {
    try {
      // Pour l'instant, retourner false (pas de vérification en base)
      // Cette fonction sera implémentée plus tard avec la vraie API
      return false;
    } catch (e) {
      print('⚠️ Erreur vérification pointage: $e');
      return false;
    }
  }

  // 📝 ENREGISTREMENT POINTAGE
  Future<bool> _recordTimesheet(String qrData, String date, String type) async {
    try {
      print('📝 Enregistrement $type pour la date: $date');
      print('📱 QR Data: $qrData');
      
      // Pour l'instant, simuler un enregistrement réussi
      // Cette fonction sera implémentée plus tard avec la vraie API
      await Future.delayed(const Duration(seconds: 1));
      
      print('✅ Pointage $type enregistré avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur enregistrement pointage: $e');
      return false;
    }
  }

  // 🎯 DIALOGUES D'ERREUR ET SUCCÈS
  void _showErrorDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showSuccessDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // 🔄 RÉINITIALISATION DU SCANNER
  Future<void> _resetScanner() async {
    try {
      print('🔄 Réinitialisation du scanner...');
      
      // Arrêter la caméra
      if (cameraController != null) {
        await cameraController!.stop();
      }
      
      // Réinitialiser les états
      setState(() {
        _isProcessing = false;
        _scannerActive = true;
        _isCameraActive = false;
        _lastScannedData = null;
        _lastScanTime = null;
      });
      
      // Redémarrer la caméra
      await Future.delayed(const Duration(milliseconds: 500));
      if (cameraController != null) {
        await cameraController!.start();
        setState(() {
          _isCameraActive = true;
        });
      }
      
      print('✅ Scanner réinitialisé avec succès');
      _showMessage('🔄 SCANNER RÉINITIALISÉ', 'Scanner prêt pour un nouveau scan', Colors.blue);
      
    } catch (e) {
      print('❌ Erreur réinitialisation scanner: $e');
      _showMessage('❌ ERREUR RÉINITIALISATION', 'Erreur lors de la réinitialisation', Colors.red);
    }
  }

  // 🔦 TOGGLE FLASH
  Future<void> _toggleFlash() async {
    try {
      if (cameraController != null) {
        await cameraController!.toggleTorch();
        print('🔦 Flash basculé');
      }
    } catch (e) {
      print('⚠️ Erreur toggle flash: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scanner QR',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF667eea),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetScanner,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner View
          if (cameraController != null && _isCameraActive)
            MobileScanner(
              controller: cameraController!,
              onDetect: _scannerActive ? _onQRCodeDetected : (capture) {},
            )
          else
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isInitializing)
                      const CircularProgressIndicator(color: Colors.white)
                    else
                      const Icon(Icons.camera_alt, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _isInitializing ? 'Initialisation de la caméra...' : 'Caméra non disponible',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if (!_isInitializing && !_isCameraActive)
                      ElevatedButton(
                        onPressed: _resetScanner,
                        child: const Text('Réessayer'),
                      ),
                  ],
                ),
              ),
            ),

          // Scanner Overlay
          if (_isCameraActive)
            Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: const Color(0xFF667eea),
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 5,
                  cutOutSize: 250,
                ),
              ),
            ),

          // Status Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Traitement en cours...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

          // Status Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isCameraActive ? Icons.camera_alt : Icons.camera_alt_outlined,
                        color: _isCameraActive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Caméra',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        _isGpsActive ? Icons.location_on : Icons.location_off,
                        color: _isGpsActive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GPS',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        _scannerActive ? Icons.qr_code_scanner : Icons.qr_code_scanner_outlined,
                        color: _scannerActive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Scanner',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final cutOutWidth = cutOutSize < width ? cutOutSize : width - borderWidth;
    final cutOutHeight = cutOutSize < height ? cutOutSize : height - borderWidth;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      borderWidthSize - cutOutWidth / 2,
      borderHeightSize - cutOutHeight / 2,
      cutOutWidth,
      cutOutHeight,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndCorners(
          cutOutRect,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
        backgroundPaint..blendMode = BlendMode.clear,
      )
      ..restore();



    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.top + borderLength)
        ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius)
        ..quadraticBezierTo(cutOutRect.left, cutOutRect.top, cutOutRect.left + borderRadius, cutOutRect.top)
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.top),
      boxPaint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderLength, cutOutRect.top)
        ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)
        ..quadraticBezierTo(cutOutRect.right, cutOutRect.top, cutOutRect.right, cutOutRect.top + borderRadius)
        ..lineTo(cutOutRect.right, cutOutRect.top + borderLength),
      boxPaint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right, cutOutRect.bottom - borderLength)
        ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius)
        ..quadraticBezierTo(cutOutRect.right, cutOutRect.bottom, cutOutRect.right - borderRadius, cutOutRect.bottom)
        ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom),
      boxPaint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom)
        ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom)
        ..quadraticBezierTo(cutOutRect.left, cutOutRect.bottom, cutOutRect.left, cutOutRect.bottom - borderRadius)
        ..lineTo(cutOutRect.left, cutOutRect.bottom - borderLength),
      boxPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
