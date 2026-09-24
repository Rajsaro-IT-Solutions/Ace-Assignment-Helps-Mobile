import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class ExpertSolutionUploadDialog extends StatefulWidget {
  final AssignmentModel assignment;
  final UserModel currentUser;
  final VoidCallback onUploaded;

  const ExpertSolutionUploadDialog({
    super.key,
    required this.assignment,
    required this.currentUser,
    required this.onUploaded,
  });

  static Future<void> show(
    BuildContext context, {
    required AssignmentModel assignment,
    required UserModel currentUser,
    required VoidCallback onUploaded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExpertSolutionUploadDialog(
        assignment: assignment,
        currentUser: currentUser,
        onUploaded: onUploaded,
      ),
    );
  }

  @override
  State<ExpertSolutionUploadDialog> createState() => _ExpertSolutionUploadDialogState();
}

class _ExpertSolutionUploadDialogState extends State<ExpertSolutionUploadDialog> {
  final _notesCtrl = TextEditingController();
  final _wordCountCtrl = TextEditingController();

  File? _solutionFile;
  String? _solutionFileName;
  int _solutionFileSize = 0;

  File? _turnitinFile;
  String? _turnitinFileName;
  int _turnitinFileSize = 0;

  String _stage = 'complete'; // 'complete' or 'draft'
  bool _uploading = false;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _wordCountCtrl.text = widget.assignment.wordCount.toString();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _wordCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickSolutionFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        setState(() {
          _solutionFile = File(result.files.first.path!);
          _solutionFileName = result.files.first.name;
          _solutionFileSize = result.files.first.size;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File pick error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _pickTurnitinFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        setState(() {
          _turnitinFile = File(result.files.first.path!);
          _turnitinFileName = result.files.first.name;
          _turnitinFileSize = result.files.first.size;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File pick error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _submitSolution() async {
    if (_solutionFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your final solution document.'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _uploadStatus = 'Uploading solution deliverable...';
    });

    // 1. Upload Primary Solution File
    final solUploadOk = await ApiService.uploadFile(
      assignmentId: widget.assignment.assignmentId,
      file: _solutionFile!,
      fileStage: _stage,
      uploadedBy: 'Expert (${widget.currentUser.name}) ${_stage == "draft" ? "Draft" : "Solution"}',
      isInternal: false,
    );

    if (!solUploadOk) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload primary solution file. Please try again.'), backgroundColor: AppTheme.danger),
        );
      }
      return;
    }

    // 2. Upload Turnitin Plagiarism Report if provided
    if (_turnitinFile != null) {
      setState(() => _uploadStatus = 'Uploading Turnitin plagiarism report...');
      await ApiService.uploadFile(
        assignmentId: widget.assignment.assignmentId,
        file: _turnitinFile!,
        fileStage: _stage,
        uploadedBy: 'Expert (${widget.currentUser.name}) Turnitin Report',
        isInternal: false,
      );
    }

    // 3. Update Status
    setState(() => _uploadStatus = 'Finalizing deliverable submission...');
    final targetStatus = (_stage == 'draft') ? 'In Progress' : 'Quality Check';
    final statusOk = await ApiService.updateStatus(
      assignmentId: widget.assignment.assignmentId,
      status: targetStatus,
      userId: widget.currentUser.id,
      role: widget.currentUser.role,
    );

    if (mounted) {
      setState(() => _uploading = false);
      if (statusOk) {
        Navigator.pop(context);
        widget.onUploaded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_stage == 'draft' 
              ? 'Milestone draft saved successfully!' 
              : 'Solution submitted for Allocator QA Review!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deliverable saved, but status update failed. Check connection.'), backgroundColor: AppTheme.warning),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cloud_upload_rounded, color: AppTheme.success, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Solution Package',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Order ID: ${widget.assignment.assignmentId}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                ),
              ],
            ),
            const Divider(height: 24),

            // Deliverable stage toggle
            const Text('Deliverable Stage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text('Final Solution (QA)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    selected: _stage == 'complete',
                    selectedColor: AppTheme.success.withValues(alpha: 0.2),
                    onSelected: (val) {
                      if (val) setState(() => _stage = 'complete');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text('Milestone Draft', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    selected: _stage == 'draft',
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                    onSelected: (val) {
                      if (val) setState(() => _stage = 'draft');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Primary Solution Document Picker
            const Text('1. Primary Solution Document *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickSolutionFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: _solutionFile != null ? AppTheme.success : Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: _solutionFile != null ? AppTheme.success.withValues(alpha: 0.05) : Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Icon(
                      _solutionFile != null ? Icons.file_present_rounded : Icons.upload_file_rounded,
                      color: _solutionFile != null ? AppTheme.success : AppTheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _solutionFileName ?? 'Browse & Select Solution Document',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _solutionFile != null ? AppTheme.textPrimary : AppTheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _solutionFile != null ? _formatBytes(_solutionFileSize) : 'DOCX, PDF, ZIP, XLSX, PPTX, PY, etc.',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (_solutionFile != null)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20, color: AppTheme.danger),
                        onPressed: () => setState(() {
                          _solutionFile = null;
                          _solutionFileName = null;
                          _solutionFileSize = 0;
                        }),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Optional Turnitin / Plagiarism Report Picker
            const Text('2. Plagiarism / Turnitin Report (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickTurnitinFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: _turnitinFile != null ? AppTheme.info : Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: _turnitinFile != null ? AppTheme.info.withValues(alpha: 0.05) : Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Icon(
                      _turnitinFile != null ? Icons.verified_user_rounded : Icons.security_rounded,
                      color: _turnitinFile != null ? AppTheme.info : AppTheme.textMuted,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _turnitinFileName ?? 'Select Turnitin Similarity PDF (Optional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _turnitinFile != null ? AppTheme.textPrimary : AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _turnitinFile != null ? _formatBytes(_turnitinFileSize) : 'Recommended for premium QA approval',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (_turnitinFile != null)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20, color: AppTheme.danger),
                        onPressed: () => setState(() {
                          _turnitinFile = null;
                          _turnitinFileName = null;
                          _turnitinFileSize = 0;
                        }),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Completed Word Count
            const Text('Deliverable Word Count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _wordCountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 2500',
                prefixIcon: const Icon(Icons.numbers_rounded, color: AppTheme.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 14),

            // Methodology / QA Notes
            const Text('Solution & Methodology Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Explain key findings, calculations, software used, or specific guidance for the student and QA allocator...',
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 20),

            if (_uploading) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(_uploadStatus, style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitSolution,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    _stage == 'complete' ? 'Submit Final Solution to QA' : 'Save Milestone Draft',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _stage == 'complete' ? AppTheme.success : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
