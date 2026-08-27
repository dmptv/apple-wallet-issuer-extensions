import 'package:injectable/injectable.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/card_dto.dart';

/// Talks to the backend. Knows about endpoints and JSON; knows nothing about
/// caching, entities, or what the UI intends to do with the result.
abstract interface class CardRemoteDataSource {
  Future<List<CardDto>> fetchCards();
}

/// Bound in every environment except [Env.dev], where
/// [FakeCardRemoteDataSource] takes over instead — see that file for why the
/// split is environment-scoped rather than an `if (kDebugMode)` branch here.
@LazySingleton(as: CardRemoteDataSource, env: [Env.prod, Env.test])
class CardRemoteDataSourceImpl implements CardRemoteDataSource {
  const CardRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<CardDto>> fetchCards() async {
    final raw = await _client.getList('/cards');
    try {
      return raw.map(CardDto.fromJson).toList(growable: false);
    } on Object catch (e) {
      // json_serializable throws TypeError / CastError on a shape mismatch,
      // which would otherwise surface as an opaque crash far from the cause.
      throw ParseException('Malformed card in /cards response: $e');
    }
  }
}
