import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  final _couponController = TextEditingController();

  String _selectedSubject = 'Computer Science & Artificial Intelligence';
  String _selectedType = 'Essay';
  String _selectedStyle = 'APA 7th Edition';
  String _selectedCurrency = 'USD';
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 5));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 23, minute: 59);

  // File Picker
  final List<PlatformFile> _selectedFiles = [];

  // Coupon
  CouponModel? _appliedCoupon;
  String? _couponMessage;
  bool _validatingCoupon = false;

  // Payment Deposit Option: '20', '50', '100'
  String _depositOption = '20'; // Default to 20% deposit to lower friction

  bool _loading = false;
  String _uploadStatusText = '';
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
    _couponController.dispose();
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

  double get _basePrice {
    final words = int.tryParse(_wordsController.text) ?? 1000;
    final rate = _ratesPerWord[_selectedCurrency] ?? 0.05;
    return words * rate;
  }

  double get _discountAmount {
    if (_appliedCoupon != null) {
      return _basePrice * (_appliedCoupon!.discountPercent / 100.0);
    }
    return 0.0;
  }

  double get _finalPrice {
    return (_basePrice - _discountAmount).clamp(0.0, double.infinity);
  }

  double get _payableNow {
    if (_depositOption == '20') return _finalPrice * 0.20;
    if (_depositOption == '50') return _finalPrice * 0.50;
    return _finalPrice;
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'zip', 'txt', 'rtf', 'xlsx', 'pptx', 'csv'],
      );
      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _validatingCoupon = true;
      _couponMessage = null;
    });

    final coupons = await ApiService.getCoupons();
    final match = coupons.where((c) => c.code.toLowerCase() == code.toLowerCase() && c.status.toLowerCase() == 'active').toList();

    if (mounted) {
      setState(() {
        _validatingCoupon = false;
        if (match.isNotEmpty) {
          _appliedCoupon = match.first;
          _couponMessage = 'Coupon applied! ${_appliedCoupon!.discountPercent}% OFF';
        } else {
          _appliedCoupon = null;
          _couponMessage = 'Invalid or expired promo code';
        }
      });
    }
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

    setState(() {
      _loading = true;
      _uploadStatusText = 'Creating assignment order...';
    });

    final finalDeadline = DateTime(
      _selectedDeadline.year,
      _selectedDeadline.month,
      _selectedDeadline.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // 1. Submit Assignment
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
      price: _finalPrice,
    );

    if (!mounted) return;

    if (res.success && res.data != null) {
      final assignId = res.data!['assignment_id'] ?? 'AAH-NEW';

      // 2. Upload any attached files
      if (_selectedFiles.isNotEmpty) {
        for (int i = 0; i < _selectedFiles.length; i++) {
          final f = _selectedFiles[i];
          if (f.path != null) {
            setState(() {
              _uploadStatusText = 'Uploading document ${i + 1} of ${_selectedFiles.length}...';
            });
            await ApiService.uploadAssignmentFile(
              assignmentId: assignId,
              filePath: f.path!,
              fileName: f.name,
              fileStage: 'brief',
              uploadedBy: widget.user.name,
            );
          }
        }
      }

      // 3. Register deposit payment
      final payable = _payableNow;
      if (payable > 0) {
        setState(() {
          _uploadStatusText = 'Registering payment confirmation...';
        });
        await ApiService.processPartialPayment(
          assignmentId: assignId,
          studentId: widget.user.id,
          amount: payable,
          paymentMethod: 'Stripe / Online',
          currency: _selectedCurrency,
        );
      }

      setState(() => _loading = false);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
              SizedBox(width: 10),
              Text('Order Placed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assignment Created: $assignId', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Total Price: ${_currencySymbols[_selectedCurrency]}${_finalPrice.toStringAsFixed(2)}'),
              Text('Amount Paid Today: ${_currencySymbols[_selectedCurrency]}${payable.toStringAsFixed(2)} (${_depositOption == '100' ? 'Full Payment' : '$_depositOption% Deposit'})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Attached Files: ${_selectedFiles.length} file(s) synchronized with expert workspace.'),
              ],
              const SizedBox(height: 12),
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
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Submission failed.'),
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
                      'Upload brief materials, lock in guaranteed grades & get 20% part-payment deposit.',
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
                items: (_courses.isNotEmpty
                        ? _courses.map((c) => c.title)
                        : [
                            'Computer Science & Artificial Intelligence',
                            'Business Administration & MBA',
                            'Nursing & Clinical Healthcare',
                            'Engineering & Physical Sciences',
                            'Law & Legal Studies',
                            'Data Analytics & Statistics',
                          ])
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                    .toList(),
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
                    TextButton(onPressed: _pickDate, child: const Text('Date')),
                    TextButton(onPressed: _pickTime, child: const Text('Time')),
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
              const SizedBox(height: 16),

              // File Attachments Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Attached Documents (${_selectedFiles.length})'),
                  TextButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    label: const Text('Add Files'),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: _selectedFiles.isEmpty
                    ? InkWell(
                        onTap: _pickFiles,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 36, color: AppTheme.primary),
                              SizedBox(height: 6),
                              Text('Tap to attach rubrics, brief PDFs, datasets, or slides',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              Text('.pdf, .docx, .zip, .xlsx, .pptx supported',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _selectedFiles.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final f = entry.value;
                          final sizeKb = (f.size / 1024).toStringAsFixed(1);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file_outlined, size: 20, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(f.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('$sizeKb KB', style: const TextStyle(fontSize: 10, color: AppTheme.textDim)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.danger),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFiles.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),

              // Promo / Coupon Code Section
              _buildSectionTitle('Discount Promo Coupon'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'e.g. ACE20, WELCOME10',
                        prefixIcon: Icon(Icons.local_offer_outlined, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _validatingCoupon ? null : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      backgroundColor: AppTheme.secondary,
                    ),
                    child: _validatingCoupon
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Apply'),
                  ),
                ],
              ),
              if (_couponMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _couponMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _appliedCoupon != null ? AppTheme.success : AppTheme.danger,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Deposit Payment Selector
              _buildSectionTitle('Choose Payment Schedule'),
              Row(
                children: [
                  _buildDepositPill('20% Deposit', '20', 'Start work immediately'),
                  const SizedBox(width: 8),
                  _buildDepositPill('50% Half', '50', 'Milestone release'),
                  const SizedBox(width: 8),
                  _buildDepositPill('100% Full', '100', 'Paid in full'),
                ],
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Base Quote (${_wordsController.text} words):', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text('$sym${_basePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (_appliedCoupon != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Coupon Discount (${_appliedCoupon!.discountPercent}%):', style: const TextStyle(fontSize: 12, color: AppTheme.success)),
                          Text('-$sym${_discountAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.success)),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payable Today ($_depositOption%):',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '$sym${_payableNow.toStringAsFixed(2)} $_selectedCurrency',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _loading ? null : _submitAssignment,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          ),
                          child: _loading
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text(_uploadStatusText, style: const TextStyle(fontSize: 10)),
                                  ],
                                )
                              : const Row(
                                  children: [
                                    Icon(Icons.send_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Confirm Order'),
                                  ],
                                ),
                        ),
                      ],
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

  Widget _buildDepositPill(String title, String value, String sub) {
    final selected = _depositOption == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _depositOption = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: selected ? AppTheme.primary : AppTheme.textMain)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 9, color: AppTheme.textDim), textAlign: TextAlign.center),
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
