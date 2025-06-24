import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intern_link/screens/EditDetailsScreen.dart';
import 'package:intern_link/screens/LoginScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final bool isHR;
  final Map<String, dynamic> currentUser;

  const ProfileScreen({Key? key, required this.userId, required this.isHR,required this.currentUser})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _userData;
  bool _isLoading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _userData = _fetchUserData();
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

  void _viewResume() {
    if (_user?['resumeUrl'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resume available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Resume'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    // Try converting PDF URL to JPG automatically
                    _user!['resumeUrl'].toString().replaceAll('.pdf', '.jpg'),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'Failed to load resume preview image.\nPlease open the full resume below.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
        backgroundColor: const Color(0xFFF5F9FF),
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

    final isEmployer = _user!['jobSeeker'] == false;
    final skillsData = _user!['Skills'];

    final skills = skillsData is List
        ? skillsData
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : skillsData is String
            ? (skillsData as String)
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[];
    print("user skills: ${_user!['Skills']}");
    print("skills: $skills");

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
                        backgroundImage: _user!['profilePicture'] != null
                            ? CachedNetworkImageProvider(
                                _user!['profilePicture'])
                            : const AssetImage(
                                    'assets/images/default_profile.png')
                                as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _user!['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isEmployer ? 'Employer' : 'Job Seeker',
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
              widget.isHR
                  ? const Center()
                  : IconButton(
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
                  widget.isHR
                      ? const Center()
                      : SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditDetailsScreen(
                                    userData: widget.currentUser,
                                    onSave: (updatedData) async {
                                      // Handle the save operation here
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(widget.currentUser['userId'])
                                          .update(updatedData);
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Iconsax.edit, size: 18),
                            label: const Text('Edit Profile'),
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

                  // Personal Information Section
                  _buildSectionTitle('Personal Information'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Iconsax.sms,
                    title: 'Email',
                    value: _user!['email'] ?? 'Not provided',
                  ),
                  const SizedBox(height: 12),
                  if (_user!['Experience'] != null) ...[
                    _buildInfoCard(
                      icon: Iconsax.briefcase,
                      title: 'Experience',
                      value: _user!['Experience'],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_user!['Education'] != null) ...[
                    _buildInfoCard(
                      icon: Iconsax.book,
                      title: 'Education',
                      value: _user!['Education'],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Skills Section with Bubbles
                  if (skills.isNotEmpty) ...[
                    _buildSectionTitle('My Skills'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills
                          .map((skill) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5EFFF),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  skill,
                                  style: const TextStyle(
                                    color: Color(0xFF1A3C7C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Resume Section
                  _buildSectionTitle('My Resume'),
                  const SizedBox(height: 12),
                  _buildResumeButton(),
                  const SizedBox(height: 24),

                  // Privacy Policy
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

  Widget _buildResumeButton() {
    return GestureDetector(
      onTap: _viewResume,
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
        child: const Row(
          children: [
            Icon(
              Iconsax.document_text,
              color: Color(0xFF6B92E6),
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'View Resume',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A3C7C),
                ),
              ),
            ),
            Icon(
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
            Icon(
              Iconsax.arrow_right_3,
              color: const Color(0xFF6B92E6),
            ),
          ],
        ),
      ),
    );
  }

  final String _privacyPolicyText = '''
1. Information Collection:
We collect personal information including your name, email, education, skills, and work experience when you create an account.

2. Use of Information:
Your information is used to:
- Create and manage your profile
- Connect you with potential employers
- Improve our services
- Communicate important updates

3. Data Sharing:
Your profile information is only shared with employers when you apply for positions. We never sell your data to third parties.

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
