import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intern_link/screens/HRHomeScreen.dart';

class AddJobScreen extends StatefulWidget {
  final String userId;
  final String companyName;
  final String companyLogo;
  final String email;
  const AddJobScreen({
    super.key,
    required this.userId,
    required this.companyName,
    required this.companyLogo,
    required this.email,
  });

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final List<TextEditingController> _arControllers = [TextEditingController()];
  final List<TextEditingController> _benefitsControllers = [
    TextEditingController()
  ];

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _lastDateController = TextEditingController();
  final TextEditingController _jdController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Convert ARs and Benefits to lists
        final ars = _arControllers
            .map((c) => c.text)
            .where((t) => t.isNotEmpty)
            .toList();
        final benefits = _benefitsControllers
            .map((c) => c.text)
            .where((t) => t.isNotEmpty)
            .toList();

        await FirebaseFirestore.instance.collection('jobs').add({
          'title': _titleController.text,
          'location': _locationController.text,
          'salary': _salaryController.text,
          'lastDate': _lastDateController.text,
          'JD': _jdController.text,
          'skillsRequired': _skillsController.text,
          'education': _educationController.text,
          'experience': _experienceController.text,
          'AR': ars,
          'benefits': benefits,
          'postedBy': widget.userId,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HRHomeScreen(email: widget.email),
          ),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _lastDateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _addARField() {
    setState(() {
      _arControllers.add(TextEditingController());
    });
  }

  void _removeARField(int index) {
    if (_arControllers.length > 1) {
      setState(() {
        _arControllers.removeAt(index);
      });
    }
  }

  void _addBenefitField() {
    setState(() {
      _benefitsControllers.add(TextEditingController());
    });
  }

  void _removeBenefitField(int index) {
    if (_benefitsControllers.length > 1) {
      setState(() {
        _benefitsControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _lastDateController.dispose();
    _jdController.dispose();
    _skillsController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    for (var controller in _arControllers) {
      controller.dispose();
    }
    for (var controller in _benefitsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text('Add Job'),
        backgroundColor: const Color(0xFFF5F9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Info
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
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
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFF5F9FF),
                      backgroundImage: widget.companyLogo.isNotEmpty
                          ? NetworkImage(widget.companyLogo)
                          : const AssetImage(
                                  'assets/images/default_company.png')
                              as ImageProvider,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      widget.companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Job Title',
                  prefixIcon: const Icon(Iconsax.text),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  prefixIcon: const Icon(Iconsax.location),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Salary and Last Date Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryController,
                      decoration: InputDecoration(
                        labelText: 'Salary',
                        prefixIcon: const Icon(Iconsax.money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter salary';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _lastDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Last Date',
                        prefixIcon: const Icon(Iconsax.calendar),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Iconsax.calendar_1),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Job Description
              TextFormField(
                controller: _jdController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Job Description',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Iconsax.note_text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe the job';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Skills Required
              TextFormField(
                controller: _skillsController,
                decoration: InputDecoration(
                  labelText: 'Skills Required (comma separated)',
                  prefixIcon: const Icon(Iconsax.bill),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter required skills';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Education and Experience Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _educationController,
                      decoration: InputDecoration(
                        labelText: 'Education',
                        prefixIcon: const Icon(Iconsax.book),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter education';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _experienceController,
                      decoration: InputDecoration(
                        labelText: 'Experience',
                        prefixIcon: const Icon(Iconsax.briefcase),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter experience';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // ARs (Responsibilities)
              const Text(
                'Responsibilities:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._arControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Responsibility ${index + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (index == 0 &&
                                (value == null || value.isEmpty)) {
                              return 'At least one responsibility required';
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.trash, color: Colors.red),
                        onPressed: () => _removeARField(index),
                      ),
                    ],
                  ),
                );
              }).toList(),
              TextButton(
                onPressed: _addARField,
                child: const Text('+ Add Responsibility'),
              ),
              const SizedBox(height: 15),

              // Benefits
              const Text(
                'Benefits:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._benefitsControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Benefit ${index + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (index == 0 &&
                                (value == null || value.isEmpty)) {
                              return 'At least one benefit required';
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.trash, color: Colors.red),
                        onPressed: () => _removeBenefitField(index),
                      ),
                    ],
                  ),
                );
              }).toList(),
              TextButton(
                onPressed: _addBenefitField,
                child: const Text('+ Add Benefit'),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 107, 146, 230),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Post Job',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
