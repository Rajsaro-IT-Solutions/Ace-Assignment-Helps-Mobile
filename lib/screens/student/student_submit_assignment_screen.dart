import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/user_model.dart';
import '../../core/models/portal_models.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class StudentSubmitAssignmentScreen extends StatefulWidget {
  final UserModel user;

  const StudentSubmitAssignmentScreen({super.key, required this.user});

  @override
  State<StudentSubmitAssignmentScreen> createState() => _StudentSubmitAssignmentScreenState();
}

class _StudentSubmitAssignmentScreenState extends State<StudentSubmitAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _wordsController = TextEditingController(text: '1000');
  final _instructionsController = TextEditingController();

  String _selectedSubject = 'Computer Science & Artificial Intelligence';
  String _selectedType = 'Essay';
  String _selectedStyle = 'APA 7th Edition';
  String _selectedCurrency = 'USD';
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 5));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 23, minute: 59);

  bool _loading = false;
  List<CourseModel> _courses = [];

  final List<String> _assignmentTypes = [
    'Essay',
    'Research Paper',
    'Case Study Analysis',
    'Dissertation / Thesis',
    'Report Writing',
    'Programming / Software Project',
    'Data Analysis & Statistics',
    'Coursework Assignment',
  ];

  final List<String> _refStyles = [
    'APA 7th Edition',
    'Harvard Referencing',
    'IEEE Standard',
    'MLA 9th Edition',
    'Chicago / Turabian',
    'OSCOLA (Law)',
  ];

  final Map<String, double> _ratesPerWord = {
    'USD': 0.05,
    'INR': 4.0,
    'GBP': 0.04,
    'EUR': 0.045,
    'AUD': 0.075,
    'CAD': 0.068,
  };

  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'INR': '₹',
    'GBP': '£',
    'EUR': '€',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _wordsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final list = await ApiService.getCourses();
    if (mounted && list.isNotEmpty) {
      setState(() {
        _courses = list;
        _selectedSubject = list.first.title;
      });
    }
  }

  double get _calculatedPrice {
    final words = int.tryParse(_wordsController.text) ?? 1000;
    final rate = _ratesPerWord[_selectedCurrency] ?? 0.05;
    return words * rate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now().add(const Duration(hours: 6)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final finalDeadline = DateTime(
      _selectedDeadline.year,
      _selectedDeadline.month,
      _selectedDeadline.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final res = await ApiService.submitAssignment(
      studentId: widget.user.id,
      title: _titleController.text.trim(),
      subject: _selectedSubject,
      assignmentType: _selectedType,
      deadline: DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDeadline),
      wordCount: int.tryParse(_wordsController.text) ?? 1000,
      referenceStyle: _selectedStyle,
      description: _instructionsController.text.trim(),
      currency: _selectedCurrency,
      price: _calculatedPrice,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success && res.data != null) {
      final assignId = res.data!['assignment_id'] ?? 'AAH-NEW';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
              SizedBox(width: 10),
              Text('Order Submitted!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your assignment has been created with ID: $assignId.'),
              const SizedBox(height: 8),
              Text(
                'Estimated Investment: ${_currencySymbols[_selectedCurrency]}${_calculatedPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              const Text('Our allocation managers are now matching your brief with the top PhD expert.'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('Go to My Assignments'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Submission failed. Please check network.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sym = _currencySymbols[_selectedCurrency] ?? '\$';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Submit Assignment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Post a New Assignment Order',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Get verified PhD expert help with strict SLA deadlines & plagiarism checks.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              _buildSectionTitle('Assignment Title / Topic *'),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Clinical Risk Assessment in Healthcare',
                  prefixIcon: Icon(Icons.assignment_outlined, size: 20),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Subject Discipline
              _buildSectionTitle('Subject Discipline *'),
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined, size: 20),
                ),
                items: (_courses.isNotEmpty ? _courses.map((c) => c.title) : [
                  'Computer Science & Artificial Intelligence',
                  'Business Administration & MBA',
                  'Nursing & Clinical Healthcare',
                  'Engineering & Physical Sciences',
                  'Law & Legal Studies',
                  'Data Analytics & Statistics',
                ]).map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedSubject = v);
                },
              ),
              const SizedBox(height: 16),

              // Assignment Type & Reference Style
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Assignment Type'),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          isExpanded: true,
                          items: _assignmentTypes
                              .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedType = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Reference Style'),
                        DropdownButtonFormField<String>(
                          value: _selectedStyle,
                          isExpanded: true,
                          items: _refStyles
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedStyle = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Word Count & Currency
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Word Count *'),
                        TextFormField(
                          controller: _wordsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '1000',
                            prefixIcon: Icon(Icons.format_size, size: 20),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 100) return 'Min 100 words';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Currency'),
                        DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          items: _ratesPerWord.keys
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedCurrency = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deadline Picker
              _buildSectionTitle('Submission Deadline *'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${DateFormat('EEE, MMM d, yyyy').format(_selectedDeadline)} at ${_selectedTime.format(context)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Date'),
                    ),
                    TextButton(
                      onPressed: _pickTime,
                      child: const Text('Time'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description / Instructions
              _buildSectionTitle('Brief & Detailed Instructions *'),
              TextFormField(
                controller: _instructionsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Paste questions, requirements, rubric criteria, or special guidelines...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter assignment requirements' : null,
              ),
              const SizedBox(height: 20),

              // Price Calculation Summary Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Total Price',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$sym${_calculatedPrice.toStringAsFixed(2)} $_selectedCurrency',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _loading ? null : _submitAssignment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Row(
                              children: [
                                Icon(Icons.send_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Submit Order'),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMain),
      ),
    );
  }
}
