class ReviewModel {
  final String id;
  final String businessId;
  final String reviewerName;
  final int rating;
  final String? text;
  final String? reviewDate;
  final String? sentiment;
  final String? aiSummary;
  final String? keyThemes;
  final String? replyText;
  final String? aiGeneratedReply;
  final bool isReplied;
  final String source;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.businessId,
    required this.reviewerName,
    required this.rating,
    this.text,
    this.reviewDate,
    this.sentiment,
    this.aiSummary,
    this.keyThemes,
    this.replyText,
    this.aiGeneratedReply,
    required this.isReplied,
    required this.source,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      reviewerName: json['reviewer_name'] as String,
      rating: json['rating'] as int? ?? 5,
      text: json['text'] as String?,
      reviewDate: json['review_date'] as String?,
      sentiment: json['sentiment'] as String?,
      aiSummary: json['ai_summary'] as String?,
      keyThemes: json['key_themes'] as String?,
      replyText: json['reply_text'] as String?,
      aiGeneratedReply: json['ai_generated_reply'] as String?,
      isReplied: json['is_replied'] as bool? ?? false,
      source: json['source'] as String? ?? 'gbp',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
