import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_statemine/common/constants.dart';

class StoreCache {
  static final _storage =
      () => GetStorage(plugin_cache_key[network_name_statemint]);

  final tokens = {}.val('tokens', getBox: _storage);
}

class StoreCacheKSM extends StoreCache {
  static final _storage =
      () => GetStorage(plugin_cache_key[network_name_statemine]);

  final tokens = {}.val('tokens', getBox: _storage);
}
