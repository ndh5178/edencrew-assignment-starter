import 'package:flutter/foundation.dart';

import '../../data/favorite_storage.dart';

enum FavoriteStatus {
  initial,
  loading,
  ready,
  failure,
}

enum FavoriteChange {
  added,
  removed,
}

class FavoriteController extends ChangeNotifier {
  FavoriteController({required FavoriteStorage storage}) : _storage = storage;

  final FavoriteStorage _storage;
  final Set<String> _favoriteSymbols = <String>{};
  final Set<String> _updatingSymbols = <String>{};

  FavoriteStatus _status = FavoriteStatus.initial;
  bool _isDisposed = false;

  FavoriteStatus get status {
    return _status;
  }

  Set<String> get favoriteSymbols {
    return Set<String>.unmodifiable(_favoriteSymbols);
  }

  bool isFavorite(String symbol) {
    return _favoriteSymbols.contains(symbol);
  }

  bool isUpdating(String symbol) {
    return _updatingSymbols.contains(symbol);
  }

  Future<void> initialize() async {
    _status = FavoriteStatus.loading;
    notifyListeners();

    try {
      final List<String> storedSymbols = await _storage.loadFavoriteSymbols();

      if (_isDisposed) {
        return;
      }

      _favoriteSymbols
        ..clear()
        ..addAll(storedSymbols);
      _status = FavoriteStatus.ready;
    } on Object {
      if (_isDisposed) {
        return;
      }

      _favoriteSymbols.clear();
      _status = FavoriteStatus.failure;
    }

    notifyListeners();
  }

  Future<FavoriteChange?> toggleFavorite(String symbol) async {
    if (_isDisposed || _updatingSymbols.contains(symbol)) {
      return null;
    }

    _updatingSymbols.add(symbol);
    final bool wasFavorite = _favoriteSymbols.contains(symbol);
    final FavoriteChange change;

    if (wasFavorite) {
      _favoriteSymbols.remove(symbol);
      change = FavoriteChange.removed;
    } else {
      _favoriteSymbols.add(symbol);
      change = FavoriteChange.added;
    }

    notifyListeners();

    try {
      await _storage.saveFavoriteSymbols(_favoriteSymbols);
      return change;
    } on Object {
      if (wasFavorite) {
        _favoriteSymbols.add(symbol);
      } else {
        _favoriteSymbols.remove(symbol);
      }

      rethrow;
    } finally {
      _updatingSymbols.remove(symbol);
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
