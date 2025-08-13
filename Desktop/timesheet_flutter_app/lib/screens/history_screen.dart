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
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
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
  }

  int get _todayCount {
    return _timesheets.where((ts) => ts.isToday).length;
  }

  int get _thisWeekCount {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    return _timesheets.where((ts) => ts.createdAt.isAfter(weekStart)).length;
  }

  int get _thisMonthCount {
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
            Text(
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
          ],
        ),
      ),
    );
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
