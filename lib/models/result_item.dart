import 'dart:convert';

/// A locally saved formatted result.
class ResultItem {
  ResultItem({
    required this.title,
    required this.kind,
    required this.content,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  final String title;
  final String kind;
  final String content;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'title': title,
        'kind': kind,
        'content': content,
        'date': date.toIso8601String(),
      };

  factory ResultItem.fromJson(Map<String, dynamic> json) => ResultItem(
        title: json['title'] as String? ?? 'Untitled',
        kind: json['kind'] as String? ?? 'Text',
        content: json['content'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );

  String toJsonString() => jsonEncode(toJson());
}
