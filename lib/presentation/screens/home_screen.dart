import 'package:flutter/material.dart';
import 'dart:math';
import '../../data/database/database_helper.dart';
import '../../data/models/child_model.dart';
import '../../domain/services/gamification_service.dart';
import 'chat_screen.dart';
import 'emergency_hub_screen.dart';
import 'first_aid_screen.dart';
import 'document_scanner_screen.dart';
import 'vaccine_tracker_screen.dart';
import 'medication_tracker_screen.dart';
import 'system_settings_screen.dart';
import '../../data/models/constante_model.dart';
import '../../domain/services/pdf_export_service.dart';
import '../widgets/growth_chart_widget.dart';
import 'package:intl/intl.dart';
import '../../domain/services/localization_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final GamificationService _gamificationService = GamificationService();

  List<ChildModel> _children = [];
  int _points = 0;
  List<String> _badges = [];
  bool _isLoading = true;
  String _dailyTip = "";

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreenCard = Color(0xFF1B5E20);
  static const Color creamBackground = Color(0xFFFFFAF1);
  static const Color iconBgLightGreen = Color(0xFFE8F5E9);

  final List<String> _pcimeTips = [
    "Breastfeed exclusively up to 6 months for a strong immunity.",
    "Always wash your hands with soap before feeding the child.",
    "A child with fever must drink plenty of fluids.",
    "In case of rapid cough, visit a clinic immediately.",
    "Strictly follow the vaccination schedule to protect them.",
    "Use treated mosquito nets to prevent malaria."
  ];

  @override
  void initState() {
    super.initState();
    _dailyTip = _pcimeTips[Random().nextInt(_pcimeTips.length)];
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final children = await _dbHelper.readAllChildren();
    final points = await _gamificationService.getPoints();
    final badges = await _gamificationService.getUnlockedBadges();

    setState(() {
      _children = children;
      _points = points;
      _badges = badges;
      _isLoading = false;
    });
  }

  void _navigateToChildDashboard(ChildModel child) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChildDashboardScreen(child: child)),
    ).then((_) => _loadData());
  }

  int _currentIndex = 0;

  Widget _buildTopProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage('assets/images/baby_background.png'), // placeholder
            backgroundColor: Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AINA",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: primaryGreen,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  LocalizationService().translate('baby_doing_great'),
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ]
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black87),
              onPressed: () {},
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGamificationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.military_tech, color: Colors.orange, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Récompenses Parents", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  "$_points Points • ${_badges.isNotEmpty ? _badges.last : 'Débutant'}", 
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.star, size: 14, color: primaryGreen),
                const SizedBox(width: 4),
                Text(
                  "+ pts",
                  style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkGreenCard,
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/baby_background.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          opacity: 0.2, // Subtle background effect behind
        )
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    LocalizationService().translate('baby_status'),
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  LocalizationService().translate('happy_active'),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  LocalizationService().translate('last_fed'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_children.isNotEmpty) {
                      _navigateToChildDashboard(_children.first);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    minimumSize: const Size(120, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16)
                  ),
                  child: Text(LocalizationService().translate('add_activity'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
          ),
          const Spacer(flex: 4) // Space for where the baby face is in the image
        ],
      ),
    );
  }

  Widget _buildGridIcons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconItem(Icons.water_drop, LocalizationService().translate('feed'), Colors.blue),
          _iconItem(Icons.bedtime, LocalizationService().translate('sleep'), Colors.indigo),
          _iconItem(Icons.baby_changing_station, LocalizationService().translate('diaper'), Colors.purple),
          _iconItem(Icons.auto_graph, LocalizationService().translate('growth'), primaryGreen, onTap: () {
            if (_children.isNotEmpty) {
              _navigateToChildDashboard(_children.first);
            }
          }),
        ],
      ),
    );
  }

  Widget _iconItem(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Row(
        children: [
          _chipItem(LocalizationService().translate('routine'), true, null),
          const SizedBox(width: 8),
          Expanded(
            child: _chipItem(LocalizationService().translate('add_log'), false, () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const FirstAidScreen()));
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _chipItem(LocalizationService().translate('baby_assistant') ?? 'IA', false, () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _chipItem("Scanner", false, () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentScannerScreen()));
            }),
          ),
        ],
      ),
    );
  }

  Widget _chipItem(String label, bool isSelected, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
          ],
          border: isSelected ? null : Border.all(color: Colors.grey.shade200)
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade500,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNapCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/baby_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.6)]
          )
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(LocalizationService().translate('morning_nap'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(LocalizationService().translate('slept_for'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      const Text("11:00 AM", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(LocalizationService().translate('start_tracking'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black87),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 64,
        margin: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.home_filled, 0),
            _navItem(Icons.calendar_today, 1),
            _navItem(Icons.health_and_safety, 2),
            _navItem(Icons.person_outline, 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 2) {
          // Navigating to Meds Tracker or First Aid as requested
          if (_children.isNotEmpty) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MedicationTrackerScreen(child: _children.first)));
          }
        } else if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemSettingsScreen()));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon, 
          color: isSelected ? Colors.white : Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopProfile(),
                  _buildGamificationCard(),
                  _buildStatusCard(),
                  _buildGridIcons(),
                  _buildFilterChips(),
                  _buildNapCard(),
                ],
              ),
            ),
          ),
          _buildFloatingNavBar(),
        ],
      ),
    );
  }
}

// ChildDashboardScreen replacing exactly the layout of Image 3 (Activity Tracker)
class ChildDashboardScreen extends StatefulWidget {
  final ChildModel child;
  const ChildDashboardScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ConstanteModel> _constantes = [];
  bool _isLoading = true;
  
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color creamBackground = Color(0xFFFFFAF1);

  @override
  void initState() {
    super.initState();
    _loadConstantes();
  }

  Future<void> _loadConstantes() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getConstantesForChild(widget.child.id!);
    setState(() {
      _constantes = data;
      _isLoading = false;
    });
  }

  String _selectedPeriod = "Day";

  Widget _buildPeriodTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LocalizationService().translate('day'),
          LocalizationService().translate('week'),
          LocalizationService().translate('month'),
          LocalizationService().translate('year')
        ].map((period) {
          bool isSelected = _selectedPeriod == period || _selectedPeriod == "Day" && period == LocalizationService().translate('day');
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(LocalizationService().translate('daily_activity_overview'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(LocalizationService().translate('today'), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade600)
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          // Chart placeholder (simulate the layout)
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 160, width: 160,
                  child: CircularProgressIndicator(
                    value: 0.7, strokeWidth: 24,
                    color: Colors.blue.shade600,
                    backgroundColor: primaryGreen.withOpacity(0.5),
                  )
                ),
                Column(
                  children: [
                    Text(LocalizationService().translate('total_activities'), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    Text("12 ${LocalizationService().translate('logs_today')}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Legends
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(Colors.blue.shade600, "${LocalizationService().translate('feed')} (4)"),
              const SizedBox(width: 8),
              _legendItem(Colors.indigo, "${LocalizationService().translate('sleep')} (3)"),
              const SizedBox(width: 8),
              _legendItem(primaryGreen, "${LocalizationService().translate('diaper')} (3)"),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(primaryGreen.withOpacity(0.3), "${LocalizationService().translate('bath')} (1)"),
              const SizedBox(width: 8),
              _legendItem(Colors.blue.shade100, "${LocalizationService().translate('playtime')} (1)"),
            ],
          )
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade100)
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildBarsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocalizationService().translate('todays_overview'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 24),
          _barItem(LocalizationService().translate('feed'), 0.85, primaryGreen),
          _barItem(LocalizationService().translate('sleep'), 0.70, Colors.indigo.shade200),
          _barItem(LocalizationService().translate('diaper'), 0.65, Colors.blue.shade300),
          _barItem(LocalizationService().translate('hydration'), 0.45, Colors.amber.shade300),
        ],
      ),
    );
  }

  Widget _barItem(String label, double fillPct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(2)), // Sharp corners
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fillPct,
                child: Container(
                  decoration: BoxDecoration(color: color), // Sharp corners
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 8),
                  child: Text("${(fillPct * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        backgroundColor: creamBackground,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(LocalizationService().translate('activity_tracker'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.black87),
              onPressed: () {}, 
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPeriodTabs(),
            _buildOverviewCard(),
            _buildBarsCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
