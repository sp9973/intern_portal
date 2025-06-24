import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intern_link/screens/profile_screen.dart';

class HRInternshipDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> internship;
  const HRInternshipDetailsScreen({super.key, required this.internship});

  @override
  State<HRInternshipDetailsScreen> createState() => _HRInternshipDetailsScreenState();
}

class _HRInternshipDetailsScreenState extends State<HRInternshipDetailsScreen> {
  String _filterStatus = 'requested'; // 'requested', 'approved', 'rejected'
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('internship')
          .doc(widget.internship['id'])
          .collection('activities')
          .doc('lists')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final applicantIds = data.keys.toList();

        final applicants = await Future.wait(
          applicantIds.map((userId) async {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
            return {
              'userId': userId,
              'status': data[userId],
              ...userDoc.data() ?? {},
            };
          }),
        );

        setState(() {
          _applicants = applicants;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading applicants: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateApplicationStatus(String userId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('internship')
          .doc(widget.internship['id'])
          .collection('activities')
          .doc('lists')
          .update({userId: status});

      // Also update in user's applied collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('applied')
          .doc('internship')
          .update({widget.internship['id']: status});

      setState(() {
        _applicants = _applicants.map((applicant) {
          if (applicant['userId'] == userId) {
            return {...applicant, 'status': status};
          }
          return applicant;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application $status successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredApplicants {
    return _applicants.where((applicant) {
      return applicant['status'] == _filterStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text('Internship Details'),
        backgroundColor: const Color(0xFFF5F9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Internship Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.internship['title'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3C7C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.internship['companyName'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildDetailChip(
                        Iconsax.money,
                        widget.internship['stipend'],
                      ),
                      const SizedBox(width: 10),
                      _buildDetailChip(
                        Iconsax.location,
                        widget.internship['location'],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildDetailChip(
                        Iconsax.clock,
                        widget.internship['duration'],
                      ),
                      const SizedBox(width: 10),
                      _buildDetailChip(
                        Iconsax.calendar,
                        'Apply by ${widget.internship['applyBy']}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'About Internship:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3C7C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.internship['about']),
                  const SizedBox(height: 16),
                  const Text(
                    'Eligibility Criteria:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3C7C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.internship['eligibility']),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Applicants Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Applicants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3C7C),
                  ),
                ),
                DropdownButton<String>(
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(
                      value: 'requested',
                      child: Text('Requested'),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _filterStatus = value);
                    }
                  },
                  style: const TextStyle(
                    color: Color(0xFF1A3C7C),
                  ),
                  underline: Container(
                    height: 1,
                    color: const Color(0xFF6B92E6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Applicants List
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredApplicants.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('No applicants found'),
                        ),
                      )
                    : Column(
                        children: _filteredApplicants.map((applicant) {
                          return _buildApplicantCard(applicant);
                        }).toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF6B92E6)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFF5F9FF),
              backgroundImage: applicant['profilePicture'] != null
                  ? CachedNetworkImageProvider(applicant['profilePicture'])
                  : const AssetImage('assets/images/default_profile.png')
                      as ImageProvider,
            ),
            title: Text(
              applicant['name'] ?? 'No Name',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3C7C),
              ),
            ),
            subtitle: Text(applicant['email'] ?? ''),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(applicant['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                applicant['status'] ?? 'requested',
                style: TextStyle(
                  color: _getStatusColor(applicant['status']),
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: applicant['userId'],
                    isHR: true,
                    currentUser: const {},
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateApplicationStatus(
                        applicant['userId'], 'rejected'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateApplicationStatus(
                        applicant['userId'], 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B92E6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return const Color(0xFF6B92E6);
    }
  }
}