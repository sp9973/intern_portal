import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intern_link/screens/AddInternshipScreen.dart';
import 'package:intern_link/screens/AddJobScreen.dart';
import 'package:intern_link/screens/HRInternshipDetailsScreen.dart';
import 'package:intern_link/screens/HRJobDetailsScreen.dart';
import 'package:intern_link/screens/HRProfileScreen.dart';
import 'package:intern_link/screens/profile_screen.dart';

class HRHomeScreen extends StatefulWidget {
  final String email;
  const HRHomeScreen({super.key, required this.email});

  @override
  State<HRHomeScreen> createState() => _HRHomeScreenState();
}

class _HRHomeScreenState extends State<HRHomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _internships = [];
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _filteredInternships = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  bool _isLoading = true;
  bool _showInternships = true;
  String _userId = '';
  String _companyName = '';
  String _companyLogo = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterListings();
  }

  void _filterListings() {
    final searchTerm = _searchController.text.toLowerCase();

    setState(() {
      _filteredInternships = _internships.where((internship) {
        final titleMatches =
            internship['title'].toLowerCase().contains(searchTerm);
        return titleMatches;
      }).toList();

      _filteredJobs = _jobs.where((job) {
        final titleMatches = job['title'].toLowerCase().contains(searchTerm);
        return titleMatches;
      }).toList();
    });
  }

  Future<void> _loadUserData() async {
    try {
      // Get user data based on email
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        setState(() {
          _userId = userData['userId'];
          _companyName = userData['name'];
          _companyLogo = userData['logo'];
        });

        // Load the HR's posted internships and jobs
        await _loadPostedListings();
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPostedListings() async {
    try {
      // Load posted internships
      final internshipsSnapshot = await FirebaseFirestore.instance
          .collection('internship')
          .where('postedBy', isEqualTo: _userId)
          .get();

      _internships = internshipsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': 'internship',
          'title': data['title'],
          'companyLogo': _companyLogo,
          'companyName': _companyName,
          'location': data['location'],
          'stipend': data['stipen'],
          'duration': data['duration'],
          'applyBy': data['applyBy'],
          'about': data['about'],
          'eligibility': data['eligibility criteria'],
          'postedBy': data['postedBy'],
          'status': data['status'],
        };
      }).toList();

      // Load posted jobs
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('postedBy', isEqualTo: _userId)
          .get();

      _jobs = jobsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': 'job',
          'title': data['title'],
          'companyLogo': _companyLogo,
          'companyName': _companyName,
          'location': data['location'],
          'salary': data['salary'],
          'lastDate': data['lastDate'],
          'JD': data['JD'],
          'skillsRequired': data['skillsRequired'],
          'education': data['education'],
          'experience': data['experience'],
          'benefits': data['benefits'],
          'AR': data['AR'],
          'postedBy': data['postedBy'],
          'status': data['status'],
        };
      }).toList();

      setState(() {
        _isLoading = false;
        _filteredInternships = _internships;
        _filteredJobs = _jobs;
      });
    } catch (e) {
      print('Error loading posted listings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _closeListing(Map<String, dynamic> listing) async {
    try {
      await FirebaseFirestore.instance
          .collection(listing['type'] == 'internship' ? 'internship' : 'jobs')
          .doc(listing['id'])
          .update({'status': 'closed'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${listing['title']} has been closed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      // Reload data to reflect changes
      await _loadPostedListings();
    } catch (e) {
      print('Error closing listing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to close listing'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addNewListing() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add New Listing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddInternshipScreen(
                      userId: _userId,
                      companyName: _companyName,
                      companyLogo: _companyLogo,
                      email: widget.email,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 107, 146, 230),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Internship',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddJobScreen(
                      userId: _userId,
                      companyName: _companyName,
                      companyLogo: _companyLogo,
                      email: widget.email,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 107, 146, 230),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Job',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _displayedListings {
    return _showInternships ? _filteredInternships : _filteredJobs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewListing,
        backgroundColor: const Color.fromARGB(255, 107, 146, 230),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          // App bar with search - Matching the original UI
          SliverAppBar(
            backgroundColor: const Color(0xFFF5F9FF),
            elevation: 0,
            pinned: true,
            floating: true,
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 197, 218, 243),
                      Color.fromARGB(255, 149, 219, 236),
                    ],
                  ),
                ),
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hello,',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 241, 92, 142),
                              ),
                            ),
                            Text(
                              _companyName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD23369),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _navigateToProfile(),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: _companyLogo.isNotEmpty
                                  ? CachedNetworkImageProvider(_companyLogo)
                                  : const AssetImage(
                                          'assets/images/default_company.png')
                                      as ImageProvider,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(75),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search your postings...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Iconsax.search_normal,
                        color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle between Internships and Jobs
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Internships'),
                          selected: _showInternships,
                          onSelected: (selected) {
                            setState(() {
                              _showInternships = true;
                            });
                          },
                          selectedColor:
                              const Color.fromARGB(255, 107, 146, 230),
                          labelStyle: TextStyle(
                            color:
                                _showInternships ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Jobs'),
                          selected: !_showInternships,
                          onSelected: (selected) {
                            setState(() {
                              _showInternships = false;
                            });
                          },
                          selectedColor:
                              const Color.fromARGB(255, 107, 146, 230),
                          labelStyle: TextStyle(
                            color:
                                !_showInternships ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Posted Listings Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showInternships
                            ? 'Your Posted Internships'
                            : 'Your Posted Jobs',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 26, 60, 124),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Listings
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
              : _displayedListings.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            'No ${_showInternships ? 'internships' : 'jobs'} posted yet',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildListingCard(_displayedListings[index]),
                        childCount: _displayedListings.length,
                      ),
                    ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final isInternship = listing['type'] == 'internship';
    final isClosed = listing['status'] == 'closed';

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
              backgroundImage: listing['companyLogo'] != null
                  ? CachedNetworkImageProvider(listing['companyLogo'])
                  : const AssetImage('assets/images/default_company.png')
                      as ImageProvider,
            ),
            title: Text(
              listing['title'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 26, 60, 124),
              ),
            ),
            subtitle: Text(
              listing['companyName'],
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isClosed
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isClosed ? 'Closed' : 'Open',
                style: TextStyle(
                  color: isClosed
                      ? const Color(0xFFC62828)
                      : const Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDetailChip(
                      Iconsax.money,
                      isInternship ? listing['stipend'] : listing['salary'],
                    ),
                    const SizedBox(width: 10),
                    _buildDetailChip(Iconsax.location, listing['location']),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildDetailChip(
                      Iconsax.clock,
                      isInternship ? listing['duration'] : 'Full-time',
                    ),
                    const SizedBox(width: 10),
                    _buildDetailChip(
                      Iconsax.calendar,
                      isInternship
                          ? 'Apply by ${listing['applyBy']}'
                          : 'Last date ${listing['lastDate']}',
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
                    onPressed: () => _viewDetails(listing, isInternship),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                          color: Color.fromARGB(255, 107, 146, 230)),
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
                    onPressed: listing['status'] == 'open'
                        ? () => _closeListing(listing)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: listing['status'] == 'open'
                          ? const Color(0xFFE91E63)
                          : Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      listing['status'] == 'open' ? 'Close' : 'Closed',
                      style: TextStyle(
                        color: listing['status'] == 'open'
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
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
            Icon(icon,
                size: 16, color: const Color.fromARGB(255, 107, 146, 230)),
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

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 1) {
              _navigateToProfile();
            } else {
              setState(() => _currentIndex = index);
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color.fromARGB(255, 107, 146, 230),
          unselectedItemColor: Colors.grey.shade500,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Iconsax.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Iconsax.profile_2user),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HRProfileScreen(
          userId: _userId,
        ),
      ),
    );
  }

  void _viewDetails(Map<String, dynamic> listing, bool isInternship) {
    if (isInternship) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HRInternshipDetailsScreen(internship: listing),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HRJobDetailsScreen(job: listing),
        ),
      );
    }
  }
}
