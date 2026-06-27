class Game {
  final int id;
  final String name;
  final String? description;
  final int contentVersion;
  final String status; // 'open' | 'freeze'

  Game({
    required this.id,
    required this.name,
    this.description,
    required this.contentVersion,
    required this.status,
  });

  factory Game.fromJson(Map<String, dynamic> json) => Game(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        contentVersion: json['content_version'] as int,
        status: json['status'] as String,
      );

  bool get isOpen => status == 'open';
}