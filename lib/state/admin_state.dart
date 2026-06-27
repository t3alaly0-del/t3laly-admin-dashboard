import 'package:flutter/foundation.dart';
import 'package:t3laly_shared/shared.dart';
import '../models/game.dart';
import '../models/card_detail.dart';
import '../models/code_model.dart';
import '../services/api_service.dart';

enum CodeFilter { all, unused, used, expired }

/// Single source of truth for the admin dashboard — a direct port of the
/// `state` object + functions in the HTML prototype (`addCategory`,
/// `adjustPoint`, `generateCodes`, etc.), just reshaped into a
/// ChangeNotifier so every page rebuilds automatically via Provider.
class AdminState extends ChangeNotifier {
  AdminState() {
    fetchGames();
  }

  // ---- DB Games ----
  List<Game> games = [];
  bool isLoading = false;
  String? error;
  bool _userBrowsingGames = false; // set true only by explicit back-navigation
  final Map<String, DateTime> _lastFetched = {};

  bool _isStale(String key, {int seconds = 30}) {
    final last = _lastFetched[key];
    return last == null || DateTime.now().difference(last).inSeconds > seconds;
  }

  void _markFetched(String key) => _lastFetched[key] = DateTime.now();

  Future<void> fetchGames() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      games = await ApiService.getGames();
      // Auto-open the first game on startup/refresh unless user explicitly
      // navigated to the games list via backToGamesList().
      if (games.isNotEmpty && _selectedPack == null && !_userBrowsingGames) {
        openGame(games.first);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---- Selected game / pack ----
  GamePack? _selectedPack;
  GamePack? get selectedPack => _selectedPack;

  void openGame(Game game) {
    _userBrowsingGames = false;
    _selectedPack = GamePack(
      id: game.id.toString(),
      name: game.name,
      codes: [],
    );
    codeFilter = CodeFilter.all;
    fetchCards(game.id);
    fetchCodes(game.id);
    notifyListeners();
  }

  void backToGamesList() {
    _userBrowsingGames = true;
    _selectedPack = null;
    cardDetails = [];
    codes = [];
    notifyListeners();
  }

  // ---- Card details (نقاط الكروت) ----
  List<CardDetail> cardDetails = [];
  bool isLoadingCards = false;
  String? cardError;

  Future<void> fetchCards(int gameId, {bool force = false}) async {
    if (!force && !_isStale('cards')) return;
    isLoadingCards = true;
    cardError = null;
    notifyListeners();
    try {
      cardDetails = await ApiService.getCards(gameId);
      _markFetched('cards');
    } catch (e) {
      cardError = e.toString();
    } finally {
      isLoadingCards = false;
      notifyListeners();
    }
  }

  void adjustCardScore(int id, double delta) {
    final detail = cardDetails.firstWhere((d) => d.id == id);
    final rounded = ((detail.score + delta) * 10).round() / 10;
    detail.score = rounded;
    notifyListeners();
  }

  Future<void> saveCardScores() async {
    await Future.wait(
      cardDetails.map((d) => ApiService.updateCardScore(d.id, d.score)),
    );
  }

  Future<void> toggleCardOneTime(int id) async {
    final detail = cardDetails.firstWhere((d) => d.id == id);
    detail.isOneTime = !detail.isOneTime;
    notifyListeners();
    await ApiService.updateCardIsOneTime(id, isOneTime: detail.isOneTime);
  }

  // ---- Point values (شاشة قيم النقاط) ----
  final PointValues points = defaultPointValues();

  /// Mirrors `adjustPoint(key, delta)` — the same generic +/-0.5 stepper
  /// logic applies to all three boxes, rescue included.
  void adjustPoint(String key, double delta) {
    final rounded = ((points.get(key) + delta) * 10).round() / 10;
    points.set(key, rounded);
    notifyListeners();
  }

  void resetPoints() {
    points.resetToDefaults();
    notifyListeners();
  }
  // ---- Card types & judge categories ----
  List<Map<String, dynamic>> cardTypes = [];
  List<Map<String, dynamic>> judgeCategories = [];

  Future<void> fetchCardTypesAndJudgeCategories() async {
    try {
      final results = await Future.wait([
        ApiService.getCardTypes(),
        ApiService.getJudgeCategories(1),
      ]);
      cardTypes = results[0];
      judgeCategories = results[1];
      notifyListeners();
    } catch (e) {
      debugPrint('fetchCardTypesAndJudgeCategories error: $e');
    }
  }

  // ---- Game management (إدارة اللعبة) ----
Map<String, dynamic> gameInfo = {};
List<Map<String, dynamic>> gameCards = [];
bool isLoadingGame = false;

Future<void> fetchGameInfo({bool force = false}) async {
  if (!force && !_isStale('gameInfo')) return;
  isLoadingGame = true;
  notifyListeners();
  try {
    final results = await Future.wait([
      ApiService.getGame(1),
      ApiService.getGameCards(1),
    ]);
    gameInfo  = Map<String, dynamic>.from(results[0] as Map);
    gameCards = List<Map<String, dynamic>>.from(
      (results[1] as List).map((e) => Map<String, dynamic>.from(e as Map))
    );
    _markFetched('gameInfo');
  } catch (e) {
    debugPrint('fetchGameInfo error: $e');
  }
  isLoadingGame = false;
  notifyListeners();
}

Future<String?> saveGameInfo({
  required String name,
  required String status,
  required int minPlayers,
}) async {
  try {
    final updated = await ApiService.updateGame(
      id: 1,
      name: name,
      status: status,
      minPlayers: minPlayers,
    );
    gameInfo = updated;
    // Keep sidebar name and games list in sync
    if (_selectedPack != null) {
      _selectedPack = GamePack(id: _selectedPack!.id, name: name, codes: _selectedPack!.codes);
    }
    final idx = games.indexWhere((g) => g.id == 1);
    if (idx != -1) {
      games[idx] = Game(
        id: games[idx].id,
        name: name,
        status: status,
        contentVersion: games[idx].contentVersion,
        description: games[idx].description,
      );
    }
    notifyListeners();
    return null;
  } catch (e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}

Future<String?> addGameCard({
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
  try {
    final newCard = await ApiService.addGameCard(
      gameId: 1,
      name: name, score: score, quantity: quantity,
      detailedDesc: detailedDesc, abstractDesc: abstractDesc, emoji: emoji,
      isOneTime: isOneTime, cardTypeId: cardTypeId, judgeCategoriesId: judgeCategoriesId,
    );
    gameCards.add(newCard);
    notifyListeners();
    return null;
  } catch (e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}

Future<String?> updateGameCard({
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
  try {
    final updated = await ApiService.updateGameCard(
      id: id,
      name: name, score: score, quantity: quantity,
      detailedDesc: detailedDesc, abstractDesc: abstractDesc, emoji: emoji,
      isOneTime: isOneTime, cardTypeId: cardTypeId, judgeCategoriesId: judgeCategoriesId,
    );
    final index = gameCards.indexWhere((c) => c['id'] == id);
    if (index != -1) gameCards[index] = updated;
    notifyListeners();
    return null;
  } catch (e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}

Future<void> deleteGameCard(int id) async {
  try {
    await ApiService.deleteGameCard(id);
    gameCards.removeWhere((c) => c['id'] == id);
    notifyListeners();
  } catch (e) {
    debugPrint('deleteGameCard error: $e');
  }
}


// ---- Categories (الكاتيجوريز) ----
List<Map<String, dynamic>> categories = [];
bool isLoadingCategories = false;
String? categoryError;

Future<void> fetchCategories({bool force = false}) async {
  if (!force && !_isStale('categories')) return;
  isLoadingCategories = true;
  notifyListeners();
  try {
    categories = await ApiService.getCategories(1);
    _markFetched('categories');
  } catch (e) {
    debugPrint('fetchCategories error: $e');
  }
  isLoadingCategories = false;
  notifyListeners();
}

Future<String?> addCategory(String name, String emoji) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return null;
  try {
    final newCat = await ApiService.addCategory(
      name: trimmed,
      emoji: emoji.trim().isEmpty ? '📌' : emoji.trim(),
      gameId: 1,
    );
    categories.add(newCat);
    notifyListeners();
    return null;
  } catch (e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}

Future<String?> editCategory(int id, String newName, String newEmoji) async {
  try {
    final updated = await ApiService.updateCategory(
      id: id,
      name: newName,
      emoji: newEmoji,
    );
    final index = categories.indexWhere((c) => c['id'] == id);
    if (index != -1) categories[index] = {...categories[index], ...updated};
    notifyListeners();
    return null;
  } catch (e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}

Future<void> deleteCategory(int id) async {
  try {
    await ApiService.deleteCategory(id);
    categories.removeWhere((c) => c['id'] == id);
    notifyListeners();
  } catch (e) {
    debugPrint('deleteCategory error: $e');
  }
}

Future<void> addSticker(int categoryId, List<int> fileBytes, String fileName, String name) async {
  try {
    final sticker = await ApiService.addSticker(
      categoryId: categoryId,
      fileBytes: fileBytes,
      fileName: fileName,
      stickerName: name,
    );
    final index = categories.indexWhere((c) => c['id'] == categoryId);
    if (index != -1) {
      final stickers = List<Map<String, dynamic>>.from(categories[index]['stickers'] ?? []);
      stickers.add(sticker);
      categories[index] = {...categories[index], 'stickers': stickers};
      notifyListeners();
    }
  } catch (e) {
    debugPrint('addSticker error: $e');
  }
}

Future<void> deleteSticker(int categoryId, int stickerId) async {
  try {
    await ApiService.deleteSticker(stickerId);
    final index = categories.indexWhere((c) => c['id'] == categoryId);
    if (index != -1) {
      final stickers = List<Map<String, dynamic>>.from(categories[index]['stickers'] ?? [])
        ..removeWhere((s) => s['id'] == stickerId);
      categories[index] = {...categories[index], 'stickers': stickers};
      notifyListeners();
    }
  } catch (e) {
    debugPrint('deleteSticker error: $e');
  }
}

  // ---- Rescue tasks (أحكام الإنقاذ) ----
// ---- Rescue tasks (أحكام الإنقاذ) ----
List<Map<String, dynamic>> rescueTasks = [];
bool isLoadingRescue = false;
String? rescueTaskError;


Future<void> fetchRescueTasks({bool force = false}) async {
  if (!force && !_isStale('rescue')) return;
  isLoadingRescue = true;
  notifyListeners();
  try {
    rescueTasks = await ApiService.getJudges(1, 'enkaz');
    _markFetched('rescue');
  } catch (e) {
    debugPrint('fetchRescueTasks error: $e');
  }
  isLoadingRescue = false;
  notifyListeners();
}


Future<String?> addRescueTask(String text) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  try {
    final newTask = await ApiService.addJudge(
      judgeCategoriesId: 1,
      description: trimmed,
    );
    rescueTasks.add(newTask);
    notifyListeners();
    return null;
  } catch (e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}

Future<String?> editRescueTask(int index, String newText) async {
  final trimmed = newText.trim();
  if (trimmed.isEmpty) return null;
  final id = rescueTasks[index]['id'];
  try {
    final updated = await ApiService.updateJudge(
      id: id,
      description: trimmed,
      status: rescueTasks[index]['status'] ?? 'on',
    );
    rescueTasks[index] = updated;
    notifyListeners();
    return null;
  } catch (e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}

Future<void> deleteRescueTask(int index) async {
  final id = rescueTasks[index]['id'];
  try {
    await ApiService.deleteJudge(id);
    rescueTasks.removeAt(index);
    notifyListeners();
  } catch (e) {
    debugPrint('deleteRescueTask error: $e');
  }
}
Future<void> toggleRescueTaskStatus(int index) async {
  final task = rescueTasks[index];
  final newStatus = task['status'] == 'on' ? 'off' : 'on';
  try {
    final updated = await ApiService.updateJudge(
      id: task['id'],
      description: task['description'],
      status: newStatus,
    );
    rescueTasks[index] = updated;
    notifyListeners();
  } catch (e) {
    debugPrint('toggleRescueTaskStatus error: $e');
  }
}

// ---- Gift lines (مكافآت الفائز) ----
List<Map<String, dynamic>> giftLines = [];
bool isLoadingGifts = false;
String? giftLineError;

Future<void> fetchGiftLines({bool force = false}) async {
  if (!force && !_isStale('gifts')) return;
  isLoadingGifts = true;
  notifyListeners();
  try {
    giftLines = await ApiService.getRewards(1);
    _markFetched('gifts');
  } catch (e) {
    debugPrint('fetchGiftLines error: $e');
  }
  isLoadingGifts = false;
  notifyListeners();
}

Future<String?> addGiftLine(String text) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  try {
    final newGift = await ApiService.addReward(description: trimmed);
    giftLines.add(newGift);
    notifyListeners();
    return null;
  } catch (e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}

Future<String?> editGiftLine(int index, String newText) async {
  final trimmed = newText.trim();
  if (trimmed.isEmpty) return null;
  final id = giftLines[index]['id'];
  try {
    final updated = await ApiService.updateJudge(
      id: id,
      description: trimmed,
      status: giftLines[index]['status'] ?? 'on',
    );
    giftLines[index] = updated;
    notifyListeners();
    return null;
  } catch (e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}

Future<void> deleteGiftLine(int index) async {
  final id = giftLines[index]['id'];
  try {
    await ApiService.deleteJudge(id);
    giftLines.removeAt(index);
    notifyListeners();
  } catch (e) {
    debugPrint('deleteGiftLine error: $e');
  }
}

Future<void> toggleGiftStatus(int index) async {
  final gift = giftLines[index];
  final newStatus = gift['status'] == 'on' ? 'off' : 'on';
  try {
    final updated = await ApiService.updateJudge(
      id: gift['id'],
      description: gift['description'],
      status: newStatus,
    );
    giftLines[index] = updated;
    notifyListeners();
  } catch (e) {
    debugPrint('toggleGiftStatus error: $e');
  }
}

  // ---- Codes (إدارة الكودات) — scoped to the currently open pack ----
  List<CodeModel> codes = [];
  bool isLoadingCodes = false;
  String? codesError;
  CodeFilter codeFilter = CodeFilter.all;

  int get totalCodes   => codes.length;
  int get unusedCodes  => codes.where((c) => c.status == 'unused').length;
  int get usedCodes    => codes.where((c) => c.status == 'used').length;
  int get expiredCodes => codes.where((c) => c.status == 'expired').length;

  void setCodeFilter(CodeFilter f) {
    codeFilter = f;
    notifyListeners();
  }

  List<CodeModel> filteredCodes() {
    if (codeFilter == CodeFilter.all) return codes;
    final key = switch (codeFilter) {
      CodeFilter.unused  => 'unused',
      CodeFilter.used    => 'used',
      CodeFilter.expired => 'expired',
      CodeFilter.all     => '',
    };
    return codes.where((c) => c.status == key).toList();
  }

  Future<void> fetchCodes(int gameId, {bool force = false}) async {
    if (!force && !_isStale('codes')) return;
    isLoadingCodes = true;
    codesError = null;
    notifyListeners();
    try {
      codes = await ApiService.getCodes(gameId);
      _markFetched('codes');
    } catch (e) {
      codesError = e.toString();
    } finally {
      isLoadingCodes = false;
      notifyListeners();
    }
  }

  Future<int> generateCodes({
    required int count,
    required int length,
    required bool numericOnly,
  }) async {
    final gameId = int.parse(_selectedPack!.id);
    final generated = await ApiService.generateCodes(
      gameId: gameId, count: count, length: length, numericOnly: numericOnly,
    );
    codes = [...generated, ...codes];
    notifyListeners();
    return generated.length;
  }

  Future<void> addManualCode(String rawCode) async {
    final gameId = int.parse(_selectedPack!.id);
    final newCode = await ApiService.insertCode(gameId: gameId, code: rawCode);
    codes = [newCode, ...codes];
    notifyListeners();
  }

  Future<void> markCodeUsed(int id) async {
    await ApiService.updateCode(id, used: true);
    final idx = codes.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      codes = List.of(codes)..[idx] = codes[idx].copyWith(used: true, usedBy: 'يدوي');
      notifyListeners();
    }
  }

  Future<void> markCodeUnused(int id) async {
    await ApiService.updateCode(id, used: false);
    final idx = codes.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      codes = List.of(codes)..[idx] = codes[idx].copyWith(used: false, usedBy: '');
      notifyListeners();
    }
  }

  Future<void> deleteCode(int id) async {
    await ApiService.deleteCode(id);
    codes = codes.where((c) => c.id != id).toList();
    notifyListeners();
  }

  Future<void> setCodeExpiry(int id, DateTime? expiry) async {
    await ApiService.updateCode(id,
        endDate: expiry, clearEndDate: expiry == null);
    final idx = codes.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      codes = List.of(codes)
        ..[idx] = codes[idx].copyWith(
            newExpiry: expiry, clearExpiry: expiry == null);
      notifyListeners();
    }
  }

  Future<int> deleteUsedCodes() async {
    final gameId = int.parse(_selectedPack!.id);
    final deleted = await ApiService.deleteUsedCodes(gameId);
    codes = codes.where((c) => !c.used).toList();
    notifyListeners();
    return deleted;
  }
}
