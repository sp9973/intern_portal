import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intern_link/screens/internship_detail_screen.dart';
import 'package:intern_link/screens/job_detail_screen.dart';

class SavedItemsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> savedListings;
  final Map<String, dynamic> currentUser;

  const SavedItemsScreen({
    Key? key,
    required this.savedListings,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  int _activeTab = 0; // 0 = Internships, 1 = Jobs
  bool _isLoading = false;

  // Separate internships and jobs from saved listings
  List<Map<String, dynamic>> get _savedInternships {
    return widget.savedListings
        .where((item) => item['type'] == 'internship')
        .toList();
  }

  List<Map<String, dynamic>> get _savedJobs {
    return widget.savedListings.where((item) => item['type'] == 'job').toList();
  }

  Future<void> _removeSavedItem(String id) async {
    setState(() => _isLoading = true);
    try {
      final saved = List<String>.from(widget.currentUser['saved'] ?? []);
      saved.remove(id);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser['userId'])
          .update({'saved': saved});

      setState(() {
        widget.currentUser['saved'] = saved;
        widget.savedListings.removeWhere((item) => item['id'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Removed from saved items'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.green.shade600,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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

  void _applyForListing(Map<String, dynamic> listing) async {
    try {
      // Update in internship/job collection
      await FirebaseFirestore.instance
          .collection(listing['type'] == 'internship' ? 'internship' : 'jobs')
          .doc(listing['id'])
          .collection('activities')
          .doc('lists')
          .update({
        '${widget.currentUser['userId']}': 'requested',
      });

      // Update in user's applied collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser['userId'])
          .collection('applied')
          .doc(listing['type'])
          .update({
        listing['id']: 'requested',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied for ${listing['title']}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
              'Saved Items',
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
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 229, 239, 255),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSavedTab('Internships', 0),
                          ),
                          Expanded(
                            child: _buildSavedTab('Jobs', 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
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
              : _activeTab == 0
                  ? _buildInternshipsList()
                  : _buildJobsList(),
        ],
      ),
    );
  }

  Widget _buildSavedTab(String title, int index) {
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _activeTab == index
              ? const Color.fromARGB(255, 107, 146, 230)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _activeTab == index
                ? Colors.white
                : const Color.fromARGB(255, 26, 60, 124),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  SliverList _buildInternshipsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final internship = _savedInternships[index];
          return _buildSavedInternshipCard(internship);
        },
        childCount: _savedInternships.length,
      ),
    );
  }

  SliverList _buildJobsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final job = _savedJobs[index];
          return _buildSavedJobCard(job);
        },
        childCount: _savedJobs.length,
      ),
    );
  }

  Widget _buildSavedInternshipCard(Map<String, dynamic> internship) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            contentPadding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFF5F9FF),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: internship['companyLogo'] ?? '',
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
            title: Text(
              internship['title'] ?? 'No Title',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 26, 60, 124),
              ),
            ),
            subtitle: Text(
              internship['companyName'] ?? 'Unknown Company',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: IconButton(
              icon: const Icon(
                Iconsax.bookmark_25,
                color: Color.fromARGB(255, 107, 146, 230),
              ),
              onPressed: () => _removeSavedItem(internship['id']),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDetailChip(Iconsax.money,
                        internship['stipend'] ?? 'Not specified'),
                    const SizedBox(width: 10),
                    _buildDetailChip(
                        Iconsax.location, internship['location'] ?? 'Remote'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildDetailChip(Iconsax.clock,
                        internship['duration'] ?? 'Not specified'),
                    const SizedBox(width: 10),
                    _buildDetailChip(
                      Iconsax.calendar,
                      'Apply by ${internship['applyBy'] ?? 'Not specified'}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InternshipDetailScreen(
                            internship: internship,
                            isSaved: true,
                            onApply: () => _applyForListing(internship),
                            onSaveToggle: () =>
                                _removeSavedItem(internship['id']),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                        color: Color.fromARGB(255, 107, 146, 230),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: Color.fromARGB(255, 107, 146, 230),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyForListing(internship),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 107, 146, 230),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildSavedJobCard(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            contentPadding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFF5F9FF),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: job['companyLogo'] ?? '',
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
            title: Text(
              job['title'] ?? 'No Title',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 26, 60, 124),
              ),
            ),
            subtitle: Text(
              job['companyName'] ?? 'Unknown Company',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: IconButton(
              icon: const Icon(
                Iconsax.bookmark_25,
                color: Color.fromARGB(255, 107, 146, 230),
              ),
              onPressed: () => _removeSavedItem(job['id']),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDetailChip(
                        Iconsax.money, job['salary'] ?? 'Not specified'),
                    const SizedBox(width: 10),
                    _buildDetailChip(
                        Iconsax.location, job['location'] ?? 'Remote'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildDetailChip(Iconsax.clock, 'Full-time'),
                    const SizedBox(width: 10),
                    _buildDetailChip(
                      Iconsax.calendar,
                      'Apply by ${job['lastDate'] ?? 'Not specified'}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailScreen(
                            job: job,
                            isSaved: true,
                            onApply: () => _applyForListing(job),
                            onSaveToggle: () => _removeSavedItem(job['id']),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                        color: Color.fromARGB(255, 107, 146, 230),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: Color.fromARGB(255, 107, 146, 230),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyForListing(job),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 107, 146, 230),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
        ],
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
            Icon(
              icon,
              size: 16,
              color: const Color.fromARGB(255, 107, 146, 230),
            ),
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
}
