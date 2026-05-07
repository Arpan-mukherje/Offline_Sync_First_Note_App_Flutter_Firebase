import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  bool isLiked;

  @HiveField(4)
  bool isSaved;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isSynced;

  @HiveField(8)
  DateTime? cachedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.isLiked = false,
    this.isSaved = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.cachedAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    bool? isLiked,
    bool? isSaved,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? cachedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map, String docId) {
    return Note(
      id: docId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      isLiked: map['isLiked'] ?? false,
      isSaved: map['isSaved'] ?? false,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      isSynced: true,
      cachedAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'Note(id: $id, title: $title, isLiked: $isLiked, isSaved: $isSaved, isSynced: $isSynced)';
}
