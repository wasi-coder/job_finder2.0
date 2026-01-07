import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() async {
    try {
      final jobs = await ApiService.getJobs(limit: 10);
      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Show error or fallback to hardcoded jobs
      _loadFallbackJobs();
    }
  }

  void _loadFallbackJobs() {
    setState(() {
      _jobs = [
        {
          'company': 'Google Inc.',
          'position': 'Senior UI/UX Designer',
          'location': 'California, USA',
          'salary': '\$120K - \$150K',
        },
        {
          'company': 'Meta',
          'position': 'Flutter Developer',
          'location': 'Remote',
          'salary': '\$100K - \$130K',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning 👋',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                'Find your dream job',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                    SizedBox(width: 12),
                    Text(
                      'Search for jobs...',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Featured Jobs
              Text(
                'Featured Jobs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              if (_isLoading)
                Center(child: CircularProgressIndicator(color: Colors.white))
              else if (_jobs.isEmpty)
                Center(
                  child: Text(
                    'No jobs available',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                Column(
                  children:
                      _jobs
                          .map(
                            (job) => Column(
                              children: [
                                _JobCard(
                                  companyName: job['company'] ?? 'Company',
                                  position: job['title'] ?? 'Position',
                                  location: job['location'] ?? 'Location',
                                  salary: job['salary_range'] ?? 'Salary TBD',
                                ),
                                SizedBox(height: 12),
                              ],
                            ),
                          )
                          .toList(),
                ),
              SizedBox(height: 24),

              // Categories
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _CategoryCard(
                    icon: Icons.design_services,
                    title: 'Design',
                    jobs: '1200+',
                  ),
                  _CategoryCard(
                    icon: Icons.bar_chart,
                    title: 'Business',
                    jobs: '800+',
                  ),
                  _CategoryCard(
                    icon: Icons.medical_services,
                    title: 'Medical',
                    jobs: '950+',
                  ),
                  _CategoryCard(
                    icon: Icons.school,
                    title: 'Education',
                    jobs: '600+',
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 0),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String companyName;
  final String position;
  final String location;
  final String salary;

  const _JobCard({
    required this.companyName,
    required this.position,
    required this.location,
    required this.salary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.business, color: Colors.white, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      position,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.bookmark_border, color: Colors.white),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              Spacer(),
              Text(
                salary,
                style: TextStyle(
                  color: Color(0xFF00D9A5),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String jobs;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.jobs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/jobs', arguments: {'category': title});
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$jobs Jobs',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
