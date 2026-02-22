import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/models/publication.dart';
import '../../../features/publications/providers/publications_provider.dart';
import '../../../core/l10n/app_localizations.dart';

/// Ecran des statistiques/analytics des publications - Acces gratuit
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;

  // Couleurs du theme (vert sombre)
  static const Color _kVertFonce = Color(0xFF2E7D32);
  static const Color _kVertClair = Color(0xFF4CAF50);

  // Statistiques calculees depuis les publications
  int _totalVues = 0;
  int _totalAspirants = 0;
  int _totalCaptivants = 0;

  // Stats par jour (7 derniers jours)
  Map<String, int> _vuesParJour = {};
  Map<String, int> _aspirantsParJour = {};
  Map<String, int> _captivantsParJour = {};

  // Stats par heure (0-23)
  Map<int, int> _vuesParHeure = {};
  Map<int, int> _aspirantsParHeure = {};
  Map<int, int> _captivantsParHeure = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadStats() {
    final publicationsProvider = Provider.of<PublicationsProvider>(context, listen: false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      publicationsProvider.chargerMesPublications().then((_) {
        if (mounted) {
          _calculateStats(publicationsProvider.mesPublications);
          setState(() {
            _isLoading = false;
          });
        }
      });
    });
  }

  void _calculateStats(List<Publication> publications) {
    _totalVues = 0;
    _totalAspirants = 0;
    _totalCaptivants = 0;
    _vuesParJour = {};
    _aspirantsParJour = {};
    _captivantsParJour = {};
    _vuesParHeure = {};
    _aspirantsParHeure = {};
    _captivantsParHeure = {};

    // Date d'il y a 7 jours
    final septJoursAvant = DateTime.now().subtract(const Duration(days: 7));

    for (final pub in publications) {
      _totalVues += pub.nombreVues;
      _totalAspirants += pub.nombreInspirations;
      _totalCaptivants += pub.nombreCaptivants;

      // Stats par jour (seulement les 7 derniers jours)
      if (pub.dateCreation.isAfter(septJoursAvant)) {
        final jourSemaine = _getDayOfWeek(pub.dateCreation.weekday);
        _vuesParJour[jourSemaine] = (_vuesParJour[jourSemaine] ?? 0) + pub.nombreVues;
        _aspirantsParJour[jourSemaine] = (_aspirantsParJour[jourSemaine] ?? 0) + pub.nombreInspirations;
        _captivantsParJour[jourSemaine] = (_captivantsParJour[jourSemaine] ?? 0) + pub.nombreCaptivants;

        // Stats par heure
        final heure = pub.dateCreation.hour;
        _vuesParHeure[heure] = (_vuesParHeure[heure] ?? 0) + pub.nombreVues;
        _aspirantsParHeure[heure] = (_aspirantsParHeure[heure] ?? 0) + pub.nombreInspirations;
        _captivantsParHeure[heure] = (_captivantsParHeure[heure] ?? 0) + pub.nombreCaptivants;
      }
    }
  }

  String _getDayOfWeek(int weekday) {
    // Return a key that will be translated
    switch (weekday) {
      case 1: return 'mon';
      case 2: return 'tue';
      case 3: return 'wed';
      case 4: return 'thu';
      case 5: return 'fri';
      case 6: return 'sat';
      case 7: return 'sun';
      default: return '';
    }
  }

  String _getDayOfWeekDisplay(BuildContext context, String key) {
    switch (key) {
      case 'mon': return context.tr('day_mon');
      case 'tue': return context.tr('day_tue');
      case 'wed': return context.tr('day_wed');
      case 'thu': return context.tr('day_thu');
      case 'fri': return context.tr('day_fri');
      case 'sat': return context.tr('day_sat');
      case 'sun': return context.tr('day_sun');
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final publicationsProvider = Provider.of<PublicationsProvider>(context);

    if (!publicationsProvider.isLoading && mounted) {
      _calculateStats(publicationsProvider.mesPublications);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.tr('my_statistics')),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _kVertFonce,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: _kVertFonce,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: const Icon(Icons.visibility), text: context.tr('views')),
                Tab(icon: const Icon(Icons.favorite), text: context.tr('aspirants')),
                Tab(icon: const Icon(Icons.star), text: context.tr('captivants')),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading || publicationsProvider.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _kVertFonce),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('loading_statistics'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : _buildDashboard(context, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadStats,
        backgroundColor: _kVertFonce,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Bandeau acces gratuit
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _kVertFonce.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_open, color: _kVertFonce),
                const SizedBox(width: 8),
                Text(
                  ' ${context.tr('free_access_30_days')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _kVertFonce),
                ),
              ],
            ),
          ),

          // Statistiques globales
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard(
                  context,
                  icon: Icons.visibility,
                  label: context.tr('views'),
                  value: _totalVues.toString(),
                  color: _kVertFonce,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  context,
                  icon: Icons.favorite,
                  label: context.tr('aspirants'),
                  value: _totalAspirants.toString(),
                  color: _kVertFonce,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  context,
                  icon: Icons.star,
                  label: context.tr('captivants'),
                  value: _totalCaptivants.toString(),
                  color: _kVertFonce,
                ),
              ],
            ),
          ),

          // Graphique par jour (7 derniers jours)
          _buildChartCard(
            context,
            title: context.tr('last_7_days'),
            chart: _buildWeeklyBarChart(context),
          ),

          // Graphique par heure
          _buildChartCard(
            context,
            title: context.tr('by_hour_today'),
            chart: _buildHourlyLineChart(),
          ),

          // Onglets avec contenu detaille
          SizedBox(
            height: 350,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailTab(context, context.tr('views'), Icons.visibility, _vuesParJour, _kVertFonce),
                _buildDetailTab(context, context.tr('aspirants'), Icons.favorite, _aspirantsParJour, _kVertFonce),
                _buildDetailTab(context, context.tr('captivants'), Icons.star, _captivantsParJour, _kVertFonce),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, {required String title, required Widget chart}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insert_chart, color: _kVertFonce, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kVertFonce,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart(BuildContext context) {
    final jours = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final currentIndex = _tabController.index;
    
    final data = currentIndex == 0 
        ? jours.map((j) => _vuesParJour[j] ?? 0).toList()
        : currentIndex == 1
            ? jours.map((j) => _aspirantsParJour[j] ?? 0).toList()
            : jours.map((j) => _captivantsParJour[j] ?? 0).toList();

    final maxValue = data.isEmpty ? 10.0 : (data.reduce((a, b) => a > b ? a : b) * 1.2);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: maxValue,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: maxValue > 20 ? (maxValue / 5) : 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: maxValue > 20 ? (maxValue / 5) : 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < jours.length) {
                  return Text(
                    _getDayOfWeekDisplay(context, jours[value.toInt()]),
                    style: TextStyle(fontSize: 11, color: _kVertFonce, fontWeight: FontWeight.bold),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(jours.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[index].toDouble(),
                color: _kVertFonce,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildHourlyLineChart() {
    final heures = List.generate(24, (i) => i);
    final currentIndex = _tabController.index;
    
    final data = currentIndex == 0 
        ? heures.map((h) => _vuesParHeure[h] ?? 0).toList()
        : currentIndex == 1
            ? heures.map((h) => _aspirantsParHeure[h] ?? 0).toList()
            : heures.map((h) => _captivantsParHeure[h] ?? 0).toList();

    final maxValue = data.isEmpty ? 10.0 : (data.reduce((a, b) => a > b ? a : b) * 1.2);

    return LineChart(
      LineChartData(
        maxY: maxValue,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: maxValue > 20 ? (maxValue / 5) : 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: maxValue > 20 ? (maxValue / 5) : 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < 24) {
                  return Text(
                    '${value.toInt()}h',
                    style: TextStyle(fontSize: 10, color: _kVertFonce),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(24, (index) => FlSpot(index.toDouble(), data[index].toDouble())),
            isCurved: true,
            color: _kVertFonce,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _kVertFonce,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _kVertFonce.withOpacity(0.2),
            ),
          ),
        ],
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildDetailTab(BuildContext context, String title, IconData icon, Map<String, int> data, Color color) {
    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                context.trParams('no_data_for', {'title': title}),
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('data_will_appear'),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: entries.map((entry) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kVertFonce.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _kVertFonce, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                _getDayOfWeekDisplay(context, entry.key),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                entry.value.toString(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _kVertFonce,
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
