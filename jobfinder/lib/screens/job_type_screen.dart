import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';

class JobTypeScreen extends StatefulWidget {
  const JobTypeScreen({super.key});

  @override
  State<JobTypeScreen> createState() => _JobTypeScreenState();
}

class _JobTypeScreenState extends State<JobTypeScreen> {
  int selected = 0; // 0: Find Job, 1: Find Employee

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Option',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Choose ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Job Type',
                          style: TextStyle(color: Color(0xFF00D9A5)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Are you looking for a new job or\nlooking for new employees?',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.yellow.shade100,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      _TypeCard(
                        selected: selected == 0,
                        icon: Icons.work,
                        title: 'Find a job',
                        subtitle:
                            "It's easy to find your\ndream jobs here with us.",
                        onTap: () => setState(() => selected = 0),
                      ),
                      SizedBox(width: 18),
                      _TypeCard(
                        selected: selected == 1,
                        icon: Icons.person_search,
                        title: 'Find Employee',
                        subtitle:
                            "It's easy to find your\nemployees here with us.",
                        onTap: () => setState(() => selected = 1),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00D9A5),
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Define colors based on selection state
    final backgroundColor =
        selected
            ? Color(0xFF00D9A5).withOpacity(0.25)
            : Colors.white.withOpacity(0.2);
    final borderColor =
        selected ? Color(0xFF00D9A5) : Colors.white.withOpacity(0.4);
    final iconBackground =
        selected ? Color(0xFF00D9A5) : Colors.white.withOpacity(0.3);
    final titleColor = selected ? Colors.black87 : Colors.white;
    final subtitleColor = selected ? Colors.black87 : Colors.white;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12),
          constraints: BoxConstraints(maxHeight: 180),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: Color(0xFF00D9A5).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: Color(0xFF00D9A5).withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: selected ? Colors.white : Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
