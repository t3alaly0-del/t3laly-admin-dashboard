import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game.dart';
import '../models/card_detail.dart';
import '../models/code_model.dart';

class ApiService {
  // to be chanaged 
  //static const String _base = 'http://localhost:3000/api';
  //static const String _base = 'http://192.168.1.107:3000/api';

// static const String _base = 'http://192.168.1.10:3000/api';
static const String _base = 'https://t3lalybackend-production.up.railway.app/api';

  // ── Games ──────────────────────────────────────────────────────────────────

  static Future<List<Game>> getGames() async {
    final res = await http.get(Uri.parse('$_base/game'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => Game.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('فشل تحميل الألعاب (${res.statusCode})');
  }

  // ── Cards / points ─────────────────────────────────────────────────────────
static Future<Map<String, dynamic>> getGameScreenCards(
  int gameId,
) async {
  final res = await http.get(
    Uri.parse('$_base/cards/game-screen/$gameId'),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  throw Exception(
    'Failed to load game screen cards (${res.statusCode})',
  );
}

  static Future<List<CardDetail>> getCards(int gameId) async {
    final res = await http.get(Uri.parse('$_base/cards/$gameId'));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = body['details'] as List;
      return list.map((e) => CardDetail.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('فشل تحميل الكروت (${res.statusCode})');
  }

  static Future<void> updateCardScore(int id, double score) async {
    final res = await http.patch(
      Uri.parse('$_base/cards/details/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'score': score}),
    );
    if (res.statusCode != 200) throw Exception('فشل تحديث النقاط (${res.statusCode})');
  }

  static Future<void> updateCardIsOneTime(int id, {required bool isOneTime}) async {
    final res = await http.patch(
      Uri.parse('$_base/cards/details/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'is_one_time': isOneTime}),
    );
    if (res.statusCode != 200) throw Exception('فشل تحديث الكارت (${res.statusCode})');
  }

  // ── Codes ──────────────────────────────────────────────────────────────────

  static Future<List<CodeModel>> getCodes(int gameId) async {
    final res = await http.get(Uri.parse('$_base/codes/game/$gameId'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => CodeModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('فشل تحميل الكودات (${res.statusCode})');
  }

  static Future<List<CodeModel>> generateCodes({
    required int gameId,
    required int count,
    required int length,
    required bool numericOnly,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/codes/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'game_id': gameId,
        'count': count,
        'length': length,
        'numericOnly': numericOnly,
      }),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = body['generated'] as List;
      return list.map((e) => CodeModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('فشل التوليد (${res.statusCode})');
  }

  static Future<CodeModel> insertCode({
    required int gameId,
    required String code,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/codes/insert'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'game_id': gameId, 'code': code}),
    );
    if (res.statusCode == 201) {
      return CodeModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    final err = (jsonDecode(res.body) as Map<String, dynamic>)['error'] ?? 'خطأ';
    throw Exception(err);
  }

  static Future<void> updateCode(int id, {bool? used, String? status, DateTime? endDate, bool clearEndDate = false}) async {
    final body = <String, dynamic>{};
    if (used   != null) body['used']   = used;
    if (status != null) body['status'] = status;
    if (clearEndDate) {
      body['end_date'] = null;
    } else if (endDate != null) {
      body['end_date'] = endDate.toIso8601String().split('T')[0];
    }
    final res = await http.patch(
      Uri.parse('$_base/codes/details/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) throw Exception('فشل التحديث (${res.statusCode})');
  }

  static Future<void> deleteCode(int id) async {
    final res = await http.delete(Uri.parse('$_base/codes/details/$id'));
    if (res.statusCode != 200) throw Exception('فشل الحذف (${res.statusCode})');
  }

  static Future<int> deleteUsedCodes(int gameId) async {
    final res = await http.delete(Uri.parse('$_base/codes/game/$gameId/used'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map<String, dynamic>)['deleted'] as int;
    }
    throw Exception('فشل حذف الكودات (${res.statusCode})');
  }

  // ── Game management ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getGame(int gameId) async {
    final res = await http.get(Uri.parse('$_base/game/$gameId'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return {
        ...Map<String, dynamic>.from(data['game'] as Map? ?? {}),
        ...Map<String, dynamic>.from(data['details'] as Map? ?? {}),
      };
    }
    throw Exception('فشل تحميل اللعبة (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> updateGame({
    required int id,
    required String name,
    required String status,
    required int minPlayers,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/game/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'status': status, 'min_players': minPlayers}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('فشل تحديث اللعبة (${res.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> getGameCards(int gameId) async {
    final res = await http.get(Uri.parse('$_base/game/$gameId/cards'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    throw Exception('فشل تحميل الكروت (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> addGameCard({
    required int gameId,
    required String name,
    required double score,
    required int quantity,
    required String detailedDesc,
    required String abstractDesc,
    required String emoji,
    bool isOneTime = false,
    int? cardTypeId,
    int? judgeCategoriesId,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/game/$gameId/cards'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name, 'score': score, 'quantity': quantity,
        'detailed_desc': detailedDesc, 'abstract_desc': abstractDesc, 'emoji': emoji,
        'is_one_time': isOneTime,
        if (cardTypeId != null) 'card_type_id': cardTypeId,
        if (judgeCategoriesId != null) 'judge_categories_id': judgeCategoriesId,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 409) throw Exception('الكارت ده موجود بالفعل ⚠️');
    throw Exception('فشل إضافة الكارت (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> updateGameCard({
    required int id,
    required String name,
    required double score,
    required int quantity,
    required String detailedDesc,
    required String abstractDesc,
    required String emoji,
    bool isOneTime = false,
    int? cardTypeId,
    int? judgeCategoriesId,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/game/cards/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name, 'score': score, 'quantity': quantity,
        'detailed_desc': detailedDesc, 'abstract_desc': abstractDesc, 'emoji': emoji,
        'is_one_time': isOneTime,
        if (cardTypeId != null) 'card_type_id': cardTypeId,
        'judge_categories_id': judgeCategoriesId,
      }),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('فشل تحديث الكارت (${res.statusCode})');
  }

  static Future<void> deleteGameCard(int id) async {
    final res = await http.delete(Uri.parse('$_base/game/cards/$id'));
    if (res.statusCode != 200) throw Exception('فشل حذف الكارت (${res.statusCode})');
  }

  // ── Categories & stickers ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCategories(int gameId) async {
    final res = await http.get(Uri.parse('$_base/cards/categories/$gameId'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    throw Exception('فشل تحميل الكاتيجوريز (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> addCategory({
    required String name,
    required String emoji,
    required int gameId,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/cards/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'emoji': emoji, 'game_id': gameId}),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 409) throw Exception('الكاتيجوري دي موجودة بالفعل ⚠️');
    throw Exception('فشل إضافة الكاتيجوري (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> updateCategory({
    required int id,
    required String name,
    required String emoji,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/cards/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'emoji': emoji}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 409) throw Exception('الكاتيجوري دي موجودة بالفعل ⚠️');
    throw Exception('فشل تحديث الكاتيجوري (${res.statusCode})');
  }

  static Future<void> deleteCategory(int id) async {
    final res = await http.delete(Uri.parse('$_base/cards/categories/$id'));
    if (res.statusCode != 200) throw Exception('فشل حذف الكاتيجوري (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> addSticker({
    required int categoryId,
    required List<int> fileBytes,
    required String fileName,
    String stickerName = '',
  }) async {
    final request = http.MultipartRequest(
      'POST', Uri.parse('$_base/cards/categories/$categoryId/stickers'),
    );
    request.files.add(http.MultipartFile.fromBytes('sticker', fileBytes, filename: fileName));
    request.fields['sticker_name'] = stickerName;
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 201) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('فشل رفع الستيكر (${response.statusCode})');
  }

  static Future<void> deleteSticker(int id) async {
    final res = await http.delete(Uri.parse('$_base/cards/stickers/$id'));
    if (res.statusCode != 200) throw Exception('فشل حذف الستيكر (${res.statusCode})');
  }

  // ── Card types & judge categories ─────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCardTypes() async {
    final res = await http.get(Uri.parse('$_base/admin/card-types'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    throw Exception('فشل تحميل أنواع الكروت (${res.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> getJudgeCategories(int gameId) async {
    final res = await http.get(Uri.parse('$_base/admin/judge-categories/$gameId'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    throw Exception('فشل تحميل فئات المحكمين (${res.statusCode})');
  }

  // ── Judges / rewards ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getJudges(int gameId, String category) async {
    final res = await http.get(Uri.parse('$_base/admin/judges/$gameId'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .cast<Map<String, dynamic>>()
          .where((e) => e['category_name'] == category)
          .toList();
    }
    throw Exception('فشل تحميل الأحكام (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> addJudge({
    required int judgeCategoriesId,
    required String description,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/admin/judges'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'judge_categories_id': judgeCategoriesId, 'description': description}),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 409) throw Exception('الحكم ده موجود بالفعل ⚠️');
    throw Exception('فشل إضافة الحكم (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> updateJudge({
    required int id,
    required String description,
    required String status,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/admin/judges/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'description': description, 'status': status}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 409) throw Exception('الحكم ده موجود بالفعل ⚠️');
    throw Exception('فشل تحديث الحكم (${res.statusCode})');
  }

  static Future<void> deleteJudge(int id) async {
    final res = await http.delete(Uri.parse('$_base/admin/judges/$id'));
    if (res.statusCode != 200) throw Exception('فشل حذف الحكم (${res.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> getRewards(int gameId) async =>
      getJudges(gameId, 'reward');

  static Future<Map<String, dynamic>> addReward({required String description}) async {
    final res = await http.post(
      Uri.parse('$_base/admin/judges'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'judge_categories_id': 2, 'description': description}),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 409) throw Exception('المكافأة دي موجودة بالفعل ⚠️');
    throw Exception('فشل إضافة المكافأة (${res.statusCode})');
  }
}