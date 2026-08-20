class GeneratedPostItemModel {
  final String channel;
  final String? title;
  final String body;
  final String? hashtags;
  final String? callToAction;
  final String? imagePrompt;
  final String? bestTimeToPost;

  GeneratedPostItemModel({
    required this.channel,
    this.title,
    required this.body,
    this.hashtags,
    this.callToAction,
    this.imagePrompt,
    this.bestTimeToPost,
  });

  factory GeneratedPostItemModel.fromJson(Map<String, dynamic> json) {
    return GeneratedPostItemModel(
      channel: json['channel'] as String? ?? 'google_post',
      title: json['title'] as String?,
      body: json['body'] as String? ?? '',
      hashtags: json['hashtags'] as String?,
      callToAction: json['call_to_action'] as String?,
      imagePrompt: json['image_prompt'] as String?,
      bestTimeToPost: json['best_time_to_post'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      'title': title,
      'body': body,
      'hashtags': hashtags,
      'call_to_action': callToAction,
      'image_prompt': imagePrompt,
      'best_time_to_post': bestTimeToPost,
    };
  }
}

class ContentGenerateResponseModel {
  final String businessId;
  final String campaignTheme;
  final List<GeneratedPostItemModel> posts;
  final List<dynamic> calendarSuggestions;

  ContentGenerateResponseModel({
    required this.businessId,
    required this.campaignTheme,
    required this.posts,
    required this.calendarSuggestions,
  });

  factory ContentGenerateResponseModel.fromJson(Map<String, dynamic> json) {
    return ContentGenerateResponseModel(
      businessId: json['business_id'] as String? ?? '',
      campaignTheme: json['campaign_theme'] as String? ?? '',
      posts: (json['posts'] as List<dynamic>?)
              ?.map((e) => GeneratedPostItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      calendarSuggestions: json['calendar_suggestions'] as List<dynamic>? ?? [],
    );
  }
}

class ContentModel {
  final String id;
  final String businessId;
  final String contentType;
  final String? title;
  final String body;
  final String? tone;
  final String? hashtags;
  final String? callToAction;
  final String? imagePrompt;
  final String? imageUrl;
  final String status;
  final String? scheduledAt;
  final String? publishedAt;
  final String? createdAt;

  ContentModel({
    required this.id,
    required this.businessId,
    required this.contentType,
    this.title,
    required this.body,
    this.tone,
    this.hashtags,
    this.callToAction,
    this.imagePrompt,
    this.imageUrl,
    required this.status,
    this.scheduledAt,
    this.publishedAt,
    this.createdAt,
  });

  bool get isDraft => status == 'draft';
  bool get isScheduled => status == 'scheduled';
  bool get isPublished => status == 'published';

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      contentType: json['content_type'] as String? ?? 'google_post',
      title: json['title'] as String?,
      body: json['body'] as String? ?? '',
      tone: json['tone'] as String?,
      hashtags: json['hashtags'] as String?,
      callToAction: json['call_to_action'] as String?,
      imagePrompt: json['image_prompt'] as String?,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'draft',
      scheduledAt: json['scheduled_at'] as String?,
      publishedAt: json['published_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'content_type': contentType,
      'title': title,
      'body': body,
      'tone': tone,
      'hashtags': hashtags,
      'call_to_action': callToAction,
      'image_prompt': imagePrompt,
      'image_url': imageUrl,
      'status': status,
      'scheduled_at': scheduledAt,
      'published_at': publishedAt,
      'created_at': createdAt,
    };
  }
}
