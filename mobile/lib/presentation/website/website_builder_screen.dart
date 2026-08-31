// ==================================================
// OptigoAI Mobile — Website Builder Screen
// Public Website Management on optigoai.com/{slug}
// ==================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/website_model.dart';
import '../../data/repositories/website_repository.dart';

class WebsiteBuilderScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const WebsiteBuilderScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<WebsiteBuilderScreen> createState() => _WebsiteBuilderScreenState();
}

class _WebsiteBuilderScreenState extends State<WebsiteBuilderScreen> {
  WebsiteModel? _website;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSaving = false;

  late TextEditingController _slugController;
  late TextEditingController _seoTitleController;
  late TextEditingController _seoDescController;

  @override
  void initState() {
    super.initState();
    _slugController = TextEditingController();
    _seoTitleController = TextEditingController();
    _seoDescController = TextEditingController();
    _loadWebsite();
  }

  @override
  void dispose() {
    _slugController.dispose();
    _seoTitleController.dispose();
    _seoDescController.dispose();
    super.dispose();
  }

  Future<void> _loadWebsite() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = Provider.of<WebsiteRepository>(context, listen: false);
      final site = await repo.getWebsite(widget.businessId);
      if (mounted) {
        setState(() {
          _website = site;
          _slugController.text = site.slug;
          _seoTitleController.text = site.seoTitle ?? '';
          _seoDescController.text = site.seoDescription ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load website: $e')),
        );
      }
    }
  }

  Future<void> _generateWebsite() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final repo = Provider.of<WebsiteRepository>(context, listen: false);
      final site = await repo.generateWebsite(widget.businessId);
      if (mounted) {
        setState(() {
          _website = site;
          _slugController.text = site.slug;
          _seoTitleController.text = site.seoTitle ?? '';
          _seoDescController.text = site.seoDescription ?? '';
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Website synthesized with AI successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    }
  }

  Future<void> _togglePublish() async {
    if (_website == null) return;
    final newStatus = _website!.isPublished ? 'draft' : 'published';

    try {
      final repo = Provider.of<WebsiteRepository>(context, listen: false);
      final updated = await repo.updateStatus(
        businessId: widget.businessId,
        status: newStatus,
      );
      if (mounted) {
        setState(() {
          _website = updated;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'published'
                  ? 'Website is now LIVE on ${updated.publicUrl}'
                  : 'Website set to Draft mode',
            ),
            backgroundColor: newStatus == 'published'
                ? const Color(0xFF059669)
                : const Color(0xFFE11D48),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final repo = Provider.of<WebsiteRepository>(context, listen: false);
      final updated = await repo.updateWebsite(
        businessId: widget.businessId,
        slug: _slugController.text.trim(),
        seoTitle: _seoTitleController.text.trim(),
        seoDescription: _seoDescController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _website = updated;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Website settings saved!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: $e')),
        );
      }
    }
  }

  Future<void> _deleteWebsite() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Public Website?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will unpublish and delete the live website for ${widget.businessName}. You can regenerate it with AI anytime.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final repo = Provider.of<WebsiteRepository>(context, listen: false);
      await repo.deleteWebsite(widget.businessId);
      if (mounted) {
        await _loadWebsite();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hero = _website?.contentJson['hero'] as Map<String, dynamic>?;
    final services = (_website?.contentJson['services'] as List<dynamic>?) ?? [];
    final reviews = _website?.contentJson['reviews'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Public Website Builder',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              widget.businessName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE11D48)),
            tooltip: 'Delete Website',
            onPressed: _deleteWebsite,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWebsite,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Live Domain Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _website?.isPublished == true
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _website?.isPublished == true
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFD97706),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _website?.isPublished == true
                                          ? 'LIVE ON WEB'
                                          : 'DRAFT MODE',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: _website?.isPublished == true
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${_website?.viewCount ?? 0} Views',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _website?.publicUrl ?? 'https://optigoai.com/...',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF334155),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  if (_website != null) {
                                    Clipboard.setData(
                                      ClipboardData(text: _website!.publicUrl),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Copied URL!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _website?.isPublished == true
                                        ? const Color(0xFFF1F5F9)
                                        : const Color(0xFFE11D48),
                                    foregroundColor: _website?.isPublished == true
                                        ? const Color(0xFF0F172A)
                                        : Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _togglePublish,
                                  icon: Icon(
                                    _website?.isPublished == true
                                        ? Icons.pause_circle_outline
                                        : Icons.public,
                                    size: 16,
                                  ),
                                  label: Text(
                                    _website?.isPublished == true
                                        ? 'Unpublish'
                                        : 'Publish to Web',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. AI Synthesizer Action Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isGenerating ? null : _generateWebsite,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, color: Colors.white),
                        label: Text(
                          _isGenerating
                              ? 'Synthesizing with AI...'
                              : '⚡ AI Re-Generate Content',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Section Overview Preview
                    Text(
                      'WEBSITE SECTIONS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Hero Preview Card
                    _buildSectionTile(
                      icon: Icons.title,
                      title: 'Hero Section',
                      subtitle: hero?['headline'] ?? 'Handcrafted Experience',
                    ),
                    const SizedBox(height: 8),

                    // Offerings Preview Card
                    _buildSectionTile(
                      icon: Icons.local_offer_outlined,
                      title: 'Specialties & Offerings',
                      subtitle: '${services.length} items configured',
                    ),
                    const SizedBox(height: 8),

                    // Reviews Preview Card
                    _buildSectionTile(
                      icon: Icons.star_border,
                      title: 'Google Reviews',
                      subtitle:
                          '${reviews?['average_rating'] ?? 4.8}★ (${reviews?['total_reviews'] ?? 20}+ verified)',
                    ),
                    const SizedBox(height: 20),

                    // 4. Slug & SEO Settings
                    Text(
                      'DOMAIN & SEO METADATA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _slugController,
                            decoration: InputDecoration(
                              labelText: 'URL Slug (optigoai.com/...)',
                              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                              prefixText: 'optigoai.com/',
                              prefixStyle: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _seoTitleController,
                            decoration: InputDecoration(
                              labelText: 'SEO Title Tag',
                              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _seoDescController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'SEO Meta Description',
                              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _isSaving ? null : _saveSettings,
                              child: Text(
                                _isSaving ? 'Saving...' : 'Save Settings',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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

  Widget _buildSectionTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF0284C7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
        ],
      ),
    );
  }
}
