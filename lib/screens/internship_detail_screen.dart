import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';

class InternshipDetailScreen extends StatefulWidget {
  final Map<String, dynamic> internship;
  final bool isSaved;
  final VoidCallback onApply;
  final VoidCallback onSaveToggle;

  const InternshipDetailScreen({
    super.key,
    required this.internship,
    required this.isSaved,
    required this.onApply,
    required this.onSaveToggle,
  });

  @override
  State<InternshipDetailScreen> createState() => _InternshipDetailScreenState();
}

class _InternshipDetailScreenState extends State<InternshipDetailScreen> {
  bool _isApplying = false;
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final internship = widget.internship;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFF5F9FF),
            expandedHeight: 250,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: internship['companyLogo'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color.fromARGB(255, 197, 218, 243),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color.fromARGB(255, 197, 218, 243),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isSaved ? Iconsax.bookmark_25 : Iconsax.bookmark,
                    color: Colors.white,
                  ),
                ),
                onPressed: widget.onSaveToggle,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          internship['title'] ?? 'No Title',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: const Color.fromARGB(255, 26, 60, 124),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 229, 239, 255),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (internship['status'] ?? 'open').toUpperCase(),
                          style: const TextStyle(
                            color: Color.fromARGB(255, 107, 146, 230),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posted by ${internship['companyName'] ?? 'Unknown Company'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 229, 239, 255),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(child: _buildDetailTab('Overview', 0)),
                        Expanded(child: _buildDetailTab('Details', 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  IndexedStack(
                    index: _currentTab,
                    children: [
                      // Overview Tab
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(
                              Iconsax.money, 'Stipend', internship['stipend'] ?? 'Not specified'),
                          _buildDetailItem(Iconsax.location, 'Location', 
                              internship['location'] ?? 'Remote'),
                          _buildDetailItem(Iconsax.calendar, 'Apply By', 
                              'Apply by ${internship['applyBy'] ?? 'Not specified'}'),
                          const SizedBox(height: 20),
                          Text(
                            'About the Internship',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: const Color.fromARGB(255, 26, 60, 124),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            internship['about'] ?? 'No description available',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      // Details Tab
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(Iconsax.clock, 'Duration', 
                              internship['duration'] ?? 'Not specified'),
                          _buildDetailItem(Iconsax.calendar_tick, 'Start Date', 
                              internship['startDate'] ?? 'Flexible'),
                          const SizedBox(height: 20),
                          Text(
                            'Eligibility Criteria',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: const Color.fromARGB(255, 26, 60, 124),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            internship['eligibility'] ?? 'No eligibility criteria specified',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () async {
            setState(() => _isApplying = true);
            await Future.delayed(const Duration(seconds: 1));
            widget.onApply();
            setState(() => _isApplying = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Application submitted successfully!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 107, 146, 230),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isApplying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Apply Now',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildDetailTab(String title, int index) {
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _currentTab == index
              ? const Color.fromARGB(255, 107, 146, 230)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _currentTab == index ? Colors.white : const Color.fromARGB(255, 26, 60, 124),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color.fromARGB(255, 107, 146, 230),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 26, 60, 124),
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
}