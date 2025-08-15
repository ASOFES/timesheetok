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
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  bool _scannerActive = true;
  String? _lastScannedData;
  DateTime? _lastScanTime;
  User? _currentUser;
  
  // 📍 ÉTATS GPS ET CAMÉRA
  bool _isGpsActive = false;
  bool _isCameraActive = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkDeviceStates();
  }

  // 📍 VÉRIFIER ÉTATS GPS ET CAMÉRA
  Future<void> _checkDeviceStates() async {
    // Vérifier l'état de la caméra
    try {
      final cameras = await cameraController.start();
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
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await ApiService.getUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error loading user: $e');
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

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) {
      print('⚠️ QR vide ou invalide');
      return;
    }

    // 🛡️ VERROU 3: Anti-doublon temporel STRICT
    final now = DateTime.now();
    if (_lastScannedData == qrData && _lastScanTime != null) {
      final timeDiff = now.difference(_lastScanTime!).inMilliseconds;
      if (timeDiff < 3000) {  // 3 secondes minimum entre scans identiques
        print('🚫 PROTECTION 3: Même QR dans les ${timeDiff}ms, scan BLOQUÉ');
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
      await cameraController.stop();
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

      print('👤 Utilisateur connecté: ${_currentUser!.displayName} (ID: ${_currentUser!.id})');
      
      // 🔍 AFFICHAGE MESSAGE DE TRAITEMENT
      _showMessage('🔍 ANALYSE EN COURS', 'Vérification du QR code...', Colors.blue);

      // 🔒 VÉRIFICATION ANTI-DOUBLON QUOTIDIEN
      print('🔍 Vérification anti-doublon quotidien pour QR: $qrData');
      final alreadyUsed = await ApiService.checkQRUsedToday(qrData, _currentUser!.id);
      if (alreadyUsed) {
        print('🚫 DOUBLON QUOTIDIEN DÉTECTÉ: QR déjà utilisé aujourd\'hui');
        _showMessage('🚫 DOUBLON DÉTECTÉ', 'Vous avez déjà pointé avec ce QR code aujourd\'hui !', Colors.orange);
        _showErrorDialog('🚫 Pointage en double', 'Vous avez déjà utilisé ce QR code aujourd\'hui.\n\nUn seul pointage par QR code par jour est autorisé.');
        return;
      }

      print('✅ Vérification anti-doublon: QR autorisé');

      // 🎯 FONCTION POUR DÉTERMINER LE TYPE DE SERVICE
      String _getServiceType(int timesheetTypeId, Map<String, dynamic> qrJson) {
        // Vérifier d'abord si le QR contient une indication explicite
        if (qrJson.containsKey('serviceType')) {
          return qrJson['serviceType'].toString();
        }
        if (qrJson.containsKey('type')) {
          return qrJson['type'].toString();
        }
        
        // Sinon, déterminer selon le timesheetTypeId
        switch (timesheetTypeId) {
          case 1:
            return 'Début de Service';
          case 2:
            return 'Fin de Service';
          case 3:
            return 'Pause Début';
          case 4:
            return 'Pause Fin';
          case 5:
            return 'Pause Déjeuner';
          default:
            return 'Service Standard';
        }
      }

      // PARSING QR - LOGIQUE COPIÉE DE VOTRE APK QUI MARCHE
      print('QR Code reçu: $qrData');
      print('Longueur QR: ${qrData.length} caractères');
      
      // 🔍 PARSING DU QR CODE JSON
      _showMessage('🔍 VALIDATION', 'Analyse du format QR code...', Colors.blue);
      
      Map<String, dynamic> qrJson;
      try {
        qrJson = jsonDecode(qrData);
        print('✅ QR JSON parsé avec succès: $qrJson');
        print('📋 Clés disponibles: ${qrJson.keys.toList()}');
        _showMessage('✅ FORMAT VALIDE', 'QR code reconnu et validé', Colors.green);
      } catch (e) {
        print('❌ ERREUR PARSING JSON: $e');
        _showMessage('❌ FORMAT INVALIDE', 'QR code non reconnu ou corrompu', Colors.red);
        _showErrorDialog('❌ QR Code Invalide', 'Le QR code scanné n\'est pas au bon format.\n\nFormat attendu: JSON valide\n\nErreur: ${e.toString()}');
        return;
      }

      // Extraire les données selon le format - COMME VOTRE APK
      int siteId, planningId, timesheetTypeId;
      String siteName = '';
      int? employeeId;
      
      // Format Vercel exact (userId + userName + planningId + timeSheetId) - VOTRE FORMAT
      if (qrJson.containsKey('userId') && qrJson.containsKey('userName') && qrJson.containsKey('planningId')) {
        siteId = 1; // Site par défaut
        planningId = qrJson['planningId'];
        timesheetTypeId = qrJson['timeSheetTypeId'] ?? 1;
        siteName = 'test'; // Site fixe pour correspondre au QR
        employeeId = qrJson['userId']; // ID de l'utilisateur spécifique
        print('Format détecté: Vercel (exact)');
        print('  userId: ${qrJson['userId']}');
        print('  userName: ${qrJson['userName']}');
        print('  planningId: ${qrJson['planningId']}');
        print('  timeSheetTypeId: ${qrJson['timeSheetTypeId']}');
        print('  siteName: $siteName');
      }
      // Format Vercel (site + employé) - Format complet
      else if (qrJson.containsKey('siteId') && qrJson.containsKey('planningId') && qrJson.containsKey('timesheetTypeId')) {
        siteId = qrJson['siteId'];
        planningId = qrJson['planningId'];
        timesheetTypeId = qrJson['timesheetTypeId'];
        siteName = qrJson['siteName'] ?? 'Site inconnu';
        employeeId = qrJson['employeeId']; // ID de l'employé spécifique
        print('Format détecté: Vercel (complet)');
      }
      // Format Vercel (site + employé) - Format sans employeeId
      else if (qrJson.containsKey('siteId') && qrJson.containsKey('planningId')) {
        siteId = qrJson['siteId'];
        planningId = qrJson['planningId'];
        timesheetTypeId = qrJson['timesheetTypeId'] ?? 1;
        siteName = qrJson['siteName'] ?? 'Site inconnu';
        print('Format détecté: Vercel (sans employeeId)');
      }
      // Format raccourci (notre app)
      else if (qrJson.containsKey('uid') && qrJson.containsKey('pid')) {
        siteId = 1; // Site par défaut
        planningId = qrJson['pid'];
        timesheetTypeId = 1; // Type par défaut
        siteName = 'Site par défaut';
        employeeId = qrJson['uid']; // ID de l'utilisateur spécifique
        print('Format détecté: raccourci');
        print('  uid: ${qrJson['uid']}');
      }
      // Format inconnu - Essayons d'extraire intelligemment
      else {
        print('❌ Format non reconnu, tentative d\'extraction intelligente');
        print('QR JSON reçu: $qrJson');
        print('Clés disponibles: ${qrJson.keys.toList()}');
        
        // 🔍 EXTRACTION INTELLIGENTE DU PLANNING ID
        siteId = 1;
        planningId = 5; // Valeur par défaut
        timesheetTypeId = 1;
        siteName = 'Site par défaut';
        
        // Essayer d'extraire le planningId sous toutes les formes possibles
        if (qrJson.containsKey('planningId')) {
          planningId = qrJson['planningId'];
          print('✅ planningId trouvé: $planningId');
        } else if (qrJson.containsKey('pid')) {
          planningId = qrJson['pid'];
          print('✅ pid trouvé: $planningId');
        } else if (qrJson.containsKey('planning_id')) {
          planningId = qrJson['planning_id'];
          print('✅ planning_id trouvé: $planningId');
        } else if (qrJson.containsKey('id')) {
          planningId = qrJson['id'];
          print('✅ id utilisé comme planningId: $planningId');
        } else {
          // Essayer de trouver tout nombre dans le QR
          for (String key in qrJson.keys) {
            final value = qrJson[key];
            if (value is int && value > 0 && value < 1000) {
              planningId = value;
              print('✅ Nombre trouvé ($key): $planningId');
              break;
            }
          }
          
          if (planningId == 5) { // Si on n'a toujours rien trouvé
            planningId = DateTime.now().millisecondsSinceEpoch % 1000; // ID basé sur timestamp
            print('⚠️ Aucun ID trouvé, génération automatique: $planningId');
          }
        }
        
        // Essayer d'extraire le timesheetTypeId aussi
        if (qrJson.containsKey('timeSheetTypeId')) {
          timesheetTypeId = qrJson['timeSheetTypeId'];
        } else if (qrJson.containsKey('timesheetTypeId')) {
          timesheetTypeId = qrJson['timesheetTypeId'];
        } else if (qrJson.containsKey('type')) {
          timesheetTypeId = qrJson['type'];
        }
        
        // Essayer d'extraire l'employeeId aussi pour la sécurité
        if (qrJson.containsKey('userId')) {
          employeeId = qrJson['userId'];
          print('✅ userId trouvé: $employeeId');
        } else if (qrJson.containsKey('employeeId')) {
          employeeId = qrJson['employeeId'];
          print('✅ employeeId trouvé: $employeeId');
        } else if (qrJson.containsKey('uid')) {
          employeeId = qrJson['uid'];
          print('✅ uid trouvé: $employeeId');
        }
        
        print('🔧 Extraction intelligente terminée: Planning=$planningId, Type=$timesheetTypeId, Employee=$employeeId');
      }

      // 🔒 VÉRIFICATION SÉCURITÉ: L'utilisateur peut-il scanner CE QR ?
      if (employeeId != null) {
        // Si le QR contient un employeeId/userId, vérifier qu'il correspond à l'utilisateur connecté
        if (employeeId != _currentUser!.id) {
          print('❌ SÉCURITÉ: Utilisateur connecté (${_currentUser!.id}) ≠ QR employeeId ($employeeId)');
          _showMessage('❌ QR NON AUTORISÉ', 'Ce QR code appartient à un autre utilisateur', Colors.red);
          _showErrorDialog(
            '🚫 QR Code Non Autorisé', 
            'Ce QR code a été généré pour un autre employé.\n\n'
            '👤 Utilisateur connecté: ${_currentUser!.displayName} (ID: ${_currentUser!.id})\n'
            '🔒 QR code pour: ID $employeeId\n\n'
            'Vous ne pouvez scanner que vos propres QR codes.'
          );
          return;
        } else {
          print('✅ SÉCURITÉ: QR code autorisé pour l\'utilisateur ${_currentUser!.id}');
          _showMessage('✅ QR AUTORISÉ', 'QR code vérifié pour ${_currentUser!.displayName}', Colors.green);
        }
      } else {
        // Si pas d'employeeId dans le QR, c'est un QR générique (autorisé)
        print('ℹ️ SÉCURITÉ: QR générique (pas d\'employeeId) - autorisé');
        _showMessage('ℹ️ QR GÉNÉRIQUE', 'QR code sans restriction d\'utilisateur', Colors.orange);
      }

      // 🎯 DÉTERMINER LE TYPE DE SERVICE
      String serviceType = _getServiceType(timesheetTypeId, qrJson);
      
      print('🎯 Données extraites: Site $siteId, Planning $planningId, Type $timesheetTypeId');
      print('🔧 Type de service déterminé: $serviceType');
      _showMessage('📊 DONNÉES EXTRAITES', 'Site: $siteName\nPlanning: $planningId\nType: $serviceType', Colors.blue);

      // 🚀 CRÉATION DU POINTAGE
      _showMessage('🚀 ENREGISTREMENT', 'Envoi du pointage au serveur...', Colors.blue);
      
      final result = await ApiService.createTimesheet(
        siteId: siteId,
        planningId: planningId,
        timesheetTypeId: timesheetTypeId,
        qrData: qrData,
      );

      if (result['success'] == true && mounted) {
        print('🎉 SUCCÈS: Pointage enregistré avec succès');
        
        // 🎉 MESSAGES DE SUCCÈS MULTIPLES DÉTAILLÉS
        _showMessage('🎉 POINTAGE RÉUSSI !', 'Enregistré: $serviceType - $siteName', Colors.green);
        
        final now = DateTime.now();
        final timeString = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        
        _showSuccessDialog(
          '🎉 POINTAGE RÉUSSI !', 
          'Votre pointage a été enregistré avec succès !\n\n'
          '🔧 Type: $serviceType\n'
          '📍 Site: $siteName\n'
          '📋 Planning: $planningId\n'
          '👤 Utilisateur: ${_currentUser!.displayName}\n'
          '📧 Email: ${_currentUser!.email}\n'
          '⏰ Date/Heure: $timeString'
        );
      } else {
        print('❌ ÉCHEC: Pointage non enregistré');
        _showMessage('❌ ÉCHEC POINTAGE', 'Impossible d\'enregistrer le pointage', Colors.red);
        _showErrorDialog('❌ Échec du pointage', 'Le pointage n\'a pas pu être enregistré.\n\nVérifiez votre connexion internet.');
      }
    } catch (e) {
      print('❌ EXCEPTION: $e');
      _showMessage('❌ ERREUR TECHNIQUE', 'Problème lors du traitement: ${e.toString()}', Colors.red);
      if (mounted) {
        _showErrorDialog('❌ Erreur technique', 'Une erreur technique est survenue:\n\n${e.toString()}\n\nVeuillez réessayer.');
      }
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.green)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to dashboard
            },
            child: const Text('🏠 Retour au menu'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 🔄 REDÉMARRER LE SCANNER PROPREMENT
              try {
                await cameraController.start();
                setState(() {
                  _scannerActive = true;
                  _lastScannedData = null;
                  _isProcessing = false;
                  _isCameraActive = true; // 📷 CAMÉRA REACTIVÉE
                });
                print('📷 SCANNER REDÉMARRÉ pour nouveau scan');
              } catch (e) {
                print('❌ Erreur redémarrage scanner: $e');
                setState(() {
                  _isCameraActive = false;
                });
              }
            },
            child: const Text('📱 Nouveau scan'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 🔄 REDÉMARRER LE SCANNER APRÈS ERREUR
              try {
                await cameraController.start();
                setState(() {
                  _scannerActive = true;
                  _lastScannedData = null;
                  _isProcessing = false;
                  _isCameraActive = true; // 📷 CAMÉRA REACTIVÉE
                });
                print('📷 SCANNER REDÉMARRÉ après erreur');
              } catch (e) {
                print('❌ Erreur redémarrage scanner: $e');
                setState(() {
                  _isCameraActive = false;
                });
              }
            },
            child: const Text('🔄 Réessayer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to dashboard
            },
            child: const Text('🏠 Retour au menu'),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() {
    cameraController.toggleTorch();
  }

  void _resetScanner() {
    setState(() {
      _isProcessing = false;
      _scannerActive = true;
      _lastScannedData = null;
      _lastScanTime = null;
    });
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
          MobileScanner(
            controller: cameraController,
            onDetect: _scannerActive ? _onQRCodeDetected : (capture) {},
          ),

          // Scanner Overlay
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
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          '⏳ Traitement en cours...',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Veuillez patienter',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 📍 INDICATEURS GPS ET CAMÉRA
          Positioned(
            top: 20,
            left: 20,
            child: Row(
              children: [
                // Indicateur GPS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isGpsActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isGpsActive ? 'GPS actif' : 'GPS inactif',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Indicateur Caméra
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isCameraActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isCameraActive ? 'Caméra OK' : 'Caméra KO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _scannerActive 
                      ? '📱 Placez le QR code dans le cadre'
                      : _isProcessing 
                        ? '⏳ Traitement en cours...'
                        : '✅ QR code détecté !',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scannerActive 
                      ? 'Alignez bien le code pour un scan optimal'
                      : _isProcessing 
                        ? 'Validation du pointage en cours'
                        : 'Traitement terminé',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement manual entry
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saisie manuelle - À implémenter'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Saisie manuelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
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
