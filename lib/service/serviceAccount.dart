import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/store/index.dart';
import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class ServiceAccount {
  ServiceAccount(this.plugin, this.keyring)
      : api = plugin.sdk.api,
        store = plugin.store;

  final PluginStatemine plugin;
  final Keyring keyring;
  final PolkawalletApi api;
  final PluginStore store;

  Future<void> updateIconsAndIndices(List addresses) async {
    final ls = addresses.toList();
    ls.removeWhere((e) => store.accounts.addressIconsMap.keys.contains(e));

    final List<List> res = await Future.wait([
      api.account.getAddressIcons(ls),
      api.account.queryIndexInfo(ls),
    ]);
    store.accounts.setAddressIconsMap(res[0]);
    store.accounts.setAddressIndex(res[1]);
  }
}
