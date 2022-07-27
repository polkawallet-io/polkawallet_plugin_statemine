import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/service/serviceAccount.dart';
import 'package:polkawallet_plugin_statemine/service/serviceAssets.dart';
import 'package:polkawallet_plugin_statemine/service/walletApi.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/passwordInputDialog.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class PluginService {
  PluginService(PluginStatemine plugin, Keyring keyring)
      : account = ServiceAccount(plugin, keyring),
        assets = ServiceAssets(plugin, keyring),
        plugin = plugin;

  final ServiceAccount account;
  final ServiceAssets assets;

  final PluginStatemine plugin;

  bool connected = false;

  Future<String> getPassword(BuildContext context, KeyPairData acc) async {
    final password = await showCupertinoDialog(
      context: context,
      builder: (_) {
        return PasswordInputDialog(
          plugin.sdk.api,
          title: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['unlock']),
          account: acc,
        );
      },
    );
    return password;
  }

  Future<void> fetchRemoteConfig() async {
    final res = await WalletApi.getRemoteConfig(plugin.basic.name);
    if (res != null) {
      plugin.store.settings.setRemoteConfig(res);

      if ((res['tokens'] ?? {})['icons'] != null) {
        final icons = Map.of((res['tokens'] ?? {})['icons']);
        icons.removeWhere(
            (key, value) => plugin.tokenIcons.keys.toList().indexOf(key) > -1);
        plugin.tokenIcons.addAll(icons.map((k, v) {
          return MapEntry(
              k,
              (v as String).contains('.svg')
                  ? SvgPicture.network(v)
                  : Image.network(v));
        }));
      }
    }
  }
}
