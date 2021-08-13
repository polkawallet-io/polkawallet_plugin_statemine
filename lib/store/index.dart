import 'package:polkawallet_plugin_statemine/store/accounts.dart';
import 'package:polkawallet_plugin_statemine/store/assets.dart';
import 'package:polkawallet_plugin_statemine/store/cache/storeCache.dart';

class PluginStore {
  PluginStore(StoreCache cache) : assets = AssetsStore(cache);
  final AssetsStore assets;
  final AccountsStore accounts = AccountsStore();
}
