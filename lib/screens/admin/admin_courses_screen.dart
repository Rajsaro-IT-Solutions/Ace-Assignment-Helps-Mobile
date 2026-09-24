import 'package:flutter/material.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminCoursesScreen extends StatefulWidget {
  final UserModel user;

  const AdminCoursesScreen({super.key, required this.user});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  bool _loading = true;
  List<CourseModel> _courses = [];
  List<CourseModel> _filtered = [];
  final _searchCtrl = TextEditingController();
  String _selectedStatusFilter = 'All';

  final List<String> _categories = [
    'Computer Science & AI',
    'Engineering & Technology',
    'Business & Management',
    'Nursing & Healthcare',
    'Law & Legal Studies',
    'Humanities & Social Sciences',
    'Mathematics & Analytics',
    'Natural Sciences',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() => _loading = true);
    final list = await ApiService.getCourses();
    if (mounted) {
      setState(() {
        _courses = list;
        _applyFilter();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _courses.where((c) {
        final matchesQuery = query.isEmpty ||
            c.title.toLowerCase().contains(query) ||
            c.courseId.toLowerCase().contains(query) ||
            c.category.toLowerCase().contains(query);

        final matchesStatus = _selectedStatusFilter == 'All' ||
            c.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  void _showCourseDialog({CourseModel? course}) {
    final isEdit = course != null;
    final titleCtrl = TextEditingController(text: course?.title ?? '');
    String selectedCategory = (course != null && _categories.contains(course.category))
        ? course.category
        : _categories.first;
    final iconCtrl = TextEditingController(text: course?.icon ?? 'fa-book-open');
    final descCtrl = TextEditingController(text: course?.description ?? '');
    final topicsCtrl = TextEditingController(text: course?.topics ?? '');
    String selectedStatus = course?.status ?? 'Active';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                  color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                isEdit ? 'Edit Course / Subject' : 'Add New Course / Subject',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course Title *',
                    hintText: 'e.g. Data Structures & Algorithms',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Academic Category *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: iconCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Icon Tag / Class',
                    hintText: 'fa-laptop-code or fa-book-open',
                    prefixIcon: Icon(Icons.palette_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Course Overview & Description',
                    hintText: 'Summary of subject modules...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicsCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Key Topics & Modules',
                    hintText: 'Comma-separated (e.g. Python, Graphs, Trees)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.toggle_on_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active (Visible)')),
                    DropdownMenuItem(value: 'Inactive', child: Text('Inactive (Hidden)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedStatus = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a course title'),
                            backgroundColor: AppTheme.warning,
                          ),
                        );
                        return;
                      }

                      setDlgState(() => saving = true);
                      bool ok = false;
                      if (isEdit) {
                        ok = await ApiService.updateCourse(
                          courseId: course.courseId,
                          title: title,
                          category: selectedCategory,
                          icon: iconCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          topics: topicsCtrl.text.trim(),
                          status: selectedStatus,
                        );
                      } else {
                        ok = await ApiService.createCourse(
                          title: title,
                          category: selectedCategory,
                          icon: iconCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          topics: topicsCtrl.text.trim(),
                          status: selectedStatus,
                        );
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      if (ok) {
                        _fetchCourses();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit
                                  ? 'Course updated successfully!'
                                  : 'New course created and published!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save course. Check database connection.'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'Update Course' : 'Create Course'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCourse(CourseModel course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to permanently delete "${course.title}" (${course.courseId})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete Course'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ApiService.deleteCourse(course.courseId);
    if (mounted) {
      if (ok) {
        _fetchCourses();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course "${course.title}" removed.'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete course.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _toggleStatus(CourseModel course) async {
    final newStatus = course.status.toLowerCase() == 'active' ? 'Inactive' : 'Active';
    final ok = await ApiService.toggleCourseStatus(course.courseId, newStatus);
    if (mounted) {
      if (ok) {
        _fetchCourses();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status changed to $newStatus'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Courses & Academic Subjects'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchCourses),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Course', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applyFilter(),
                  decoration: InputDecoration(
                    hintText: 'Search by title, course code, or category...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Status Filter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      children: ['All', 'Active', 'Inactive'].map((s) {
                        final isSel = _selectedStatusFilter == s;
                        return ChoiceChip(
                          label: Text(s, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppTheme.textMain)),
                          selected: isSel,
                          selectedColor: AppTheme.primary,
                          onSelected: (_) {
                            setState(() => _selectedStatusFilter = s);
                            _applyFilter();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 54, color: AppTheme.textDim),
                            const SizedBox(height: 12),
                            const Text('No courses found', style: TextStyle(color: AppTheme.textMuted)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showCourseDialog(),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add First Course'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final item = _filtered[i];
                          final isActive = item.status.toLowerCase() == 'active';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.primaryLight,
                                        radius: 20,
                                        child: const Icon(Icons.school_rounded, color: AppTheme.primary, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            const SizedBox(height: 2),
                                            Text('${item.courseId} • ${item.category}',
                                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _toggleStatus(item),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isActive ? AppTheme.successBg : AppTheme.dangerBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.status,
                                            style: TextStyle(
                                              color: isActive ? AppTheme.success : AppTheme.danger,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textDim),
                                    ),
                                  ],
                                  if (item.topics.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: item.topics.split(',').take(4).map((t) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.bg,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppTheme.border),
                                          ),
                                          child: Text(t.trim(), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _showCourseDialog(course: item),
                                        icon: const Icon(Icons.edit_rounded, size: 16),
                                        label: const Text('Edit'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _confirmDeleteCourse(item),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.danger),
                                        label: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
