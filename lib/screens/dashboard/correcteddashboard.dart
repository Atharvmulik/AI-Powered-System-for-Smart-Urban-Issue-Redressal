import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../guide/guide.dart';
import '../track/trackissueimage.dart';
import '../report/issuereport.dart' as report;

class CivicEyeApp extends StatelessWidget {
  const CivicEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CivicEye',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.teal,
          secondary: Colors.green,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.teal.shade50,
          selectedColor: Colors.teal,
          disabledColor: Colors.grey.shade200,
          labelStyle: const TextStyle(color: Colors.black),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // small user variable to keep names consistent
  final String _userName = 'Siddhi';

  void _showGuideOverlay() {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => GuideOverlay(
      onFinish: () {
        overlayEntry.remove();
      },
    ),
  );

  overlay.insert(overlayEntry);
}


  int _bottomIndex = 0;

  // Fake numbers just for interactivity
  double resolvedPctToday = 0.62; // 62%

  final categories = const [
    _IssueCategory('Pothole', Icons.traffic),
    _IssueCategory('Water', Icons.water_drop),
    _IssueCategory('Garbage', Icons.delete_outline),
    _IssueCategory('Lights', Icons.light_mode_outlined),
  ];

  final reportedIssues = [
    IssueCardData(
      title: 'Open pothole near Gate 2',
      type: 'Pothole',
      urgency: 0.8,
      distanceKm: 0.4,
    ),
    IssueCardData(
      title: 'Garbage overflow at Block A',
      type: 'Garbage',
      urgency: 0.6,
      distanceKm: 1.1,
    ),
    IssueCardData(
      title: 'Streetlight not working',
      type: 'Lights',
      urgency: 0.5,
      distanceKm: 0.7,
    ),
    IssueCardData(
      title: 'Water leak opposite canteen',
      type: 'Water',
      urgency: 0.9,
      distanceKm: 0.2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.radio_button_checked,
              color: Colors.teal,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'CivicEye',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showGuideOverlay();
            },
            icon: const Icon(Icons.help_outline), // Guide icon
          ),
          IconButton(
            onPressed: () {
              // Notifications logic here if needed
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _openProfileSheet(context),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal,
                child: Text(
                  'S',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _greetingCard(cs),
                const SizedBox(height: 12),
                _reportedSection(cs),
                const SizedBox(height: 18),
                _reportIssueSection(cs),
                const SizedBox(height: 18),
                _resolvedTodaySection(cs),
                const SizedBox(height: 18),
                _recentActivityList(),
              ],
            ),
          ),
          _trackNearbyBar(context),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (i) => setState(() => _bottomIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.add), label: 'Report'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => report.ReportIssuePage(
                category: "General", // 👈 you can prefill or remove if not required
              ),
            ),
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Report issue'),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _greetingCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[800],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12), // softened border
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $_userName! ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Make your city better today',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _quickChip('Track', Icons.location_on, () {}),
                    _quickChip('Nearby Issues', Icons.receipt_long, () {}),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.map_outlined, size: 50, color: Colors.white),
        ],
      ),
    );
  }

  Widget _reportedSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Reported issues',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180, // give enough height for cards
          child: ListView.separated(
            scrollDirection: Axis.horizontal, // 👈 horizontal
            physics: const BouncingScrollPhysics(), // 👈 makes it scroll smoothly
            itemCount: reportedIssues.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = reportedIssues[index];
              return _IssueCard(
                data: item,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackIssuePage(
                        issue: item,
                      ), // 👈 pass the tapped issue
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _reportIssueSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report issue',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final c in categories)
              _CategoryTile(
                category: c,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => report.ReportIssuePage(category: c.title),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _resolvedTodaySection(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CustomPaint(
              painter: _DonutPainter(
                value: resolvedPctToday,
                bgColor: Colors.teal.shade100,
                fgColor: Colors.green.shade600,
              ),
              child: Center(
                child: Text(
                  '${(resolvedPctToday * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Issues resolved today',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                _miniBar('Pothole', 0.7, Colors.teal.shade700),
                _miniBar('Water', 0.5, Colors.green.shade700),
                _miniBar('Garbage', 0.6, Colors.black87),
                _miniBar('Lights', 0.45, Colors.grey.shade800),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivityList() {
    final items = [
      const _ActivityItem(
        icon: Icons.check_circle_outline,
        title: 'Ward 12 cleared garbage pile',
        subtitle: 'Confirmed by 8 citizens',
      ),
      const _ActivityItem(
        icon: Icons.warning_amber_outlined,
        title: 'New pothole reported near Library Rd',
        subtitle: 'Urgency: High',
      ),
      const _ActivityItem(
        icon: Icons.light_mode_outlined,
        title: '2 streetlights fixed in Block C',
        subtitle: 'Marked Resolved',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _trackNearbyBar(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 78,
      child: GestureDetector(
        onTap: () => _showSnack('Showing nearby issues…'), // 👈 close onTap properly
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: const [
              Icon(Icons.my_location, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Track nearby issues',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers
  Widget _quickChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: Colors.teal.shade800),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.teal.shade200),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _miniBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 80, child: Text(label)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openIssue(BuildContext context, IssueCardData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Type: ${data.type}'),
            const SizedBox(height: 6),
            Text('Distance: ${data.distanceKm.toStringAsFixed(1)} km'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _showSnack('Subscribed to updates'),
                    child: const Text('Follow updates'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showSnack('Opening directions…'),
                    child: const Text('Get directions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.teal,
              child: Text(_userName.isNotEmpty ? _userName[0] : 'S', style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Text(
              _userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text('Ward 12, Volunteer'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.data, required this.onTap});
  final IssueCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.place, size: 18, color: Colors.teal),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                _UrgencyPill(value: data.urgency),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(data.type, style: TextStyle(color: Colors.grey.shade800)),
                const Spacer(),
                Icon(
                  Icons.directions_walk,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  '${data.distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgencyPill extends StatelessWidget {
  const _UrgencyPill({required this.value});
  final double value; // 0..1
  @override
  Widget build(BuildContext context) {
    Color bg;
    if (value > 0.75) {
      bg = Colors.red.shade600;
    } else if (value > 0.5) {
      bg = Colors.orange.shade600;
    } else {
      bg = Colors.green.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text(
        'Urgency',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class IssueCardData {
  IssueCardData({
    required this.title,
    required this.type,
    required this.urgency,
    required this.distanceKm,
  });
  final String title;
  final String type;
  final double urgency; // 0..1
  final double distanceKm;
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final _IssueCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            border: Border.all(
              color: Colors.blue.shade200, // 👈 ultramarine blue border
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(category.icon, color: Colors.blue.shade400),
              const SizedBox(height: 6),
              Text(
                category.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueCategory {
  final String title;
  final IconData icon;
  const _IssueCategory(this.title, this.icon);
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade600),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.value,
    required this.bgColor,
    required this.fgColor,
  });
  final double value; // 0..1
  final Color bgColor;
  final Color fgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 12.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = bgColor;

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = fgColor;

    // Background circle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      base,
    );
    // Foreground arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.bgColor != bgColor || oldDelegate.fgColor != fgColor;
  }
}

class _ReportIssueSheet extends StatefulWidget {
  const _ReportIssueSheet(this.prefill);
  final String? prefill;

  @override
  State<_ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<_ReportIssueSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedType = 'Pothole';

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) _selectedType = widget.prefill!;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                height: 5,
                width: 48,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const Text(
              'Report new issue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'Pothole', child: Text('Pothole')),
                DropdownMenuItem(value: 'Water', child: Text('Water leak')),
                DropdownMenuItem(value: 'Garbage', child: Text('Garbage')),
                DropdownMenuItem(value: 'Lights', child: Text('Street lights')),
              ],
              onChanged: (v) => setState(() => _selectedType = v ?? _selectedType),
              decoration: const InputDecoration(
                labelText: 'Issue type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Short title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Add photo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Use GPS'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Issue submitted')),
                );
              },
              child: const Text('Submit'),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}