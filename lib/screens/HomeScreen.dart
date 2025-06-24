import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intern_link/screens/application_status_screen.dart';
import 'package:intern_link/screens/internship_detail_screen.dart';
import 'package:intern_link/screens/job_detail_screen.dart';
import 'package:intern_link/screens/profile_screen.dart';
import 'package:intern_link/screens/saved_items_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _internships = [];
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _filteredInternships = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  bool _isLoading = true;
  bool _showInternships = true;
  String _selectedCategory = '';

  // Category keywords map
  final Map<String, List<String>> _categoryKeywords = {
    'Development': [
      'flutter',
      'software',
      'developer',
      'development',
      'programming',
      'coding',
      'frontend',
      'backend',
      'fullstack',
      'mobile',
      'web',
      'android',
      'ios',
      'react',
      'javascript',
      'python',
      'java',
      'c++',
      'dart',
      'node'
    ],
    'Design': [
      'design',
      'ui',
      'ux',
      'graphic',
      'figma',
      'adobe',
      'photoshop',
      'illustrator',
      'sketch',
      'prototype',
      'wireframe',
      'user experience',
      'user interface',
      'visual',
      'creative',
      'art',
      'branding',
      'typography',
      'layout',
      'interaction'
    ],
    'Marketing': [
      'marketing',
      'digital',
      'social media',
      'seo',
      'content',
      'brand',
      'advertising',
      'campaign',
      'strategy',
      'analytics',
      'growth',
      'sales',
      'public relations',
      'influencer',
      'email',
      'market research',
      'customer',
      'engagement',
      'promotion',
      'outreach'
    ],
    'Data Science': [
      'data',
      'science',
      'machine learning',
      'ai',
      'artificial intelligence',
      'python',
      'r',
      'sql',
      'analysis',
      'analytics',
      'statistics',
      'visualization',
      'big data',
      'deep learning',
      'neural networks',
      'tensorflow',
      'pytorch',
      'numpy',
      'pandas',
      'scikit'
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
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
        final companyMatches =
            internship['companyName'].toLowerCase().contains(searchTerm);

        if (_selectedCategory.isEmpty) {
          return titleMatches || companyMatches;
        } else {
          final categoryKeywords = _categoryKeywords[_selectedCategory] ?? [];
          final matchesCategory = categoryKeywords.any(
              (keyword) => internship['title'].toLowerCase().contains(keyword));
          return (titleMatches || companyMatches) && matchesCategory;
        }
      }).toList();

      _filteredJobs = _jobs.where((job) {
        final titleMatches = job['title'].toLowerCase().contains(searchTerm);
        final companyMatches =
            job['companyName'].toLowerCase().contains(searchTerm);

        if (_selectedCategory.isEmpty) {
          return titleMatches || companyMatches;
        } else {
          final categoryKeywords = _categoryKeywords[_selectedCategory] ?? [];
          final matchesCategory = categoryKeywords
              .any((keyword) => job['title'].toLowerCase().contains(keyword));
          return (titleMatches || companyMatches) && matchesCategory;
        }
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? '' : category;
      _filterListings();
    });
  }

  Future<void> _loadData() async {
    try {
      print("fetching internships...");
      final internshipsSnapshot = await FirebaseFirestore.instance
          .collection('internship')
          .where('status', isEqualTo: 'open')
          .get();

      _internships =
          await Future.wait(internshipsSnapshot.docs.map((doc) async {
        final data = doc.data();
        print('Internship data: $data');

        final company = await _getCompanyData(data['postedBy']);
        return {
          'id': doc.id,
          'type': 'internship',
          'title': data['title'],
          'companyLogo': company['logo'],
          'companyName': company['name'],
          'location': data['location'],
          'stipend': data['stipen'],
          'duration': data['duration'],
          'applyBy': data['applyBy'],
          'about': data['about'],
          'eligibility': data['eligibility criteria'],
          'postedBy': data['postedBy'],
        };
      }));

      // Load jobs
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('status', isEqualTo: 'open')
          .get();

      _jobs = await Future.wait(jobsSnapshot.docs.map((doc) async {
        final data = doc.data();
        print('Job data: $data');

        final company = await _getCompanyData(data['postedBy']);
        return {
          'id': doc.id,
          'type': 'job',
          'title': data['title'],
          'companyLogo': company['logo'],
          'companyName': company['name'],
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
        };
      }));

      setState(() {
        _isLoading = false;
        _filteredInternships = _internships;
        _filteredJobs = _jobs;
      });

      print(_internships);
      print(_jobs);
    } catch (e) {
      print('Error loading data: $e');
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

  void _toggleSaved(String listingId) {
    setState(() {
      final saved = List<String>.from(widget.currentUser['saved'] ?? []);
      if (saved.contains(listingId)) {
        saved.remove(listingId);
      } else {
        saved.add(listingId);
      }

      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser['userId'])
          .update({'saved': saved});

      widget.currentUser['saved'] = saved;
    });
  }

  void _applyForListing(Map<String, dynamic> listing) {
    try {
      FirebaseFirestore.instance
          .collection(listing['type'] == 'internship' ? 'internship' : 'jobs')
          .doc(listing['id'])
          .collection('activities')
          .doc('lists')
          .set({
        '${widget.currentUser['userId']}': 'requested',
      });

      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser['userId'])
          .collection('applied')
          .doc(listing['type'])
          .set({
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
      print('Error applying for listing: $e');
    }
  }

  List<Map<String, dynamic>> get _displayedListings {
    return _showInternships ? _filteredInternships : _filteredJobs;
  }

  List<Map<String, dynamic>> get _savedListings {
    final savedIds = List<String>.from(widget.currentUser['saved'] ?? []);
    return [..._internships, ..._jobs]
        .where((item) => savedIds.contains(item['id']))
        .toList();
  }

  bool _isSaved(String listingId) {
    return (widget.currentUser['saved'] as List?)?.contains(listingId) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: CustomScrollView(
        slivers: [
          // App bar with search - UPDATED TO MATCH ORIGINAL UI
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
                              widget.currentUser['name'].split(' ').first,
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
                              backgroundImage: widget
                                          .currentUser['profilePicture'] !=
                                      null
                                  ? CachedNetworkImageProvider(
                                      widget.currentUser['profilePicture'])
                                  : const AssetImage(
                                          'assets/images/default_profile.png')
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
                    hintText: 'Search internships, jobs...',
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

          // Content - UPDATED TO MATCH ORIGINAL UI
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 26, 60, 124),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryCard(
                          Iconsax.code,
                          'Development',
                          const Color(0xFFE1F0FF),
                          const Color(0xFF1A3C7C),
                          isSelected: _selectedCategory == 'Development',
                        ),
                        _buildCategoryCard(
                          Iconsax.designtools,
                          'Design',
                          const Color(0xFFFFE7F5),
                          const Color(0xFFD23369),
                          isSelected: _selectedCategory == 'Design',
                        ),
                        _buildCategoryCard(
                          Iconsax.chart_2,
                          'Marketing',
                          const Color(0xFFE4F9E4),
                          const Color(0xFF2E7D32),
                          isSelected: _selectedCategory == 'Marketing',
                        ),
                        _buildCategoryCard(
                          Iconsax.cpu,
                          'Data Science',
                          const Color(0xFFF0E7FF),
                          const Color(0xFF5E35B1),
                          isSelected: _selectedCategory == 'Data Science',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

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

                  // Featured Listings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showInternships
                            ? 'Featured Internships'
                            : 'Featured Jobs',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 26, 60, 124),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _navigateToSaved(),
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            color: Color.fromARGB(255, 107, 146, 230),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Listings - UPDATED TO MATCH ORIGINAL UI
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
                            'No ${_showInternships ? 'internships' : 'jobs'} available',
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
    final isSaved = _isSaved(listing['id']);
    final isInternship = listing['type'] == 'internship';

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
            trailing: IconButton(
              icon: Icon(
                isSaved ? Iconsax.bookmark_25 : Iconsax.bookmark,
                color: isSaved
                    ? const Color.fromARGB(255, 107, 146, 230)
                    : Colors.grey.shade400,
              ),
              onPressed: () => _toggleSaved(listing['id']),
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
                      'Apply by ${isInternship ? listing['applyBy'] : listing['lastDate']}',
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
                    onPressed: () => _viewDetails(listing, _showInternships),
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
                    onPressed: () => _applyForListing(listing),
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

  Widget _buildCategoryCard(
      IconData icon, String title, Color bgColor, Color iconColor,
      {bool isSelected = false}) {
    return GestureDetector(
      onTap: () => _selectCategory(title),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: isSelected ? bgColor.withOpacity(0.7) : bgColor,
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(
                  color: const Color.fromARGB(255, 107, 146, 230), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedItemsScreen(
                    savedListings: _savedListings,
                    currentUser: widget.currentUser,
                  ),
                ),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApplicationStatusScreen(
                    currentUser: widget.currentUser,
                  ),
                ),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: widget.currentUser['userId'],
                    isHR: false,
                    currentUser: widget.currentUser, 
                  ),
                ),
              );
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
          items: [
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 0 ? Iconsax.home_25 : Iconsax.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 1 ? Iconsax.save_25 : Iconsax.save_2),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 2
                  ? Iconsax.document_text_15
                  : Iconsax.document_text),
              label: 'Applications',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 3
                  ? Iconsax.profile_2user5
                  : Iconsax.profile_2user),
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
        builder: (context) => ProfileScreen(
          userId: widget.currentUser['userId'], isHR: false,currentUser: widget.currentUser, // Pass the user ID
        ),
      ),
    );
  }

  void _navigateToSaved() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedItemsScreen(
          savedListings: _savedListings,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _viewDetails(Map<String, dynamic> listing, bool internship) {
    if (internship) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InternshipDetailScreen(
            internship: listing,
            isSaved: _isSaved(listing['id']),
            onApply: () => _applyForListing(listing),
            onSaveToggle: () => _toggleSaved(listing['id']),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobDetailScreen(
            job: listing,
            isSaved: _isSaved(listing['id']),
            onApply: () => _applyForListing(listing),
            onSaveToggle: () => _toggleSaved(listing['id']),
          ),
        ),
      );
    }
  }
}
