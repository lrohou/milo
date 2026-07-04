class PlaylistModel {
  const PlaylistModel({
    required this.id,
    required this.name,
    this.description = '',
    this.trackIds = const [],
  });

  final String id;
  final String name;
  final String description;
  final List<String> trackIds;

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      trackIds: (json['trackIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'trackIds': trackIds,
    };
  }

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? trackIds,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      trackIds: trackIds ?? this.trackIds,
    );
  }
}
