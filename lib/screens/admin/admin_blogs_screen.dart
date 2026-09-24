import 'package:flutter/material.dart';
import '../../core/models/portal_models.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminBlogsScreen extends StatefulWidget {
  final UserModel user;

  const AdminBlogsScreen({super.key, required this.user});

  @override
  State<AdminBlogsScreen> createState() => _AdminBlogsScreenState();
}

class _AdminBlogsScreenState extends State<AdminBlogsScreen> {
  bool _loading = true;
  List<BlogModel> _blogs = [];

  @override
  void initState() {
    super.initState();
    _fetchBlogs();
  }

  Future<void> _fetchBlogs() async {
    setState(() => _loading = true);
    final list = await ApiService.getBlogs();
    if (mounted) {
      setState(() {
        _blogs = list;
        _loading = false;
      });
    }
  }

  void _showBlogDialog({BlogModel? blog}) {
    final isEdit = blog != null;
    final titleCtrl = TextEditingController(text: blog?.title ?? '');
    final catCtrl = TextEditingController(text: blog?.category ?? 'Academic Writing');
    final excerptCtrl = TextEditingController(text: blog?.excerpt ?? '');
    final contentCtrl = TextEditingController(text: blog?.content ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit_note_rounded : Icons.post_add_rounded, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                isEdit ? 'Edit Blog Article' : 'Publish Blog Article',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Article Title *', hintText: 'e.g. 5 Rules for APA Referencing'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(labelText: 'Category', hintText: 'Research, Essays, Guides'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: excerptCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Short Excerpt *', hintText: 'Brief summary for students...'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Article Content *', hintText: 'Full article body...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      final excerpt = excerptCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      final category = catCtrl.text.trim();

                      if (title.isEmpty || excerpt.isEmpty || content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppTheme.warning),
                        );
                        return;
                      }

                      setDlgState(() => saving = true);
                      bool ok = false;
                      if (isEdit) {
                        ok = await ApiService.updateBlog(
                          blogId: blog.id,
                          title: title,
                          excerpt: excerpt,
                          content: content,
                          category: category.isNotEmpty ? category : 'General',
                        );
                      } else {
                        ok = await ApiService.createBlog(
                          title: title,
                          excerpt: excerpt,
                          author: widget.user.name,
                          category: category.isNotEmpty ? category : 'General',
                        );
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (ok) {
                        _fetchBlogs();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Article updated successfully!' : 'Article published successfully!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to save article.'), backgroundColor: AppTheme.danger),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Save Changes' : 'Publish Article'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBlog(int blogId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Article'),
        content: Text('Are you sure you want to delete "$title"? This removes it from the public platform.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ApiService.deleteBlog(blogId);
    if (mounted) {
      if (ok) {
        _fetchBlogs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article deleted'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete article'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Academic & Marketing Articles'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchBlogs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBlogDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Article', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article_outlined, size: 54, color: AppTheme.textDim),
                      const SizedBox(height: 12),
                      const Text('No blog articles published yet', style: TextStyle(color: AppTheme.textMuted)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showBlogDialog(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Publish First Article'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _blogs.length,
                  itemBuilder: (ctx, i) {
                    final blog = _blogs[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    blog.category,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
                                  ),
                                ),
                                const Spacer(),
                                Text(blog.publishedAt, style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(blog.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                            const SizedBox(height: 6),
                            Text(blog.excerpt, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                            const Divider(height: 20),
                            Row(
                              children: [
                                Text('By ${blog.author}', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                                  tooltip: 'Edit Article',
                                  onPressed: () => _showBlogDialog(blog: blog),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.danger),
                                  tooltip: 'Delete Article',
                                  onPressed: () => _confirmDeleteBlog(blog.id, blog.title),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
