class Hutbe {
  final String id;
  final String title;
  final String content;
  final String? summary;
  final DateTime date;
  final int year;
  final String? category;
  final int? readingTimeMinutes;
  final String? sourceUrl;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  Hutbe({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.date,
    required this.year,
    this.category,
    this.readingTimeMinutes,
    this.sourceUrl,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Hutbe.fromJson(Map<String, dynamic> json) {
    return Hutbe(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      date: DateTime.parse(json['date'] as String),
      year: json['year'] as int,
      category: json['category'] as String?,
      readingTimeMinutes: json['reading_time_minutes'] as int?,
      sourceUrl: json['source_url'] as String?,
      isFeatured: json['is_featured'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'date': date.toIso8601String(),
      'year': year,
      'category': category,
      'reading_time_minutes': readingTimeMinutes,
      'source_url': sourceUrl,
      'is_featured': isFeatured,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class HutbeListItem {
  final String id;
  final String title;
  final DateTime date;
  final int year;
  final String? category;
  final int? readingTimeMinutes;
  final bool isFeatured;

  HutbeListItem({
    required this.id,
    required this.title,
    required this.date,
    required this.year,
    this.category,
    this.readingTimeMinutes,
    required this.isFeatured,
  });

  factory HutbeListItem.fromJson(Map<String, dynamic> json) {
    return HutbeListItem(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      year: json['year'] as int,
      category: json['category'] as String?,
      readingTimeMinutes: json['reading_time_minutes'] as int?,
      isFeatured: json['is_featured'] as bool,
    );
  }
}
