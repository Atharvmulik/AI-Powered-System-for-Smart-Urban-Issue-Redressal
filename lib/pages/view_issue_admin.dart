import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/admin_issue_model.dart'; // ✅ Add this import

class IssueTrackingPage extends StatefulWidget {
  const IssueTrackingPage({super.key});

  @override
  State<IssueTrackingPage> createState() => _IssueTrackingPageState();
}

class _IssueTrackingPageState extends State<IssueTrackingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AdminIssue> _allIssues = []; // ✅ Changed to AdminIssue
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // ✅ Use the new AdminIssue method
      final issues = await ApiService().getAdminIssuesList();
      
      setState(() {
        _allIssues = issues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading issues: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ Now we can directly use status from AdminIssue
  List<AdminIssue> get pendingIssues => _allIssues.where((issue) => 
      issue.status.toLowerCase() == 'pending').toList();

  List<AdminIssue> get inProgressIssues => _allIssues.where((issue) => 
      issue.status.toLowerCase() == 'in progress').toList();

  List<AdminIssue> get resolvedIssues => _allIssues.where((issue) => 
      issue.status.toLowerCase() == 'resolved').toList();

  Future<void> _updateIssueStatus(AdminIssue issue, String newStatus) async {
    try {
      // ✅ Connect to actual API endpoint
      final response = await ApiService().updateIssueStatus(issue.id, newStatus);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          // Update local state
          _allIssues = _allIssues.map((i) => 
            i.id == issue.id ? AdminIssue(
              id: i.id,
              userName: i.userName,
              userEmail: i.userEmail,
              userMobile: i.userMobile,
              title: i.title,
              description: i.description,
              category: i.category,
              urgencyLevel: i.urgencyLevel,
              status: newStatus, // Updated status
              locationAddress: i.locationAddress,
              assignedDepartment: i.assignedDepartment,
              resolutionNotes: i.resolutionNotes,
              resolvedBy: i.resolvedBy,
              createdAt: i.createdAt,
              updatedAt: DateTime.now(),
            ) : i
          ).toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _assignToDepartment(AdminIssue issue, String department) async {
    try {
      // ✅ Connect to actual API endpoint
      final response = await ApiService().assignToDepartment(issue.id, department);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _allIssues = _allIssues.map((i) => 
            i.id == issue.id ? AdminIssue(
              id: i.id,
              userName: i.userName,
              userEmail: i.userEmail,
              userMobile: i.userMobile,
              title: i.title,
              description: i.description,
              category: i.category,
              urgencyLevel: i.urgencyLevel,
              status: i.status,
              locationAddress: i.locationAddress,
              assignedDepartment: department, // Updated department
              resolutionNotes: i.resolutionNotes,
              resolvedBy: i.resolvedBy,
              createdAt: i.createdAt,
              updatedAt: DateTime.now(),
            ) : i
          ).toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assigned to $department'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to assign department: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning department: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resolveIssue(AdminIssue issue, String resolutionNotes, String resolvedBy) async {
    try {
      // ✅ Connect to actual API endpoint
      final response = await ApiService().resolveIssue(issue.id, resolutionNotes, resolvedBy);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _allIssues = _allIssues.map((i) => 
            i.id == issue.id ? AdminIssue(
              id: i.id,
              userName: i.userName,
              userEmail: i.userEmail,
              userMobile: i.userMobile,
              title: i.title,
              description: i.description,
              category: i.category,
              urgencyLevel: i.urgencyLevel,
              status: 'Resolved', // Set to resolved
              locationAddress: i.locationAddress,
              assignedDepartment: i.assignedDepartment,
              resolutionNotes: resolutionNotes, // Updated resolution notes
              resolvedBy: resolvedBy, // Updated resolved by
              createdAt: i.createdAt,
              updatedAt: DateTime.now(),
            ) : i
          ).toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue resolved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to resolve issue: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resolving issue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteIssue(AdminIssue issue) async {
    try {
      // ✅ Connect to actual DELETE endpoint
      final response = await ApiService().deleteIssue(issue.id);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _allIssues.removeWhere((i) => i.id == issue.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to delete issue: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting issue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'garbage':
        return Icons.delete;
      case 'water':
        return Icons.water_drop;
      case 'sanitation':
        return Icons.plumbing;
      default:
        return Icons.report_problem;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ClipPath(
            clipper: CurvedHeaderClipper(),
            child: Container(
              height: 260,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Color(0xFF8C6FF7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 70.0, left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🖼 Left-side Image
                    Container(
                      height: 230,
                      width: 230,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white24,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          "assets/images/track_issue_page_image-removebg-preview.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // 📄 Right-side Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text(
                            "Track Issue Progress",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Monitor issues in real time with ease",
                            textAlign: TextAlign.right,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.deepPurple,
            labelColor: Colors.deepPurple.shade700,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Pending Issues"),
              Tab(text: "In Progress"),
              Tab(text: "Resolved"),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadIssues,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          buildIssueList(pendingIssues),
                          buildIssueList(inProgressIssues),
                          buildIssueList(resolvedIssues),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadIssues,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget buildIssueList(List<AdminIssue> issues) {
    if (issues.isEmpty) {
      return const Center(
        child: Text(
          'No issues found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];

        return MouseRegion(
          onEnter: (_) => setState(() {}),
          onExit: (_) => setState(() {}),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.deepPurple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.shade100.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              splashColor: Colors.deepPurple.withOpacity(0.2),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IssueDetailPage(
                      issue: issue,
                      onStatusUpdated: (newStatus) => _updateIssueStatus(issue, newStatus),
                      onDepartmentAssigned: (department) => _assignToDepartment(issue, department),
                      onIssueResolved: (notes, resolvedBy) => _resolveIssue(issue, notes, resolvedBy),
                      onIssueDeleted: () => _deleteIssue(issue),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Hero(
                      tag: issue.id,
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getCategoryIcon(issue.category),
                          color: Colors.deepPurple,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${issue.category} • 0.5 km", // Using fixed distance for now
                            style: TextStyle(color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "#REP${issue.id}",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            _getFormattedDate(issue.createdAt),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(issue.urgencyLevel),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        issue.urgencyLevel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    final controlPoint = Offset(size.width / 2, size.height + 50);
    final endPoint = Offset(size.width, size.height - 80);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ======================= DETAILED ISSUE PAGE ======================

class IssueDetailPage extends StatefulWidget {
  final AdminIssue issue;
  final Function(String) onStatusUpdated;
  final Function(String) onDepartmentAssigned;
  final Function(String, String) onIssueResolved;
  final VoidCallback onIssueDeleted;

  const IssueDetailPage({
    super.key,
    required this.issue,
    required this.onStatusUpdated,
    required this.onDepartmentAssigned,
    required this.onIssueResolved,
    required this.onIssueDeleted,
  });

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  late String selectedStatus;
  late String selectedDept;
  final TextEditingController _resolutionNotesController = TextEditingController();
  final TextEditingController _resolvedByController = TextEditingController();

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.issue.status;
    selectedDept = widget.issue.assignedDepartment ?? "Public Works";
    _resolvedByController.text = widget.issue.resolvedBy ?? "Admin";
    _resolutionNotesController.text = widget.issue.resolutionNotes ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.issue.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _getStatusColor(selectedStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Status: $selectedStatus",
                  style: TextStyle(
                    color: _getStatusColor(selectedStatus),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reporter Information",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildRow("Name", widget.issue.userName),
                  _buildRow("Phone", widget.issue.userMobile),
                  if (widget.issue.userEmail.isNotEmpty) 
                    _buildRow("Email", widget.issue.userEmail),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.deepPurple.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.shade100.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow("Description", widget.issue.description),
                  _buildRow("Location", widget.issue.locationAddress),
                  _buildRow("Category", widget.issue.category),
                  _buildRow(
                    "Urgency",
                    widget.issue.urgencyLevel,
                    badgeColor: _getUrgencyColor(widget.issue.urgencyLevel).withOpacity(0.2),
                    textColor: _getUrgencyColor(widget.issue.urgencyLevel),
                  ),
                  _buildRow("Reported Date", _getFormattedDate(widget.issue.createdAt)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Update Dropdowns
            const Text(
              "Update Status",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _dropdown(["Pending", "In Progress", "Resolved"], selectedStatus, (val) {
              setState(() {
                selectedStatus = val;
              });
              widget.onStatusUpdated(val);
            }),

            const SizedBox(height: 16),
            const Text(
              "Assign to Department",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _dropdown(
              ["Public Works", "Water Dept", "Road Dept", "Sanitation Dept", "Other"],
              selectedDept,
              (val) {
                setState(() {
                  selectedDept = val;
                });
                widget.onDepartmentAssigned(val);
              },
            ),

            // Resolution Notes (for Resolved status)
            if (selectedStatus == "Resolved") ...[
              const SizedBox(height: 16),
              const Text(
                "Resolution Notes",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _resolutionNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter resolution details...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Resolved By",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _resolvedByController,
                decoration: InputDecoration(
                  hintText: "Enter your name...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ✅ Buttons Row (Delete + Verify & Resolve)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showDeleteDialog(context),
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    label: const Text(
                      "Delete Issue",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedStatus == "Resolved" ? Colors.green.shade600 : Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (selectedStatus == "Resolved") {
                        _resolveIssue();
                      } else {
                        widget.onStatusUpdated("Resolved");
                        setState(() {
                          selectedStatus = "Resolved";
                        });
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: Text(
                      selectedStatus == "Resolved" ? "Confirm Resolution" : "Mark as Resolved",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value, {Color? badgeColor, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: badgeColor != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(color: textColor ?? Colors.black, fontWeight: FontWeight.bold),
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(List<String> items, String selected, ValueChanged<String> onChanged) {
    return StatefulBuilder(
      builder: (context, setInnerState) {
        String selectedValue = selected;
        TextEditingController otherController = TextEditingController();
        bool showOtherField = selectedValue == "Other";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.deepPurple.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.shade100.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: Colors.white,
                items: items
                    .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (val) {
                  setInnerState(() {
                    selectedValue = val!;
                    showOtherField = selectedValue == "Other";
                    onChanged(selectedValue);
                  });
                },
              ),
            ),

            if (showOtherField) ...[
              const SizedBox(height: 10),
              TextField(
                controller: otherController,
                decoration: InputDecoration(
                  labelText: "Enter department name",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  onChanged(value);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  void _resolveIssue() {
    if (_resolutionNotesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter resolution notes"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_resolvedByController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter who resolved this issue"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    widget.onIssueResolved(
      _resolutionNotesController.text,
      _resolvedByController.text,
    );
    Navigator.pop(context);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Issue"),
        content: const Text("Are you sure you want to delete this issue? This action cannot be undone."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text("Delete"),
            onPressed: () {
              Navigator.pop(context);
              widget.onIssueDeleted();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}