import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher to pubspec.yaml if you want to open CVs
import '../widgets/gradient_background.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _applications = [];
  bool _isLoading = true;
  String _userType = 'employee';
  
  // To avoid constant reloading
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _loadData();
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  Future<void> _loadData() async {
    try {
      final type = await ApiService.getUserType();
      setState(() => _userType = type);

      List<dynamic> data;
      if (type == 'employer') {
        data = await ApiService.getEmployerApplications(); 
      } else {
        data = await ApiService.getMyApplications();
      }

      setState(() {
        _applications = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error silently or show snackbar
    }
  }

  // --- EMPLOYER ACTIONS ---

  void _updateStatus(int appId, String newStatus) async {
    try {
      await ApiService.updateApplicationStatus(appId, newStatus);
      _loadData(); // Refresh list
      
      if (newStatus == 'hired') {
        _showCloseJobDialog(appId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update status")));
    }
  }

  void _showCloseJobDialog(int appId) {
    // Find the job ID from the application
    final app = _applications.firstWhere((element) => element['id'] == appId);
    final jobId = app['job_id'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Hired!", style: TextStyle(color: Colors.white)),
        content: Text(
          "Do you want to close this Job Post now? It will be removed from the job board.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: Text("Keep Open"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD4FF00)),
            child: Text("Close Job", style: TextStyle(color: Colors.black)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.closeJob(jobId);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Job Closed Successfully")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to close job")));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            _userType == 'employer' ? 'Applicant Dashboard' : 'My Applications', 
            style: TextStyle(color: Colors.white)
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: EdgeInsets.all(20),
                itemCount: _applications.length,
                itemBuilder: (context, index) {
                  final app = _applications[index];
                  return _userType == 'employer' 
                    ? _buildEmployerCard(app) 
                    : _buildEmployeeCard(app);
                },
              ),
            ),
        bottomNavigationBar: BottomNavBar(currentIndex: 2),
      ),
    );
  }

  // --- EMPLOYER CARD VIEW ---
  Widget _buildEmployerCard(dynamic app) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Applicant #${app['user_id']}", // Replace with Name if available in join
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildStatusBadge(app['status']),
            ],
          ),
          SizedBox(height: 4),
          Text("Applied for Job #${app['job_id']}", style: TextStyle(color: Colors.white54)),
          if (app['cover_message'] != null) ...[
             SizedBox(height: 8),
             Text('"${app['cover_message']}"', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
          ],
          
          SizedBox(height: 16),
          // Links
          Row(
            children: [
              if (app['cv_file'] != null) _buildLinkButton("CV", Icons.picture_as_pdf, () {
                // Logic to open PDF (Use url_launcher with backend URL + app['cv_file'])
              }),
              Spacer(),
              IconButton(
                icon: Icon(Icons.chat_bubble, color: Color(0xFFD4FF00)),
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(applicationId: app['id'], jobTitle: "Applicant #${app['user_id']}")
                  ));
                },
              )
            ],
          ),
          
          Divider(color: Colors.white24),
          
          // ACTION BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton("Shortlist", Colors.blue, () => _updateStatus(app['id'], 'shortlisted')),
              _buildActionButton("Reject", Colors.red, () => _updateStatus(app['id'], 'rejected')),
              _buildActionButton("Hire", Colors.green, () => _updateStatus(app['id'], 'hired')),
            ],
          ),
        ],
      ),
    );
  }

  // --- EMPLOYEE CARD VIEW ---
  Widget _buildEmployeeCard(dynamic app) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Job #${app['job_id']}", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              _buildStatusBadge(app['status']),
            ],
          ),
          SizedBox(height: 8),
          Text("Applied on: ${app['applied_at'].toString().split('T')[0]}", style: TextStyle(color: Colors.white54)),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.chat, color: Color(0xFFD4FF00)),
              label: Text("Message Employer", style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: Color(0xFFD4FF00))),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(applicationId: app['id'], jobTitle: "Chat with Employer")
                ));
              },
            ),
          )
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'hired': color = Colors.green; break;
      case 'shortlisted': color = Colors.blue; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.orange; // Pending
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLinkButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}