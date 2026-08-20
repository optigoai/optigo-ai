class BusinessModel {
  final String id;
  final String name;
  final String? category;
  final String? location;
  final String? website;
  final String? phone;
  final String? description;
  final int? healthScore;
  final bool onboardingCompleted;
  final Map<String, dynamic>? aiBusinessProfile;
  final DateTime createdAt;

  BusinessModel({
    required this.id,
    required this.name,
    this.category,
    this.location,
    this.website,
    this.phone,
    this.description,
    this.healthScore,
    required this.onboardingCompleted,
    this.aiBusinessProfile,
    required this.createdAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      healthScore: json['health_score'] as int?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      aiBusinessProfile: json['ai_business_profile'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
