import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';
import '../reports/farmer_reports_screen.dart';
import 'rate_chart_screen.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  final ReportsService _reportsService = ReportsService();
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _last7Days = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final now = DateTime.now();
    
    if (authProvider.user?.token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    final result = await _reportsService.getCollectionReports(authProvider.user!.token!);
    final records = result['success'] == true && result['data'] != null
        ? List<Map<String, dynamic>>.from(result['data']['collections'] ?? [])
        : <Map<String, dynamic>>[];
    
    if (records.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final today = records.where((r) {
      final date = DateTime.tryParse(r['timestamp'] ?? r['collection_date'] ?? '');
      return date != null && date.year == now.year && date.month == now.month && date.day == now.day;
    }).toList();

    final thisWeek = records.where((r) {
      final date = DateTime.tryParse(r['timestamp'] ?? r['collection_date'] ?? '');
      return date != null && now.difference(date).inDays <= 7;
    }).toList();

    final thisMonth = records.where((r) {
      final date = DateTime.tryParse(r['timestamp'] ?? r['collection_date'] ?? '');
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();

    final last7 = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayRecords = records.where((r) {
        final date = DateTime.tryParse(r['timestamp'] ?? r['collection_date'] ?? '');
        return date != null && date.year == day.year && date.month == day.month && date.day == day.day;
      }).toList();
      final qty = dayRecords.fold<double>(0, (sum, r) => sum + (((r['quantity'] ?? r['qty']) as num?)?.toDouble() ?? 0.0));
      last7.add({'day': i, 'quantity': qty});
    }

    setState(() {
      _statistics = {
        'todayCollection': today.fold<double>(0, (sum, r) => sum + (((r['quantity'] ?? r['qty']) as num?)?.toDouble() ?? 0.0)),
        'todayAmount': today.fold<double>(0, (sum, r) => sum + (((r['total_amount'] ?? r['amount']) as num?)?.toDouble() ?? 0.0)),
        'weekCollection': thisWeek.fold<double>(0, (sum, r) => sum + (((r['quantity'] ?? r['qty']) as num?)?.toDouble() ?? 0.0)),
        'monthCollection': thisMonth.fold<double>(0, (sum, r) => sum + (((r['quantity'] ?? r['qty']) as num?)?.toDouble() ?? 0.0)),
        'monthAmount': thisMonth.fold<double>(0, (sum, r) => sum + (((r['total_amount'] ?? r['amount']) as num?)?.toDouble() ?? 0.0)),
        'avgFat': thisMonth.isEmpty ? 0.0 : thisMonth.fold<double>(0, (sum, r) => sum + (((r['fat_percentage'] ?? r['fat']) as num?)?.toDouble() ?? 0.0)) / thisMonth.length,
        'avgSNF': thisMonth.isEmpty ? 0.0 : thisMonth.fold<double>(0, (sum, r) => sum + (((r['snf_percentage'] ?? r['snf']) as num?)?.toDouble() ?? 0.0)) / thisMonth.length,
      };
      _last7Days = last7;
      _isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showProfileMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final user = authProvider.user;

    ProfileMenuScreen.show(
      context,
      user: user,
      isDarkMode: themeProvider.isDarkMode,
      isAutoConnectEnabled: false,
      onThemeChanged: (value) => setState(() {}),
      onLanguageChanged: (locale) => setState(() {}),
      onAutoConnectChanged: (value) async {},
      onLogout: () => _logout(context),
      onProfileUpdated: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final l10n = AppLocalizations();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(SizeConfig.appBarHeight),
        child: AppBar(
          toolbarHeight: SizeConfig.appBarHeight,
          titleSpacing: SizeConfig.appBarTitleSpacing,
          title: Text(l10n.tr('farmer_dashboard'), style: SizeConfig.appBarTitleStyle),
          actions: [
            IconButton(
              iconSize: SizeConfig.appBarIconSize,
              icon: const Icon(Icons.assessment_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FarmerReportsScreen(defaultLocalMode: true))),
            ),
            IconButton(
              iconSize: SizeConfig.appBarIconSize,
              icon: const Icon(Icons.receipt_long),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RateChartScreen())),
            ),
            IconButton(
              iconSize: SizeConfig.appBarIconSize,
              icon: const Icon(Icons.menu),
              onPressed: () => _showProfileMenu(context),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(user),
              if (_isLoading) _buildLoadingState() else _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    final todayCollection = _statistics['todayCollection'] ?? 0.0;
    final todayAmount = _statistics['todayAmount'] ?? 0.0;

    return Container(
      margin: EdgeInsets.all(SizeConfig.flexSpace(16)),
      padding: EdgeInsets.all(SizeConfig.flexSpace(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryGreen, AppTheme.primaryTeal],
        ),
        borderRadius: BorderRadius.circular(SizeConfig.normalize(16)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: SizeConfig.normalize(12),
            offset: Offset(0, SizeConfig.normalize(4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(SizeConfig.flexSpace(12)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(SizeConfig.normalize(12)),
                ),
                child: Icon(Icons.person, color: Colors.white, size: SizeConfig.normalize(32)),
              ),
              SizedBox(width: SizeConfig.flexSpace(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Farmer',
                      style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(22), fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: SizeConfig.flexSpace(4)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: SizeConfig.flexSpace(12), vertical: SizeConfig.flexSpace(4)),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(SizeConfig.normalize(12)),
                      ),
                      child: Text('FARMER', style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(12), fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.flexSpace(20)),
          Container(
            padding: EdgeInsets.all(SizeConfig.flexSpace(16)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(SizeConfig.normalize(12)),
            ),
            child: Column(
              children: [
                Text("Today's Collection", style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(14), color: Colors.white70)),
                SizedBox(height: SizeConfig.flexSpace(8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeaderStat(Icons.water_drop, '${todayCollection.toStringAsFixed(1)} L', 'Milk'),
                    Container(width: 1, height: SizeConfig.normalize(40), color: Colors.white30),
                    _buildHeaderStat(Icons.currency_rupee, '₹${todayAmount.toStringAsFixed(0)}', 'Amount'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: SizeConfig.normalize(24)),
        SizedBox(height: SizeConfig.flexSpace(4)),
        Text(value, style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(20), fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(12), color: Colors.white70)),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.flexSpace(32)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.flexSpace(16)),
      child: Column(
        children: [
          _buildStatsGrid(),
          SizedBox(height: SizeConfig.flexSpace(16)),
          _buildCollectionChart(),
          SizedBox(height: SizeConfig.flexSpace(16)),
          _buildMonthlyAnalytics(),
          SizedBox(height: SizeConfig.flexSpace(16)),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.calendar_today, 'This Week', '${(_statistics['weekCollection'] ?? 0).toStringAsFixed(1)} L', AppTheme.primaryBlue)),
        SizedBox(width: SizeConfig.flexSpace(12)),
        Expanded(child: _buildStatCard(Icons.calendar_month, 'This Month', '${(_statistics['monthCollection'] ?? 0).toStringAsFixed(1)} L', AppTheme.primaryPurple)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.flexSpace(16)),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(SizeConfig.normalize(12)),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: SizeConfig.normalize(28)),
          SizedBox(height: SizeConfig.flexSpace(8)),
          Text(value, style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(18), fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
          SizedBox(height: SizeConfig.flexSpace(4)),
          Text(title, style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(12), color: context.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildCollectionChart() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.flexSpace(16)),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(SizeConfig.normalize(12)),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 7 Days Collection', style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(16), fontWeight: FontWeight.bold)),
          SizedBox(height: SizeConfig.flexSpace(20)),
          SizedBox(
            height: SizeConfig.normalize(200),
            child: _last7Days.isEmpty
                ? Center(child: Text('No data available', style: TextStyle(color: context.textSecondaryColor)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(10))))),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text('D${value.toInt() + 1}', style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(10))))),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(_last7Days.length, (i) => FlSpot(i.toDouble(), (_last7Days[i]['quantity'] ?? 0).toDouble())),
                          isCurved: true,
                          color: AppTheme.primaryGreen,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: AppTheme.primaryGreen.withOpacity(0.1)),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyAnalytics() {
    final avgFat = _statistics['avgFat'] ?? 0.0;
    final avgSNF = _statistics['avgSNF'] ?? 0.0;
    final totalAmount = _statistics['monthAmount'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(SizeConfig.flexSpace(16)),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(SizeConfig.normalize(12)),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Analytics', style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(16), fontWeight: FontWeight.bold)),
          SizedBox(height: SizeConfig.flexSpace(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAnalyticItem('Avg FAT', '${avgFat.toStringAsFixed(1)}%', AppTheme.primaryAmber),
              _buildAnalyticItem('Avg SNF', '${avgSNF.toStringAsFixed(1)}%', AppTheme.primaryBlue),
              _buildAnalyticItem('Total', '₹${totalAmount.toStringAsFixed(0)}', AppTheme.primaryGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(SizeConfig.flexSpace(12)),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Text(value, style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(16), fontWeight: FontWeight.bold, color: color)),
        ),
        SizedBox(height: SizeConfig.flexSpace(8)),
        Text(label, style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(12), color: context.textSecondaryColor)),
      ],
    );
  }

  Widget _buildQuickActions() {
    final l10n = AppLocalizations();
    return Container(
      padding: EdgeInsets.all(SizeConfig.flexSpace(16)),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(SizeConfig.normalize(12)),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(16), fontWeight: FontWeight.bold)),
          SizedBox(height: SizeConfig.flexSpace(12)),
          _buildActionTile(Icons.assessment, l10n.tr('view_reports'), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FarmerReportsScreen(defaultLocalMode: true)))),
          Divider(height: SizeConfig.flexSpace(1)),
          _buildActionTile(Icons.receipt_long, l10n.tr('rate_chart'), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RateChartScreen()))),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(SizeConfig.flexSpace(8)),
        decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(SizeConfig.normalize(8))),
        child: Icon(icon, color: AppTheme.primaryGreen, size: SizeConfig.normalize(24)),
      ),
      title: Text(title, style: TextStyle(fontSize: SizeConfig.adaptiveNormalize(14), fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.arrow_forward_ios, size: SizeConfig.normalize(16), color: context.textSecondaryColor),
      onTap: onTap,
    );
  }
}
