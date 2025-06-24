import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Changed from image_picker
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intern_link/services/apikeys.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:intern_link/screens/LoginScreen.dart';
import 'package:intern_link/services/FadeTransitionPageRoute.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _profileImage;
  File? _resumeFile;
  File? _companyLogo;
  String? _userType = 'job_seeker';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  List<String> _skills = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size should be less than 3MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          if (_userType == 'job_seeker') {
            _profileImage = file;
          } else {
            _companyLogo = file;
          }
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting image'),
          backgroundColor: Colors.red,
        ),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resume size should be less than 3MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _resumeFile = file;
        });
      }
    } catch (e) {
      print('Error picking resume: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting resume'),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  String _generateCloudinarySignature(String timestamp) {
    print('Generating Cloudinary signature');
    final params = 'folder=uploads&timestamp=$timestamp${ApiKeys.getSecret()}';
    return sha256.convert(utf8.encode(params)).toString();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    if (_userType == 'job_seeker' && _resumeFile == null) {
      print('Resume not provided for job seeker');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your resume'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    print('Starting signup process');

    try {
      // 1. Upload files to Cloudinary first
      print('Starting file uploads');
      String? profileImageUrl;
      String? resumeUrl;
      String? companyLogoUrl;

      if (_userType == 'job_seeker' && _profileImage != null) {
        print('Uploading profile image');
        profileImageUrl =
            await _uploadToCloudinary(_profileImage!, 'profile_pictures');
        if (profileImageUrl == null) {
          print('Profile image upload failed');
          throw Exception('Failed to upload profile image');
        }
      }

      if (_userType == 'job_seeker' && _resumeFile != null) {
        print('Uploading resume');
        resumeUrl = await _uploadToCloudinary(_resumeFile!, 'resumes');
        if (resumeUrl == null) {
          print('Resume upload failed');
          throw Exception('Failed to upload resume');
        }
      }

      if (_userType == 'hr' && _companyLogo != null) {
        print('Uploading company logo');
        companyLogoUrl =
            await _uploadToCloudinary(_companyLogo!, 'company_logos');
        if (companyLogoUrl == null) {
          print('Company logo upload failed');
          throw Exception('Failed to upload company logo');
        }
      }

      print('All files uploaded successfully');

      // 2. Check if email already exists
      print('Checking if email exists');
      final loginRef = FirebaseFirestore.instance
          .collection('users')
          .doc('login')
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => snapshot.data()!,
            toFirestore: (data, _) => data,
          );

      final loginDoc = await loginRef.get();

      if (loginDoc.exists &&
          loginDoc.data()?.containsKey(_emailController.text) == true) {
        print('Email already exists');
        throw Exception('Email already registered');
      }

      // 3. Create user document in Firestore
      print('Creating user document');
      final usersRef = FirebaseFirestore.instance.collection('users');
      final newUserRef = usersRef.doc();

      // Create properly typed user data
      final userData = <String, dynamic>{
        'userId': newUserRef.id,
        'jobSeeker': _userType == 'job_seeker',
        'email': _emailController.text,
        'name': _nameController.text,
        'password': _passwordController.text, // Note: In production, hash this
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add job seeker specific fields
      if (_userType == 'job_seeker') {
        userData.addAll(<String, dynamic>{
          'Education': _educationController.text,
          'Experience': _experienceController.text,
          'Skills': _skills,
          'profilePicture': profileImageUrl ?? '',
          'resumeUrl': resumeUrl ?? '',
        });
      }
      // Add HR specific fields
      else {
        userData.addAll(<String, dynamic>{
          'description': _descriptionController.text,
          'logo': companyLogoUrl ?? '',
          'website': _websiteController.text,
        });
      }

      // 4. Create all documents in a batch to ensure atomicity
      print('Creating Firestore batch');
      final batch = FirebaseFirestore.instance.batch();

      // Create user document
      batch.set(newUserRef, userData);

      // Update login document
      batch.set(
        loginRef,
        <String, dynamic>{_emailController.text: newUserRef.id},
        SetOptions(merge: true),
      );

      // Create empty applied/posts collections
      if (_userType == 'job_seeker') {
        batch.set(
          newUserRef.collection('applied').doc('internship'),
          <String, dynamic>{},
        );
        batch.set(
          newUserRef.collection('applied').doc('job'),
          <String, dynamic>{},
        );
      } else {
        batch.set(
          newUserRef.collection('posts').doc('internship'),
          <String, dynamic>{},
        );
        batch.set(
          newUserRef.collection('posts').doc('job'),
          <String, dynamic>{},
        );
      }

      // Commit the batch
      print('Committing Firestore batch');
      await batch.commit();
      print('Batch committed successfully');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login screen
      Navigator.of(context).pushReplacement(
        FadeTransitionPageRoute(page: const LoginScreen()),
      );
    } catch (e) {
      print('Error during signup: $e');
      print('Error type: ${e.runtimeType}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      print('Signup process completed');
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
                              "Join",
                              style: TextStyle(
                                fontSize: 22,
                                color: const Color.fromARGB(255, 107, 146, 230)
                                    .withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "InternLink",
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
                                // User Type Selection
                                const Text(
                                  'I am signing up as:',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 26, 60, 124),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Text('Job Seeker'),
                                        selected: _userType == 'job_seeker',
                                        onSelected: (selected) {
                                          setState(
                                              () => _userType = 'job_seeker');
                                        },
                                        selectedColor: const Color.fromARGB(
                                            255, 107, 146, 230),
                                        labelStyle: TextStyle(
                                          color: _userType == 'job_seeker'
                                              ? Colors.white
                                              : const Color.fromARGB(
                                                  255, 26, 60, 124),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Text('HR (Company)'),
                                        selected: _userType == 'hr',
                                        onSelected: (selected) {
                                          setState(() => _userType = 'hr');
                                        },
                                        selectedColor: const Color.fromARGB(
                                            255, 107, 146, 230),
                                        labelStyle: TextStyle(
                                          color: _userType == 'hr'
                                              ? Colors.white
                                              : const Color.fromARGB(
                                                  255, 26, 60, 124),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Name Field
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: _userType == 'job_seeker'
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
                                      return _userType == 'job_seeker'
                                          ? 'Please enter your name'
                                          : 'Please enter company name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
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
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
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
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey.shade600,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Confirm Password Field
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
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
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey.shade600,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Profile Picture/Company Logo
                                Text(
                                  _userType == 'job_seeker'
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
                                    child: _userType == 'job_seeker'
                                        ? _profileImage != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.file(
                                                  _profileImage!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : const Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
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
                                                          255, 107, 146, 230),
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
                                            : const Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
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
                                                          255, 107, 146, 230),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Job Seeker Specific Fields
                                if (_userType == 'job_seeker') ...[
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
                                if (_userType == 'hr') ...[
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
                                            "Sign Up",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Color.fromARGB(
                                                  255, 26, 60, 124),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Already have account
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Already have an account?",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pushReplacement(
                                          FadeTransitionPageRoute(
                                              page: const LoginScreen()),
                                        );
                                      },
                                      child: const Text(
                                        "Login",
                                        style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 26, 60, 124),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
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
