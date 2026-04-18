import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MlHistoryEntry {
  final String type;
  final String input;
  final String result;
  final DateTime timestamp;

  MlHistoryEntry({
    required this.type,
    required this.input,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'input': input,
        'result': result,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MlHistoryEntry.fromJson(Map<String, dynamic> json) => MlHistoryEntry(
        type: json['type'] as String,
        input: json['input'] as String,
        result: json['result'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class MlHistoryService {
  static const _key = 'ml_history';

  static Future<void> save(MlHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load();
    list.insert(0, entry);
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<List<MlHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => MlHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
