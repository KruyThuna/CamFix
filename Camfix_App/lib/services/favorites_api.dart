import '../models/favorite.dart';
import 'api_client.dart';

/// The signed-in customer's saved technicians (`/api/favorites/**`).
class FavoritesApi {
  FavoritesApi._();
  static final FavoritesApi instance = FavoritesApi._();

  final _client = ApiClient.instance;

  /// Local cache of favorited technician ids, so a heart icon can render
  /// instantly without an extra round trip on every provider card.
  final Set<int> _favoritedIds = {};
  bool _loaded = false;

  Future<List<Favorite>> list() async {
    final raw = await _client.getJsonList('/api/favorites/mine');
    final favorites =
        raw.whereType<Map<String, dynamic>>().map(Favorite.fromJson).toList();
    _favoritedIds
      ..clear()
      ..addAll(favorites.map((f) => f.technicianId));
    _loaded = true;
    return favorites;
  }

  bool isFavorite(int technicianId) => _favoritedIds.contains(technicianId);

  bool get isLoaded => _loaded;

  /// Server-checked favorite status for one technician (used where fetching
  /// the whole list first would be overkill, e.g. a single tracking screen).
  Future<bool> check(int technicianId) async {
    final json = await _client.getJson('/api/favorites/$technicianId/check');
    final fav = json['isFavorite'] == true;
    if (fav) {
      _favoritedIds.add(technicianId);
    } else {
      _favoritedIds.remove(technicianId);
    }
    return fav;
  }

  Future<Favorite> add(int technicianId) async {
    final json = await _client.postJson(
        '/api/favorites', {'technicianId': technicianId},
        withAuth: true);
    _favoritedIds.add(technicianId);
    return Favorite.fromJson(json);
  }

  Future<void> remove(int technicianId) async {
    await _client.deleteJson('/api/favorites/$technicianId');
    _favoritedIds.remove(technicianId);
  }
}
