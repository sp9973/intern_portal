import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intern_link/screens/EditHrDetailsScreen.dart';
import 'package:intern_link/screens/LoginScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class HRProfileScreen extends StatefulWidget {
  final String userId;
  const HRProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HRProfileScreen> createState() => _HRProfileScreenState();
}

class _HRProfileScreenState extends State<HRProfileScreen> {
  late Future<Map<String, dynamic>> _userData;
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  int _postedInternshipsCount = 0;
  int _postedJobsCount = 0;

  @override
  void initState() {
    super.initState();
    _userData = _fetchUserData();
    _fetchPostedCounts();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!doc.exists) {
        throw Exception('User not found');
      }

      final data = doc.data()!;
      setState(() {
        _user = data;
        _isLoading = false;
      });
      return data;
    } catch (e) {
      setState(() => _isLoading = false);
      throw Exception('Failed to load user data: $e');
    }
  }

  Future<void> _fetchPostedCounts() async {
    try {
      final internships = await FirebaseFirestore.instance
          .collection('internship')
          .where('postedBy', isEqualTo: widget.userId)
          .get();

      final jobs = await FirebaseFirestore.instance
          .collection('jobs')
          .where('postedBy', isEqualTo: widget.userId)
          .get();

      setState(() {
        _postedInternshipsCount = internships.size;
        _postedJobsCount = jobs.size;
      });
    } catch (e) {
      print('Error fetching posted counts: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F9FF),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6B92E6),
          ),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F9FF),
        body: Center(
          child: Text(
            'Failed to load profile',
            style: TextStyle(
              color: Color(0xFF1A3C7C),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFF5F9FF),
            expandedHeight: 220,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFC5DAF3),
                      Color(0xFF95DBEC),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 46,
                        backgroundImage: _user!['logo'] != null
                            ? CachedNetworkImageProvider(_user!['logo'])
                            : const AssetImage(
                                    'assets/images/default_company.png')
                                as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _user!['name'] ?? 'Company Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'HR Representative',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.logout,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditHrDetailsScreen(
                              hrData: _user!, // Your HR user data map
                              onSave: (updatedData) async {
                                // Handle the save operation
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(_user!['userId'])
                                    .update(updatedData);
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Iconsax.edit, size: 18),
                      label: const Text('Edit Company Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(
                          color: Color(0xFF6B92E6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Company Stats
                  _buildSectionTitle('Company Stats'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          value: _postedInternshipsCount.toString(),
                          label: 'Posted Internships',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          value: _postedJobsCount.toString(),
                          label: 'Posted Jobs',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Company Information Section
                  _buildSectionTitle('Company Information'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Iconsax.sms,
                    title: 'Email',
                    value: _user!['email'] ?? 'Not provided',
                  ),
                  const SizedBox(height: 12),
                  if (_user!['description'] != null) ...[
                    _buildInfoCard(
                      icon: Iconsax.note_text,
                      title: 'Description',
                      value: _user!['description'],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_user!['website'] != null) ...[
                    GestureDetector(
                      onTap: () => _launchURL(_user!['website']),
                      child: _buildInfoCard(
                        icon: Iconsax.global,
                        title: 'Website',
                        value: _user!['website'],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Contact Information
                  _buildSectionTitle('Contact Information'),
                  const SizedBox(height: 12),
                  _buildContactButton(
                    icon: Iconsax.global,
                    label: 'Visit Website',
                    onTap: () => _launchURL(_user!['website'] ?? ''),
                  ),
                  const SizedBox(height: 12),
                  _buildContactButton(
                    icon: Iconsax.sms,
                    label: 'Contact Support',
                    onTap: () {
                      // Handle contact support
                    },
                  ),
                  const SizedBox(height: 24),

                  // Settings
                  _buildSectionTitle('Settings'),
                  const SizedBox(height: 12),
                  _buildPrivacyPolicyButton(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A3C7C),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3C7C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF6B92E6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A3C7C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6B92E6),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A3C7C),
                ),
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              color: Color(0xFF6B92E6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Privacy Policy'),
            content: SingleChildScrollView(
              child: Text(
                _privacyPolicyText,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Iconsax.shield_tick,
              color: Color(0xFF6B92E6),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A3C7C),
                ),
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              color: Color(0xFF6B92E6),
            ),
          ],
        ),
      ),
    );
  }

  final String _privacyPolicyText = '''
1. Information Collection:
We collect company information including name, logo, description, and contact details when you create an HR account.

2. Use of Information:
Your information is used to:
- Create and manage your company profile
- Display your job postings
- Verify your organization
- Communicate important updates

3. Data Sharing:
Your company information is visible to job seekers who view your postings. We never sell your data to third parties.

4. Data Security:
We implement industry-standard security measures including encryption and secure servers to protect your information.

5. Your Rights:
You can:
- Access and review your data
- Update or correct information
- Delete your account
- Request a copy of your data

6. Changes to Policy:
We will notify you of any significant changes to this policy via email or in-app notification.

7. Contact Us:
For any questions about your data or this policy, please contact:
privacy@internlink.com
''';
}
