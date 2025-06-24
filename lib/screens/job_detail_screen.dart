import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onApply;
  final VoidCallback onSaveToggle;

  const JobDetailScreen({
    super.key,
    required this.job,
    required this.isSaved,
    required this.onApply,
    required this.onSaveToggle,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isExpanded = false;
  bool _isApplying = false;
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
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
                    imageUrl: job['companyLogo'] ?? '',
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
                          job['title'] ?? 'No Title',
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
                          (job['status'] ?? 'open').toUpperCase(),
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
                    'Posted by ${job['companyName'] ?? 'Unknown Company'}',
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
                        Expanded(child: _buildDetailTab('Requirements', 1)),
                        Expanded(child: _buildDetailTab('Benefits', 2)),
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
                          _buildDetailItem(Iconsax.money, 'Salary',
                              job['salary'] ?? 'Not specified'),
                          _buildDetailItem(Iconsax.location, 'Location',
                              job['location'] ?? 'Remote'),
                          _buildDetailItem(Iconsax.calendar, 'Last Date',
                              'Apply by ${job['lastDate'] ?? 'Not specified'}'),
                          const SizedBox(height: 20),
                          Text(
                            'Job Description',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: const Color.fromARGB(255, 26, 60, 124),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            job['JD'] ?? 'No job description available',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      // Requirements Tab
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(Iconsax.book, 'Education',
                              job['education'] ?? 'Not specified'),
                          _buildDetailItem(Iconsax.cpu, 'Skills Required',
                              job['skillsRequired'] ?? 'Not specified'),
                          _buildDetailItem(Iconsax.briefcase, 'Experience',
                              job['experience'] ?? 'Not specified'),
                          const SizedBox(height: 20),
                          Text(
                            'Additional Requirements',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: const Color.fromARGB(255, 26, 60, 124),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            (job['AR'] as List?)
                                    ?.map((item) => '• $item')
                                    .join('\n') ??
                                'No additional requirements',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      // Benefits Tab
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...(job['benefits'] as List?)?.map(
                                  (benefit) => _buildBulletPoint(benefit)) ??
                              [
                                _buildBulletPoint(
                                    'No benefits information available')
                              ],
                          const SizedBox(height: 20),
                          Text(
                            'Company Culture',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: const Color.fromARGB(255, 26, 60, 124),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            job['description'] ??
                                'No company culture information available',
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  if (job['website'] != null) {
                    final uri = Uri.parse(job['website']);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                      return;
                    }
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch website')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 107, 146, 230),
                  ),
                ),
                child: const Text(
                  'Company Website',
                  style: TextStyle(
                    color: Color.fromARGB(255, 107, 146, 230),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  setState(() => _isApplying = true);
                  await Future.delayed(const Duration(seconds: 1));
                  widget.onApply();
                  setState(() => _isApplying = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text('Application submitted successfully!'),
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
          ],
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
            color: _currentTab == index
                ? Colors.white
                : const Color.fromARGB(255, 26, 60, 124),
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

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 10),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 107, 146, 230),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
