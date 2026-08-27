import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/bank_card.dart';
import '../../domain/entities/money.dart';

/// The cache. Stores entities, not DTOs.
///
/// Storing the *domain* shape means a backend field rename never triggers a
/// database migration — the DTO absorbs the change and the cached rows stay
/// valid. The opposite choice (cache the raw JSON) is faster to write and
/// costs a migration every time the API moves.
abstract interface class CardLocalDataSource {
  Future<List<BankCard>> readCards();
  Future<BankCard?> readCard(String id);

  /// Replaces the whole set atomically.
  Future<void> replaceAll(List<BankCard> cards);
}

@LazySingleton(as: CardLocalDataSource)
class CardLocalDataSourceImpl implements CardLocalDataSource {
  const CardLocalDataSourceImpl(this._database);

  final AppDatabase _database;

  static const _table = 'cards';

  @override
  Future<List<BankCard>> readCards() async {
    try {
      final db = await _database.database;
      final rows = await db.query(_table, orderBy: 'cached_at DESC');
      return rows.map(_toEntity).toList(growable: false);
    } on DatabaseException catch (e) {
      throw CacheException('Failed to read cards: $e');
    }
  }

  @override
  Future<BankCard?> readCard(String id) async {
    try {
      final db = await _database.database;
      final rows = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : _toEntity(rows.first);
    } on DatabaseException catch (e) {
      throw CacheException('Failed to read card $id: $e');
    }
  }

  @override
  Future<void> replaceAll(List<BankCard> cards) async {
    try {
      final db = await _database.database;
      // One transaction, one batch. Two reasons:
      //  - atomicity: a crash mid-write cannot leave a half-updated card list;
      //  - speed: sqflite otherwise pays a round trip per statement, which is
      //    visible once the list is more than a handful of rows.
      await db.transaction((txn) async {
        final batch = txn.batch()..delete(_table);
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final card in cards) {
          batch.insert(
            _table,
            _toRow(card, cachedAt: now),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } on DatabaseException catch (e) {
      throw CacheException('Failed to write cards: $e');
    }
  }

  Map<String, Object?> _toRow(BankCard card, {required int cachedAt}) => {
        'id': card.id,
        'display_name': card.displayName,
        'last_digits': card.lastDigits,
        'expiry': card.expiry,
        'payment_network': card.paymentNetwork,
        'state': card.state.name,
        'balance_minor': card.balance.minorUnits,
        'currency': card.balance.currency,
        'cached_at': cachedAt,
      };

  BankCard _toEntity(Map<String, Object?> row) => BankCard(
        id: row['id']! as String,
        displayName: row['display_name']! as String,
        lastDigits: row['last_digits']! as String,
        expiry: row['expiry']! as String,
        paymentNetwork: row['payment_network']! as String,
        // A row written by an older build may hold a state this build does not
        // know; falling back keeps the cache readable across app updates.
        state: CardState.values.firstWhere(
          (s) => s.name == row['state'],
          orElse: () => CardState.inactive,
        ),
        balance: Money(
          minorUnits: row['balance_minor']! as int,
          currency: row['currency']! as String,
        ),
      );
}
