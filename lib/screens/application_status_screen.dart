import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ApplicationStatusScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const ApplicationStatusScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ApplicationStatusScreen> createState() =>
      _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  String _selectedFilter = 'all';
  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      setState(() => _isLoading = true);

      // Get all applications from user's applied collection
      final appliedInternships = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser['userId'])
          .collection('applied')
          .doc('internship')
          .get();

      final appliedJobs = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser['userId'])
          .collection('applied')
          .doc('job')
          .get();

      final allApplications = <Map<String, dynamic>>[];

      // Process internship applications
      if (appliedInternships.exists) {
        final internshipData =
            appliedInternships.data() as Map<String, dynamic>;
        for (var entry in internshipData.entries) {
          if (entry.value is String) {
            // Ensure it's a status entry
            final internshipDoc = await FirebaseFirestore.instance
                .collection('internship')
                .doc(entry.key)
                .get();

            if (internshipDoc.exists) {
              final internship = internshipDoc.data()!;
              final company = await _getCompanyData(internship['postedBy']);

              allApplications.add({
                'id': entry.key,
                'type': 'internship',
                'title': internship['title'],
                'companyLogo': company['logo'],
                'companyName': company['name'],
                'location': internship['location'],
                'stipend': internship['stipen'],
                'duration': internship['duration'],
                'applyBy': internship['applyBy'],
                'status': entry.value,
                'appliedOn':
                    'Recently', // You might want to store actual date in your DB
              });
            }
          }
        }
      }

      // Process job applications
      if (appliedJobs.exists) {
        final jobData = appliedJobs.data() as Map<String, dynamic>;
        for (var entry in jobData.entries) {
          if (entry.value is String) {
            // Ensure it's a status entry
            final jobDoc = await FirebaseFirestore.instance
                .collection('jobs')
                .doc(entry.key)
                .get();

            if (jobDoc.exists) {
              final job = jobDoc.data()!;
              final company = await _getCompanyData(job['postedBy']);

              allApplications.add({
                'id': entry.key,
                'type': 'job',
                'title': job['title'],
                'companyLogo': company['logo'],
                'companyName': company['name'],
                'location': job['location'],
                'salary': job['salary'],
                'lastDate': job['lastDate'],
                'status': entry.value,
                'appliedOn':
                    'Recently', // You might want to store actual date in your DB
              });
            }
          }
        }
      }

      setState(() {
        _applications = allApplications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading applications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _getCompanyData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data() ?? {};
    } catch (e) {
      print('Error loading company data: $e');
      return {};
    }
  }

  List<Map<String, dynamic>> get _filteredApplications {
    if (_selectedFilter == 'all') return _applications;
    return _applications
        .where((app) => app['status'] == _selectedFilter)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'requested':
        return const Color.fromARGB(255, 107, 146, 230);
      default:
        return Colors.grey;
    }
  }

  Color _getCardColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFFE8F5E9); // Light green
      case 'rejected':
        return const Color(0xFFFFEBEE); // Light red
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFF5F9FF),
            elevation: 0,
            pinned: true,
            title: const Text(
              'My Applications',
              style: TextStyle(
                color: Color.fromARGB(255, 26, 60, 124),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Requested', 'requested'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', 'approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'rejected'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _isLoading
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: const Color.fromARGB(255, 107, 146, 230),
                      ),
                    ),
                  ),
                )
              : _filteredApplications.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.note_remove,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No applications found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _selectedFilter == 'all'
                                  ? 'You haven\'t applied to anything yet'
                                  : 'No $_selectedFilter applications',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final application = _filteredApplications[index];
                          return _buildApplicationCard(application);
                        },
                        childCount: _filteredApplications.length,
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: const Color.fromARGB(255, 107, 146, 230),
      labelStyle: TextStyle(
        color: _selectedFilter == value
            ? Colors.white
            : const Color.fromARGB(255, 26, 60, 124),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      side: BorderSide(
        color: _selectedFilter == value
            ? const Color.fromARGB(255, 107, 146, 230)
            : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final isJob = application['type'] == 'job';
    final statusColor = _getStatusColor(application['status']);
    final cardColor = _getCardColor(application['status']);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFF5F9FF),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: application['companyLogo'] ?? '',
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/default_company.png',
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromARGB(255, 26, 60, 124),
                        ),
                      ),
                      Text(
                        isJob ? 'Job Application' : 'Internship Application',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    application['status'].toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDetailItem(Iconsax.calendar,
                    application['appliedOn'] ?? 'Unknown date'),
                const SizedBox(width: 16),
                _buildDetailItem(
                    Iconsax.location, application['location'] ?? 'Remote'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDetailItem(
                  Iconsax.money,
                  isJob
                      ? application['salary'] ?? 'Not specified'
                      : application['stipend'] ?? 'Not specified',
                ),
                const SizedBox(width: 16),
                _buildDetailItem(
                  Iconsax.clock,
                  isJob
                      ? 'Full-time'
                      : application['duration'] ?? 'Not specified',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (application['status'] == 'approved')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle interview scheduling
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 107, 146, 230),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color.fromARGB(255, 107, 146, 230),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
