class CardDetail {
  final int id;
  final String name;
  final String emoji;
  double score;
  final int quantity;
  bool isOneTime;

  CardDetail({
    required this.id,
    required this.name,
    required this.emoji,
    required this.score,
    required this.quantity,
    this.isOneTime = false,
  });

  factory CardDetail.fromJson(Map<String, dynamic> json) => CardDetail(
        id:         json['id'] as int,
        name:       json['name'] as String,
        emoji:      json['emoji'] as String? ?? '🃏',
        score:      double.parse(json['score'].toString()),
        quantity:   json['quantity'] as int,
        isOneTime:  json['is_one_time'] as bool? ?? false,
      );
}
