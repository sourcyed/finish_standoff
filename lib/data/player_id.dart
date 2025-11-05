import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PlayerIdService {
  static const _key = "player_id";
  static final _uuid = Uuid();

  static Future<String> getPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_key);

    if (id == null) {
      id = _uuid.v4().replaceAll(RegExp(r'[^a-zA-Z0-9]'), 'replace');
      await prefs.setString(_key, id);
    }

    return id;
  }
}
