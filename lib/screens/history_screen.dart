import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/timesheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Timesheet> _timesheets = [];
  User? _currentUser;
  bool _isLoading = true;
  
  // NOUVELLES VARIABLES POUR L'HISTORIQUE AVEC SCOPES
  Map<String, dynamic> _todayResume = {};
  Map<String, dynamic> _weekResume = {};
  Map<String, dynamic> _monthResume = {};
  bool _isLoadingResume = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await ApiService.getUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
        await _loadTimesheets();
        await _loadAllResumes(); // NOUVELLE MÉTHODE
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // NOUVELLE MÉTHODE POUR CHARGER TOUS LES RESUMES
  Future<void> _loadAllResumes() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLoadingResume = true;
    });

    try {
      // Charger les 3 scopes en parallèle
      final futures = [
        ApiService.getTimesheetResume(_currentUser!.id, 1), // Aujourd'hui
        ApiService.getTimesheetResume(_currentUser!.id, 2), // Cette semaine
        ApiService.getTimesheetResume(_currentUser!.id, 3), // Ce mois
      ];

      final results = await Future.wait(futures);
      
      setState(() {
        _todayResume = results[0];
        _weekResume = results[1];
        _monthResume = results[2];
      });

      print('✅ Tous les resumes chargés avec succès');
    } catch (e) {
      print('❌ Erreur chargement resumes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement historique: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingResume = false;
      });
    }
  }

  Future<void> _loadTimesheets() async {
    if (_currentUser == null) return;

    try {
      final timesheets = await ApiService.getUserTimesheets(_currentUser!.id);
      setState(() {
        _timesheets = timesheets;
      });
    } catch (e) {
      print('Error loading timesheets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refresh() async {
    await _loadTimesheets();
    await _loadAllResumes(); // NOUVELLE MÉTHODE
  }

  // NOUVEAUX GETTERS UTILISANT L'API RÉELLE
  int get _todayCount {
    if (_todayResume['success'] == true && _todayResume['data'] != null) {
      // Essayer d'extraire le nombre de pointages depuis la réponse API
      final data = _todayResume['data'];
      if (data is Map<String, dynamic>) {
        // Adapter selon la structure de votre API
        return data['totalCount'] ?? data['count'] ?? data['timesheets']?.length ?? 0;
      } else if (data is List) {
        return data.length;
      }
    }
    // Fallback sur l'ancienne méthode
    return _timesheets.where((ts) => ts.isToday).length;
  }

  int get _thisWeekCount {
    if (_weekResume['success'] == true && _weekResume['data'] != null) {
      final data = _weekResume['data'];
      if (data is Map<String, dynamic>) {
        return data['totalCount'] ?? data['count'] ?? data['timesheets']?.length ?? 0;
      } else if (data is List) {
        return data.length;
      }
    }
    // Fallback sur l'ancienne méthode
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    return _timesheets.where((ts) => ts.createdAt.isAfter(weekStart)).length;
  }

  int get _thisMonthCount {
    if (_monthResume['success'] == true && _monthResume['data'] != null) {
      final data = _monthResume['data'];
      if (data is Map<String, dynamic>) {
        return data['totalCount'] ?? data['count'] ?? data['timesheets']?.length ?? 0;
      } else if (data is List) {
        return data.length;
      }
    }
    // Fallback sur l'ancienne méthode
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _timesheets.where((ts) => ts.createdAt.isAfter(monthStart)).length;
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            // NOUVEAU : Indicateur de chargement pour les resumes
            _isLoadingResume
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            // NOUVEAU : Indicateur de source des données
            if (!_isLoadingResume && (title == 'Aujourd\'hui' || title == 'Cette semaine' || title == 'Ce mois'))
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'API',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeInfo(String title, Map<String, dynamic> resume) {
    if (resume.isEmpty) {
      return Text('Aucune information disponible pour $title.');
    }

    final data = resume['data'];
    if (data == null) {
      return Text('Aucune information disponible pour $title.');
    }

    if (data is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ${data['totalCount'] ?? data['count'] ?? data['timesheets']?.length ?? 0} pointages',
            style: const TextStyle(fontSize: 14),
          ),
          if (data['totalCount'] != null)
            Text(
              'Total: ${data['totalCount']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (data['count'] != null)
            Text(
              'Count: ${data['count']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (data['timesheets'] != null)
            Text(
              'Timesheets: ${data['timesheets'].length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      );
    } else if (data is List) {
      return Text(
        '$title: ${data.length} pointages',
        style: const TextStyle(fontSize: 14),
      );
    }
    return Text('Aucune information disponible pour $title.');
  }

  Widget _buildTimesheetItem(Timesheet timesheet) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: timesheet.isToday 
            ? Border.all(color: const Color(0xFF667eea), width: 2)
            : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timesheet.formattedDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✅ Enregistré',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              _buildInfoRow('🏷️ Code', timesheet.uniqueCode),
              const SizedBox(height: 6),
              _buildInfoRow('📍 Site', 'Site ${timesheet.siteId}'),
              const SizedBox(height: 6),
              _buildInfoRow('📋 Planning', 'Planning ${timesheet.planningId}'),
              const SizedBox(height: 6),
              _buildInfoRow('⏰ Type', _getTimesheetTypeLabel(timesheet.timesheetTypeId)),
              
              if (timesheet.details != null) ...[
                const SizedBox(height: 6),
                _buildInfoRow('📱 Méthode', _getMethodFromDetails(timesheet.details!)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getTimesheetTypeLabel(int typeId) {
    switch (typeId) {
      case 1:
        return 'Entrée';
      case 2:
        return 'Sortie';
      default:
        return 'Type $typeId';
    }
  }

  String _getMethodFromDetails(String details) {
    try {
      // Simple parsing - just look for method keywords
      if (details.contains('qr_scan')) return 'Scan QR';
      if (details.contains('manual')) return 'Saisie manuelle';
      if (details.contains('Flutter')) return 'App Flutter';
      return 'Scan QR';
    } catch (e) {
      return 'Scan QR';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historique',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF667eea),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: Column(
                children: [
                  // Stats Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatsCard(
                            'Aujourd\'hui',
                            _todayCount.toString(),
                            Icons.today,
                            const Color(0xFF667eea),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatsCard(
                            'Cette semaine',
                            _thisWeekCount.toString(),
                            Icons.date_range,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatsCard(
                            'Ce mois',
                            _thisMonthCount.toString(),
                            Icons.calendar_month,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // NOUVELLE SECTION : Détails des resumes si disponibles
                  if (!_isLoadingResume && (_todayResume.isNotEmpty || _weekResume.isNotEmpty || _monthResume.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Informations API',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildResumeInfo('Aujourd\'hui', _todayResume),
                              const SizedBox(height: 8),
                              _buildResumeInfo('Cette semaine', _weekResume),
                              const SizedBox(height: 8),
                              _buildResumeInfo('Ce mois', _monthResume),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Timesheets List
                  Expanded(
                    child: _timesheets.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _timesheets.length,
                            itemBuilder: (context, index) {
                              return _buildTimesheetItem(_timesheets[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun pointage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore effectué de pointage.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Return to dashboard
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Faire un pointage'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
