import 'package:edencrew_assignment_starter/data/favorite_storage.dart';
import 'package:edencrew_assignment_starter/features/favorites/favorite_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('저장된 관심 종목을 초기 상태로 불러온다', () async {
    final _MemoryFavoriteStorage storage = _MemoryFavoriteStorage(
      initialSymbols: <String>{'005930', '000660'},
    );
    final FavoriteController controller = FavoriteController(storage: storage);

    await controller.initialize();

    expect(controller.status, FavoriteStatus.ready);
    expect(controller.isFavorite('005930'), isTrue);
    expect(controller.isFavorite('000660'), isTrue);

    controller.dispose();
  });

  test('관심 종목을 등록하고 다시 누르면 해제한다', () async {
    final _MemoryFavoriteStorage storage = _MemoryFavoriteStorage();
    final FavoriteController controller = FavoriteController(storage: storage);
    await controller.initialize();

    final FavoriteChange? added = await controller.toggleFavorite('005930');

    expect(added, FavoriteChange.added);
    expect(controller.isFavorite('005930'), isTrue);
    expect(storage.symbols, contains('005930'));

    final FavoriteChange? removed = await controller.toggleFavorite('005930');

    expect(removed, FavoriteChange.removed);
    expect(controller.isFavorite('005930'), isFalse);
    expect(storage.symbols, isNot(contains('005930')));

    controller.dispose();
  });

  test('로컬 저장에 실패하면 관심 상태를 이전 값으로 되돌린다', () async {
    final _FailingFavoriteStorage storage = _FailingFavoriteStorage();
    final FavoriteController controller = FavoriteController(storage: storage);
    await controller.initialize();

    await expectLater(
      controller.toggleFavorite('005930'),
      throwsA(isA<StateError>()),
    );

    expect(controller.isFavorite('005930'), isFalse);

    controller.dispose();
  });
}

class _MemoryFavoriteStorage implements FavoriteStorage {
  _MemoryFavoriteStorage({Set<String>? initialSymbols})
      : symbols = initialSymbols ?? <String>{};

  final Set<String> symbols;

  @override
  Future<List<String>> loadFavoriteSymbols() async {
    return symbols.toList();
  }

  @override
  Future<void> saveFavoriteSymbols(Iterable<String> newSymbols) async {
    symbols
      ..clear()
      ..addAll(newSymbols);
  }
}

class _FailingFavoriteStorage implements FavoriteStorage {
  @override
  Future<List<String>> loadFavoriteSymbols() async {
    return <String>[];
  }

  @override
  Future<void> saveFavoriteSymbols(Iterable<String> symbols) async {
    throw StateError('저장 실패');
  }
}
