import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intern_link/services/apikeys.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onSave;

  const EditDetailsScreen({
    Key? key,
    required this.userData,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditDetailsScreenState createState() => _EditDetailsScreenState();
}

class _EditDetailsScreenState extends State<EditDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _skillsController;
  late TextEditingController _experienceController;
  late TextEditingController _educationController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;

  File? _profileImage;
  File? _resumeFile;
  File? _companyLogo;
  bool _isLoading = false;
  bool _isJobSeeker = true;
  List<String> _skills = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current user data
    _nameController =
        TextEditingController(text: widget.userData['name'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    _skillsController = TextEditingController();
    _experienceController =
        TextEditingController(text: widget.userData['Experience'] ?? '');
    _educationController =
        TextEditingController(text: widget.userData['Education'] ?? '');
    _websiteController =
        TextEditingController(text: widget.userData['website'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.userData['description'] ?? '');

    _isJobSeeker = widget.userData['jobSeeker'] ?? true;
    _skills = List<String>.from(widget.userData['Skills'] ?? []);

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowCompression: true,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.files.single.path!);
        final fileSize = await file.length() / (1024 * 1024);

        if (fileSize > 3) {
          _showErrorSnackbar('Image size should be less than 3MB');
          return;
        }

        setState(() {
          if (_isJobSeeker) {
            _profileImage = file;
          } else {
            _companyLogo = file;
          }
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackbar('Error selecting image');
    }
  }

  Future<void> _pickResume() async {
    try {
      final pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowCompression: true,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.files.single.path!);
        final fileSize = await file.length() / (1024 * 1024);

        if (fileSize > 3) {
          _showErrorSnackbar('Resume size should be less than 3MB');
          return;
        }

        setState(() => _resumeFile = file);
      }
    } catch (e) {
      print('Error picking resume: $e');
      _showErrorSnackbar('Error selecting resume');
    }
  }

  void _addSkill() {
    if (_skillsController.text.isNotEmpty) {
      setState(() {
        _skills.add(_skillsController.text);
        _skillsController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<String?> _uploadToCloudinary(File file, String folder) async {
    try {
      print('Starting Cloudinary upload for folder: $folder');

      final cloudinaryUrl =
          'https://api.cloudinary.com/v1_1/${ApiKeys.getCloudName()}/upload';
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileExtension = path.extension(file.path).toLowerCase();
      final isPdf = fileExtension == '.pdf';

      // Parameters to sign (only folder and timestamp)
      final paramsToSign = {
        'timestamp': timestamp,
        'folder': folder,
      };

      // Sort parameters alphabetically
      final sortedKeys = paramsToSign.keys.toList()..sort();
      final paramString =
          sortedKeys.map((key) => '$key=${paramsToSign[key]}').join('&');
      final stringToSign = '$paramString${ApiKeys.getSecret()}';

      print('String to sign: $stringToSign');

      final signature = sha1.convert(utf8.encode(stringToSign)).toString();

      print('Creating multipart request');
      final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));

      // Add all required fields
      request.fields.addAll({
        'timestamp': timestamp,
        'api_key': ApiKeys.getKey(),
        'signature': signature,
        'folder': folder,
        if (isPdf)
          'resource_type': 'raw', // Only add to request, not to signature
      });

      print('Adding file to request');
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: path.basename(file.path),
      ));

      print('Sending request to Cloudinary');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData) as Map<String, dynamic>;

      print('Cloudinary response: ${response.statusCode}');
      print('Cloudinary response data: $jsonResponse');

      if (response.statusCode == 200) {
        print('Upload successful, URL: ${jsonResponse['secure_url']}');
        return jsonResponse['secure_url'] as String;
      } else {
        throw Exception(
            'Failed to upload: ${jsonResponse['error']?.toString() ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      _showErrorSnackbar('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload files to Cloudinary if they were changed
      String? profileImageUrl;
      String? resumeUrl;
      String? companyLogoUrl;

      if (_isJobSeeker && _profileImage != null) {
        profileImageUrl =
            await _uploadToCloudinary(_profileImage!, 'profile_pictures');
        if (profileImageUrl == null)
          throw Exception('Failed to upload profile image');
      }

      if (_isJobSeeker && _resumeFile != null) {
        resumeUrl = await _uploadToCloudinary(_resumeFile!, 'resumes');
        if (resumeUrl == null) throw Exception('Failed to upload resume');
      }

      if (!_isJobSeeker && _companyLogo != null) {
        companyLogoUrl =
            await _uploadToCloudinary(_companyLogo!, 'company_logos');
        if (companyLogoUrl == null)
          throw Exception('Failed to upload company logo');
      }

      // 2. Prepare updated data
      final updatedData = <String, dynamic>{
        'name': _nameController.text,
        'Skills': _skills,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isJobSeeker) {
        updatedData.addAll({
          'Experience': _experienceController.text,
          'Education': _educationController.text,
          if (profileImageUrl != null) 'profilePicture': profileImageUrl,
          if (resumeUrl != null) 'resumeUrl': resumeUrl,
        });
      } else {
        updatedData.addAll({
          'website': _websiteController.text,
          'description': _descriptionController.text,
          if (companyLogoUrl != null) 'logo': companyLogoUrl,
        });
      }

      // 3. Call the save callback
      await widget.onSave(updatedData);

      _showSuccessSnackbar(
          'Profile updated successfully! Please restart the app to see changes.');
      Navigator.of(context).pop();
    } catch (e) {
      print('Error updating profile: $e');
      _showErrorSnackbar('Failed to update profile: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/images/texture.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Edit",
                              style: TextStyle(
                                fontSize: 22,
                                color: const Color.fromARGB(255, 107, 146, 230)
                                    .withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Profile Details",
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 26, 60, 124),
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Profile Picture/Company Logo
                                Text(
                                  _isJobSeeker
                                      ? 'Profile Picture'
                                      : 'Company Logo',
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 26, 60, 124),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 107, 146, 230),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _isJobSeeker
                                        ? _profileImage != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.file(
                                                  _profileImage!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : widget.userData[
                                                        'profilePicture'] !=
                                                    null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: CachedNetworkImage(
                                                      imageUrl: widget.userData[
                                                          'profilePicture'],
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : const Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.add_a_photo,
                                                        color: Color.fromARGB(
                                                            255, 107, 146, 230),
                                                      ),
                                                      SizedBox(height: 5),
                                                      Text(
                                                        'Add Photo',
                                                        style: TextStyle(
                                                          color: Color.fromARGB(
                                                              255,
                                                              107,
                                                              146,
                                                              230),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                        : _companyLogo != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.file(
                                                  _companyLogo!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : widget.userData['logo'] != null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: CachedNetworkImage(
                                                      imageUrl: widget
                                                          .userData['logo'],
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : const Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.add_a_photo,
                                                        color: Color.fromARGB(
                                                            255, 107, 146, 230),
                                                      ),
                                                      SizedBox(height: 5),
                                                      Text(
                                                        'Add Logo',
                                                        style: TextStyle(
                                                          color: Color.fromARGB(
                                                              255,
                                                              107,
                                                              146,
                                                              230),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Name Field
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: _isJobSeeker
                                        ? 'Full Name'
                                        : 'Company Name',
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color.fromARGB(255, 26, 60, 124),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return _isJobSeeker
                                          ? 'Please enter your name'
                                          : 'Please enter company name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Email Field (read-only)
                                TextFormField(
                                  controller: _emailController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color.fromARGB(255, 26, 60, 124),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Job Seeker Specific Fields
                                if (_isJobSeeker) ...[
                                  // Resume Upload
                                  const Text(
                                    'Resume (PDF only)',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 26, 60, 124),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                    onPressed: _pickResume,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: const BorderSide(
                                        color:
                                            Color.fromARGB(255, 107, 146, 230),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.upload,
                                          color: Color.fromARGB(
                                              255, 107, 146, 230),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _resumeFile != null
                                              ? 'Resume Selected'
                                              : widget.userData['resumeUrl'] !=
                                                      null
                                                  ? 'Change Resume'
                                                  : 'Upload Resume',
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                                255, 107, 146, 230),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Skills
                                  const Text(
                                    'Skills',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 26, 60, 124),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _skillsController,
                                          decoration: InputDecoration(
                                            hintText: 'Add a skill',
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color.fromARGB(
                                                    255, 26, 60, 124),
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 107, 146, 230),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.add,
                                              color: Colors.white),
                                          onPressed: _addSkill,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: _skills
                                        .map((skill) => Chip(
                                              label: Text(skill),
                                              deleteIcon: const Icon(
                                                  Icons.close,
                                                  size: 18),
                                              onDeleted: () {
                                                setState(() =>
                                                    _skills.remove(skill));
                                              },
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 229, 239, 255),
                                              labelStyle: const TextStyle(
                                                color: Color.fromARGB(
                                                    255, 26, 60, 124),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 20),

                                  // Experience
                                  TextFormField(
                                    controller: _experienceController,
                                    decoration: InputDecoration(
                                      labelText: 'Experience',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color:
                                              Color.fromARGB(255, 26, 60, 124),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Education
                                  TextFormField(
                                    controller: _educationController,
                                    decoration: InputDecoration(
                                      labelText: 'Education',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color:
                                              Color.fromARGB(255, 26, 60, 124),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // HR Specific Fields
                                if (!_isJobSeeker) ...[
                                  TextFormField(
                                    controller: _websiteController,
                                    decoration: InputDecoration(
                                      labelText: 'Company Website',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color:
                                              Color.fromARGB(255, 26, 60, 124),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _descriptionController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: 'Company Description',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color:
                                              Color.fromARGB(255, 26, 60, 124),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Submit Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 107, 146, 230),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 3,
                                      shadowColor: const Color.fromARGB(
                                          255, 26, 60, 124),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: Color.fromARGB(
                                                  255, 26, 60, 124),
                                            ),
                                          )
                                        : const Text(
                                            "Save Changes",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Color.fromARGB(
                                                  255, 26, 60, 124),
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
