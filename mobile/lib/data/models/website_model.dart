// ==================================================
// OptigoAI Mobile — Business Website Data Model
// ==================================================

class WebsiteModel {
  final String id;
  final String businessId;
  final String organizationId;
  final String slug;
  final String status;
  final String? seoTitle;
  final String? seoDescription;
  final Map<String, dynamic> contentJson;
  final String? customHtml;
  final String? customCss;
  final String? customJs;
  final int viewCount;
  final String? publishedAt;
  final String? createdAt;
  final String? updatedAt;

  WebsiteModel({
    required this.id,
    required this.businessId,
    required this.organizationId,
    required this.slug,
    required this.status,
    this.seoTitle,
    this.seoDescription,
    required this.contentJson,
    this.customHtml,
    this.customCss,
    this.customJs,
    this.viewCount = 0,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory WebsiteModel.fromJson(Map<String, dynamic> json) {
    return WebsiteModel(
      id: json['id'] ?? '',
      businessId: json['business_id'] ?? '',
      organizationId: json['organization_id'] ?? '',
      slug: json['slug'] ?? '',
      status: json['status'] ?? 'draft',
      seoTitle: json['seo_title'],
      seoDescription: json['seo_description'],
      contentJson: (json['content_json'] is Map<String, dynamic>)
          ? json['content_json']
          : {},
      customHtml: json['custom_html'],
      customCss: json['custom_css'],
      customJs: json['custom_js'],
      viewCount: json['view_count'] ?? 0,
      publishedAt: json['published_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'organization_id': organizationId,
      'slug': slug,
      'status': status,
      'seo_title': seoTitle,
      'seo_description': seoDescription,
      'content_json': contentJson,
      'custom_html': customHtml,
      'custom_css': customCss,
      'custom_js': customJs,
      'view_count': viewCount,
      'published_at': publishedAt,
    };
  }

  bool get isPublished => status == 'published';
  String get publicUrl => 'https://optigoai.com/$slug';
}
