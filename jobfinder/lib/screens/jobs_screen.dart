import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  List<dynamic> _jobs = [];
  bool _isLoading = true;
  String? _category;
  String? _userType;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    final userType = await ApiService.getUserType();
    setState(() => _userType = userType);

    // Get category from route arguments if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('category')) {
        setState(() => _category = args['category'] as String);
      }
      _loadJobs();
    });
  }

  void _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await ApiService.getJobs(
        category: _category,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load jobs: $e')));
    }
  }

  void _searchJobs() {
    _loadJobs();
  }

  void _postNewJob() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _JobPostDialog(),
    );

    if (result != null) {
      try {
        await ApiService.postJob(result);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Job posted successfully')));
        _loadJobs();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post job: $e')));
      }
    }
  }

  void _applyForJob(dynamic job) async {
    final message = await showDialog<String>(
      context: context,
      builder: (context) => _JobApplicationDialog(),
    );

    if (message != null) {
      try {
        await ApiService.applyForJob(job['id'], message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application submitted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to apply: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _category ?? 'All Jobs',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            if (_userType == 'employer')
              IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: _postNewJob,
              ),
            IconButton(
              icon: Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search jobs...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _searchJobs();
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
                onSubmitted: (_) => _searchJobs(),
              ),
            ),
            // Jobs list
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : _jobs.isEmpty
                      ? Center(
                        child: Text(
                          'No jobs found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                      : ListView.builder(
                        padding: EdgeInsets.all(20),
                        itemCount: _jobs.length,
                        itemBuilder: (context, index) {
                          final job = _jobs[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
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
                                      child: Icon(
                                        Icons.business,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job['company_name'] ?? 'Company',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            job['position'] ?? 'Job Position',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_userType == 'employee')
                                      IconButton(
                                        icon: Icon(
                                          Icons.send,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => _applyForJob(job),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${job['type'] ?? 'Full-time'} • ${job['location'] ?? 'Remote'}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
      ),
    );
  }
}

class _JobPostDialog extends StatefulWidget {
  @override
  _JobPostDialogState createState() => _JobPostDialogState();
}

class _JobPostDialogState extends State<_JobPostDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  String _jobType = 'Full-time';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Post a New Job'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Job Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: _salaryController,
              decoration: InputDecoration(labelText: 'Salary Range'),
            ),
            DropdownButtonFormField<String>(
              value: _jobType,
              items:
                  ['Full-time', 'Part-time', 'Contract', 'Freelance']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _jobType = value!),
              decoration: InputDecoration(labelText: 'Job Type'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isEmpty ||
                _descriptionController.text.isEmpty) {
              return;
            }
            Navigator.pop(context, {
              'position': _titleController.text,
              'description': _descriptionController.text,
              'location': _locationController.text,
              'salary_range': _salaryController.text,
              'type': _jobType,
            });
          },
          child: Text('Post'),
        ),
      ],
    );
  }
}

class _JobApplicationDialog extends StatefulWidget {
  @override
  _JobApplicationDialogState createState() => _JobApplicationDialogState();
}

class _JobApplicationDialogState extends State<_JobApplicationDialog> {
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Apply for Job'),
      content: TextField(
        controller: _messageController,
        decoration: InputDecoration(
          labelText: 'Message to Employer',
          hintText: 'Introduce yourself and explain why you\'re a good fit...',
        ),
        maxLines: 5,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_messageController.text.isEmpty) return;
            Navigator.pop(context, _messageController.text);
          },
          child: Text('Send Application'),
        ),
      ],
    );
  }
}
