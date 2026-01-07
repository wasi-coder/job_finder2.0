import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';
import 'post_job_screen.dart'; // Ensure this import exists
import 'apply_job_screen.dart'; // Ensure this import exists

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userType = 'employee';
  String _userName = '';
  bool _isLoading = true;
  
  // Data lists
  List<dynamic> _recommendedJobs = [];
  List<dynamic> _recentApplications = [];
  int _activeJobsCount = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final user = await ApiService.getCurrentUser();
      final type = user['user_type'] ?? 'employee';
      
      setState(() {
        _userType = type;
        _userName = user['first_name'] ?? 'User';
      });

      if (type == 'employer') {
        // Fetch Employer Stats
        final jobs = await ApiService.getJobs(); // Ideally getEmployerJobs API
        final apps = await ApiService.getEmployerApplications();
        setState(() {
          _activeJobsCount = jobs.where((j) => j['company_name'] == user['company_name']).length;
          _recentApplications = apps.take(5).toList(); // Last 5 apps
        });
      } else {
        // Fetch Job Seeker Data
        final jobs = await ApiService.getJobs(limit: 5);
        setState(() {
          _recommendedJobs = jobs;
        });
      }
    } catch (e) {
      print("Error loading home data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Custom App Bar Logic
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLoading ? "Loading..." : "Hello, $_userName 👋",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                _userType == 'employer' ? "Employer Dashboard" : "Find your dream job",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
            )
          ],
        ),
        
        body: _isLoading 
            ? Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)))
            : _userType == 'employer' 
                ? _buildEmployerHome() 
                : _buildSeekerHome(),
        
        bottomNavigationBar: BottomNavBar(currentIndex: 0),
      ),
    );
  }

  // ================== JOB SEEKER HOME ==================
  Widget _buildSeekerHome() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar
          TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search jobs, skills, companies...",
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              suffixIcon: Icon(Icons.tune, color: Color(0xFFD4FF00)), // Filter icon
            ),
          ),
          SizedBox(height: 24),

          // 2. Job Categories
          Text("Categories", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["IT & Software", "Design", "Marketing", "Finance", "Remote", "Part-time"]
                  .map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Chip(
                          label: Text(cat),
                          backgroundColor: Colors.white10,
                          labelStyle: TextStyle(color: Colors.white),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                        ),
                      ))
                  .toList(),
            ),
          ),
          SizedBox(height: 24),

          // 3. Recommended Jobs Feed
          Text("Recommended for you", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _recommendedJobs.length,
            itemBuilder: (context, index) {
              final job = _recommendedJobs[index];
              return _buildJobCard(job);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(dynamic job) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job['position'],
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Icon(Icons.bookmark_border, color: Colors.white54),
            ],
          ),
          SizedBox(height: 4),
          Text(job['company_name'] ?? 'Unknown Company', style: TextStyle(color: Color(0xFFD4FF00))),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.white54),
              SizedBox(width: 4),
              Text(job['location'], style: TextStyle(color: Colors.white54, fontSize: 12)),
              Spacer(),
              Text("\$${job['salary_min']} - \$${job['salary_max']}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ApplyJobScreen(
                    jobId: job['id'], 
                    jobTitle: job['position']
                  ),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Apply Now", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // ================== EMPLOYER HOME ==================
  Widget _buildEmployerHome() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post a Job CTA
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFD4FF00), Color(0xFFA0C000)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.add_circle_outline, size: 40, color: Colors.black),
                SizedBox(height: 10),
                Text("Hire New Talent", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Post a new job listing now", style: TextStyle(fontSize: 14)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => PostJobScreen()));
                    if (res == true) _initData(); // Refresh if posted
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  child: Text("Post a Job"),
                )
              ],
            ),
          ),
          SizedBox(height: 24),

          // 2. Dashboard Stats
          Row(
            children: [
              Expanded(child: _buildStatCard("Active Jobs", "$_activeJobsCount", Icons.business_center)),
              SizedBox(width: 16),
              Expanded(child: _buildStatCard("Total Applicants", "${_recentApplications.length}", Icons.people)),
            ],
          ),
          SizedBox(height: 24),

          // 3. Recent Activity (Latest Applications)
          Text("Recent Applications", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          _recentApplications.isEmpty 
          ? Text("No applications yet.", style: TextStyle(color: Colors.white54))
          : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _recentApplications.length,
              itemBuilder: (context, index) {
                final app = _recentApplications[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    tileColor: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: CircleAvatar(backgroundColor: Color(0xFFD4FF00), child: Icon(Icons.person, color: Colors.black)),
                    title: Text("Applicant #${app['user_id']}", style: TextStyle(color: Colors.white)),
                    subtitle: Text("Applied for Job #${app['job_id']}", style: TextStyle(color: Colors.white54)),
                    trailing: Text(app['status'], style: TextStyle(color: Colors.blueAccent)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFFD4FF00), size: 28),
          SizedBox(height: 12),
          Text(count, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}