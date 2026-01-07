import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data'; // For Web Bytes
import 'package:flutter/foundation.dart' show kIsWeb; // To check if Web
import '../widgets/gradient_background.dart';
import '../services/api_service.dart';

class ApplyJobScreen extends StatefulWidget {
  final int jobId;
  final String jobTitle;

  const ApplyJobScreen({super.key, required this.jobId, required this.jobTitle});

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  final _messageController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();
  
  String? _selectedFileName;
  String? _selectedFilePath;      // For Mobile
  Uint8List? _selectedFileBytes;  // For Web
  bool _isLoading = false;

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Important for Web!
    );

    if (result != null) {
      final file = result.files.single;
      setState(() {
        _selectedFileName = file.name;
        if (kIsWeb) {
          _selectedFileBytes = file.bytes;
        } else {
          _selectedFilePath = file.path;
        }
      });
    }
  }

  void _submitApplication() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.applyForJob(
        jobId: widget.jobId,
        message: _messageController.text,
        linkedin: _linkedinController.text.isEmpty ? null : _linkedinController.text,
        github: _githubController.text.isEmpty ? null : _githubController.text,
        portfolio: _portfolioController.text.isEmpty ? null : _portfolioController.text,
        // Pass everything; ApiService will decide which to use
        filePath: _selectedFilePath,
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Applied successfully!")));
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
          title: Text("Apply for ${widget.jobTitle}", style: TextStyle(color: Colors.white, fontSize: 16)),
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Cover Letter / Message"),
              _buildTextField(_messageController, "Tell us why you are a good fit...", Icons.message, maxLines: 4),
              SizedBox(height: 20),

              _buildSectionTitle("Resume / CV (PDF)"),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24)
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: Color(0xFFD4FF00), size: 40),
                    SizedBox(height: 10),
                    Text(
                      _selectedFileName ?? "No file selected",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _pickFile,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFFD4FF00)),
                      ),
                      child: Text("Select PDF", style: TextStyle(color: Color(0xFFD4FF00))),
                    )
                  ],
                ),
              ),
              SizedBox(height: 20),

              _buildSectionTitle("Links"),
              _buildTextField(_linkedinController, "LinkedIn Profile URL", Icons.link),
              SizedBox(height: 10),
              _buildTextField(_githubController, "GitHub Profile URL", Icons.code),
              SizedBox(height: 10),
              _buildTextField(_portfolioController, "Portfolio URL", Icons.web),

              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD4FF00)),
                  child: _isLoading 
                    ? CircularProgressIndicator() 
                    : Text("Submit Application", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}