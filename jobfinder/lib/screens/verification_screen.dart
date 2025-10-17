import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../services/api_service.dart';

class VerificationScreen extends StatefulWidget {
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  List<String> code = List.filled(6, '');
  List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  List<TextEditingController> controllers = List.generate(6, (_) => TextEditingController());

  bool _isLoading = false;
  late int userId;
  late String email;
  String? verificationCode; // For debugging - remove in production

  @override
  void initState() {
    super.initState();
    // Get arguments passed from registration or login screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        userId = args['user_id'];
        email = args['email'] ?? args['phone']; // Support both email and phone
        verificationCode = args['verification_code']; // For debugging
        setState(() {}); // Trigger rebuild to show email/phone
      }
    });
  }

  @override
  void dispose() {
    for (var node in focusNodes) {
      node.dispose();
    }
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _verify() async {
    if (_isLoading) return;

    // Check if all code digits are filled
    final verificationCode = code.join();
    if (verificationCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the complete 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.verifyCode(userId, verificationCode);

      // Navigate to home on successful verification
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resendCode() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.resendCode(userId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification code resent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend code: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                'Verification',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 40),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mail_outline, size: 60, color: Colors.white),
              ),
              SizedBox(height: 40),
              Text(
                'Verification code',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 16),
              Column(
                children: [
                  Text(
                    'Enter the verification code we\'ve sent to your\n${email ?? 'email'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),
                  ),
                  if (verificationCode != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Debug: Code is $verificationCode',
                      style: TextStyle(fontSize: 12, color: Colors.yellow.withOpacity(0.8)),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (idx) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: code[idx].isNotEmpty
                            ? Color(0xFF9D8FFF).withOpacity(0.5)
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: code[idx].isNotEmpty ? Color(0xFF9D8FFF) : Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: controllers[idx],
                        focusNode: focusNodes[idx],
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() => code[idx] = val);
                          if (val.isNotEmpty && idx < 5) {
                            focusNodes[idx + 1].requestFocus();
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                        ),
                      )
                    : Text('Confirm', style: TextStyle(fontSize: 16, color: Colors.black87)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                  backgroundColor: Color(0xFFD4FF00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _resendCode,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),
                      children: [
                        TextSpan(text: "Didn't receive the code? "),
                        TextSpan(
                          text: 'Resend',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9D8FFF)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}