import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../services/api_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  
  String _jobType = 'Full-time';
  String _category = 'Technology';
  bool _isLoading = false;

  final List<String> _categories = [
    "Technology", "Healthcare", "Finance", "Education", 
    "Marketing", "Sales", "Engineering", "Design", "Other"
  ];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final jobData = {
        'position': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'salary_min': int.tryParse(_minSalaryController.text) ?? 0,
        'salary_max': int.tryParse(_maxSalaryController.text) ?? 0,
        'job_type': _jobType,
        'category': _category,
      };

      await ApiService.postJob(jobData);
      if (!mounted) return;
      Navigator.pop(context, true); // Return "true" to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("Post a Job", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Job Details"),
                _buildTextField(_titleController, "Job Title", Icons.work),
                SizedBox(height: 12),
                _buildTextField(_descriptionController, "Description", Icons.description, maxLines: 4),
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(child: _buildDropdown("Category", _category, _categories, (val) => setState(() => _category = val!))),
                    SizedBox(width: 12),
                    Expanded(child: _buildDropdown("Type", _jobType, ['Full-time', 'Part-time', 'Contract', 'Remote'], (val) => setState(() => _jobType = val!))),
                  ],
                ),
                SizedBox(height: 12),
                
                _buildTextField(_locationController, "Location", Icons.location_on),
                SizedBox(height: 12),
                
                _buildLabel("Salary Range"),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_minSalaryController, "Min", Icons.attach_money, isNumber: true)),
                    SizedBox(width: 12),
                    Expanded(child: _buildTextField(_maxSalaryController, "Max", Icons.attach_money, isNumber: true)),
                  ],
                ),
                SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD4FF00)),
                    child: _isLoading 
                      ? CircularProgressIndicator() 
                      : Text("Post Job", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white),
      validator: (val) => val!.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70)),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: Colors.grey[800],
            style: TextStyle(color: Colors.white),
            underline: SizedBox(),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}