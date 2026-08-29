// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/cards/data/datasources/card_local_data_source.dart'
    as _i890;
import '../../features/cards/data/datasources/card_remote_data_source.dart'
    as _i755;
import '../../features/cards/data/datasources/fake_card_remote_data_source.dart'
    as _i728;
import '../../features/cards/data/repositories/card_repository_impl.dart'
    as _i96;
import '../../features/cards/domain/repositories/card_repository.dart' as _i34;
import '../../features/cards/domain/usecases/watch_cards.dart' as _i226;
import '../../features/wallet/data/wallet_provisioning_repository.dart'
    as _i1023;
import '../database/app_database.dart' as _i982;
import '../native/idemia_card_api.g.dart' as _i959;
import '../native/secure_card_display_api.g.dart' as _i337;
import '../network/api_client.dart' as _i557;
import '../network/token_storage.dart' as _i964;
import 'register_module.dart' as _i291;

const String _dev = 'dev';
const String _prod = 'prod';
const String _test = 'test';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i982.AppDatabase>(() => registerModule.database);
    gh.lazySingleton<_i964.TokenStorage>(() => registerModule.tokenStorage);
    gh.lazySingleton<_i959.IdemiaCardHostApi>(
      () => registerModule.idemiaCardHostApi(),
    );
    gh.lazySingleton<_i337.SecureCardDisplayHostApi>(
      () => registerModule.secureCardDisplayHostApi(),
    );
    gh.factory<String>(
      () => registerModule.devBaseUrl,
      instanceName: 'baseUrl',
      registerFor: {_dev},
    );
    gh.lazySingleton<_i755.CardRemoteDataSource>(
      () => _i728.FakeCardRemoteDataSource(),
      registerFor: {_dev},
    );
    gh.lazySingleton<_i890.CardLocalDataSource>(
      () => _i890.CardLocalDataSourceImpl(gh<_i982.AppDatabase>()),
    );
    gh.factory<String>(
      () => registerModule.prodBaseUrl,
      instanceName: 'baseUrl',
      registerFor: {_prod},
    );
    gh.lazySingleton<_i1023.WalletProvisioningRepository>(
      () => _i1023.WalletProvisioningRepositoryImpl(
        gh<_i959.IdemiaCardHostApi>(),
      ),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.dio(
        gh<String>(instanceName: 'baseUrl'),
        gh<_i964.TokenStorage>(),
      ),
    );
    gh.lazySingleton<_i557.ApiClient>(
      () => registerModule.apiClient(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i755.CardRemoteDataSource>(
      () => _i755.CardRemoteDataSourceImpl(gh<_i557.ApiClient>()),
      registerFor: {_prod, _test},
    );
    gh.lazySingleton<_i34.CardRepository>(
      () => _i96.CardRepositoryImpl(
        remote: gh<_i755.CardRemoteDataSource>(),
        local: gh<_i890.CardLocalDataSource>(),
      ),
    );
    gh.factory<_i226.WatchCards>(
      () => _i226.WatchCards(gh<_i34.CardRepository>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
