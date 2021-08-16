import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/store/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class ServiceAssets {
  ServiceAssets(this.plugin, this.keyring) : store = plugin.store;

  final PluginStatemine plugin;
  final Keyring keyring;

  final PluginStore store;

  Future<void> getAllAssets() async {
    final res = await plugin.sdk.api.assets.getAssetsAll();
    store.assets.setAllAssets(res);
  }

  Future<void> getAssetsDetail(String id) async {
    final res =
        await plugin.sdk.webView.evalJavascript('api.query.assets.asset($id)');
    store.assets.setAssetsDetails({id: res});

    if (res != null) {
      final addresses = [
        res['owner'],
        res['issuer'],
        res['admin'],
        res['freezer']
      ];
      plugin.service.account.updateIconsAndIndices(addresses.toSet().toList());
    }
  }
}
