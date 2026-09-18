import 'package:shared_preferences/shared_preferences.dart';

abstract interface class FavoriteStorage {
  Future<List<String>> loadFavoriteSymbols();

  Future<void> saveFavoriteSymbols(Iterable<String> symbols);
}

class SharedPreferencesFavoriteStorage implements FavoriteStorage {
  SharedPreferencesFavoriteStorage({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _favoriteSymbolsKey = 'favorite_symbols';

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<String>> loadFavoriteSymbols() async {
    final List<String> storedSymbols =
        await _preferences.getStringList(_favoriteSymbolsKey) ?? <String>[];
    final RegExp sixDigitSymbol = RegExp(r'^\d{6}$');
    final Set<String> uniqueSymbols = <String>{};

    for (final String symbol in storedSymbols) {
      if (sixDigitSymbol.hasMatch(symbol)) {
        uniqueSymbols.add(symbol);
      }
    }

    return uniqueSymbols.toList()..sort();
  }

  @override
  Future<void> saveFavoriteSymbols(Iterable<String> symbols) async {
    final List<String> symbolsToSave = symbols.toSet().toList()..sort();

    await _preferences.setStringList(_favoriteSymbolsKey, symbolsToSave);
  }
}
