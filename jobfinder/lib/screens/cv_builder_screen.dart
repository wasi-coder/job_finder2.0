import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/gradient_background.dart';
import '../widgets/bottom_nav_bar.dart';

class CVBuilderScreen extends StatefulWidget {
  const CVBuilderScreen({super.key});

  @override
  State<CVBuilderScreen> createState() => _CVBuilderScreenState();
}

class _CVBuilderScreenState extends State<CVBuilderScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(_nameController.text, style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Paragraph(text: "${_emailController.text} | ${_phoneController.text}"),
              pw.SizedBox(height: 20),
              pw.Header(level: 1, child: pw.Text("Experience")),
              pw.Paragraph(text: _experienceController.text),
              pw.SizedBox(height: 20),
              pw.Header(level: 1, child: pw.Text("Skills")),
              pw.Paragraph(text: _skillsController.text),
            ],
          );
        },
      ),
    );

    // Save/Share/Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("CV Builder", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          automaticallyImplyLeading: false, // Hide back button for nav bar screen
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _buildTextField(_nameController, "Full Name", Icons.person),
              SizedBox(height: 12),
              _buildTextField(_emailController, "Email", Icons.email),
              SizedBox(height: 12),
              _buildTextField(_phoneController, "Phone", Icons.phone),
              SizedBox(height: 12),
              _buildTextField(_experienceController, "Experience (Summary)", Icons.work, maxLines: 5),
              SizedBox(height: 12),
              _buildTextField(_skillsController, "Skills (Comma separated)", Icons.star, maxLines: 3),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _generatePdf,
                icon: Icon(Icons.picture_as_pdf, color: Colors.black),
                label: Text("Generate & Download PDF", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD4FF00),
                  minimumSize: Size(double.infinity, 56),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 3),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}