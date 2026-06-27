class CodeModel {
  final int id;
  final String code; // hash_code from DB
  final bool used;
  final String usedBy; // device_identifier or ''
  final DateTime? activatedAt; // device_token_issued_at
  final DateTime? expiry; // end_date

  const CodeModel({
    required this.id,
    required this.code,
    required this.used,
    this.usedBy = '',
    this.activatedAt,
    this.expiry,
  });

  // منتهية = end_date is set AND that date is today or in the past
  bool get isExpired => expiry != null && !expiry!.isAfter(DateTime.now());

  // Matches the admin UI filter values: 'unused' | 'used' | 'expired'
  String get status {
    if (isExpired) return 'expired';
    if (used) return 'used';
    return 'unused';
  }

  factory CodeModel.fromJson(Map<String, dynamic> json) {
    final endDate = json['end_date'] != null
        ? DateTime.tryParse(json['end_date'].toString())
        : null;
    final activated = json['device_token_issued_at'] != null
        ? DateTime.tryParse(json['device_token_issued_at'].toString())
        : null;
    return CodeModel(
      id: json['id'] as int,
      code: json['hash_code'] as String,
      used: json['used'] as bool? ?? false,
      usedBy: json['device_identifier'] as String? ?? '',
      activatedAt: activated,
      expiry: endDate,
    );
  }

  CodeModel copyWith({
    bool? used,
    String? usedBy,
    DateTime? activatedAt,
    DateTime? newExpiry,
    bool clearExpiry = false,
  }) =>
      CodeModel(
        id: id,
        code: code,
        used: used ?? this.used,
        usedBy: usedBy ?? this.usedBy,
        activatedAt: activatedAt ?? this.activatedAt,
        expiry: clearExpiry ? null : (newExpiry ?? expiry),
      );
}
