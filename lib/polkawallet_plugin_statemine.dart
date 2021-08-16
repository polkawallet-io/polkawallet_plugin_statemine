library polkawallet_plugin_statemine;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_statemine/common/constants.dart';
import 'package:polkawallet_plugin_statemine/pages/assetDetailPage.dart';
import 'package:polkawallet_plugin_statemine/pages/assetsList.dart';
import 'package:polkawallet_plugin_statemine/service/index.dart';
import 'package:polkawallet_plugin_statemine/store/cache/storeCache.dart';
import 'package:polkawallet_plugin_statemine/store/index.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class PluginStatemine extends PolkawalletPlugin {
  /// the kusama plugin support two networks: kusama & polkadot,
  /// so we need to identify the active network to connect & display UI.
  PluginStatemine({name = 'statemine'})
      : basic = PluginBasicData(
          name: name,
          genesisHash: plugin_genesis_hash[name],
          ss58: plugin_ss58_format[name],
          primaryColor: plugin_primary_color[name],
          gradientColor: plugin_gradient_color[name],
          backgroundImage: AssetImage(
              'packages/polkawallet_plugin_statemine/assets/images/bg_$name.png'),
          icon: Image.asset(
              'packages/polkawallet_plugin_statemine/assets/images/statemine.png'),
          iconDisabled: Image.asset(
              'packages/polkawallet_plugin_statemine/assets/images/statemine_grey.png'),
          jsCodeVersion: 21401,
          isTestNet: false,
          isXCMSupport: true,
        ),
        recoveryEnabled = false,
        _cache =
            name == network_name_statemine ? StoreCacheKSM() : StoreCache();

  @override
  final PluginBasicData basic;

  @override
  final bool recoveryEnabled;

  @override
  List<NetworkParams> get nodeList {
    return _randomList(plugin_node_list[basic.name])
        .map((e) => NetworkParams.fromJson(e))
        .toList();
  }

  @override
  final Map<String, Widget> tokenIcons = {
    'KSM': Image.asset(
        'packages/polkawallet_plugin_statemine/assets/images/tokens/KSM.png'),
    'DOT': Image.asset(
        'packages/polkawallet_plugin_statemine/assets/images/tokens/DOT.png'),
  };

  @override
  List<TokenBalanceData> get noneNativeTokensAll {
    return store?.assets?.assetsAll?.toList();
  }

  @override
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) {
    return [
      HomeNavItem(
        text: basic.name[0].toUpperCase() + basic.name.substring(1),
        icon: Image.asset(
            'packages/polkawallet_plugin_statemine/assets/images/statemine_grey.png'),
        iconActive: Image.asset(
            'packages/polkawallet_plugin_statemine/assets/images/statemine.png'),
        content: AssetsList(this),
      )
    ];
  }

  @override
  Map<String, WidgetBuilder> getRoutes(Keyring keyring) {
    return {
      TxConfirmPage.route: (_) =>
          TxConfirmPage(this, keyring, _service.getPassword),

      // assets pages
      AssetDetailPage.route: (_) => AssetDetailPage(this),
    };
  }

  @override
  Future<String> loadJSCode() => null;

  PluginStore _store;
  PluginService _service;
  PluginStore get store => _store;
  PluginService get service => _service;

  final StoreCache _cache;

  @override
  Future<void> updateBalances(KeyPairData acc) async {
    super.updateBalances(acc);

    final all = store.assets.assetsAll.toList();
    final res = await sdk.api.assets
        .queryAssetsBalances(all.map((e) => e.id).toList(), acc.address);
    final assetsBalances = all
        .asMap()
        .map((k, v) {
          v.amount = res[k].balance;
          return MapEntry(k, v);
        })
        .values
        .toList();
    store.assets.setTokenBalanceMap(assetsBalances, acc.pubKey);

    assetsBalances.retainWhere((e) => Fmt.balanceInt(e.amount) > BigInt.zero);
    balances.setTokens(assetsBalances);
  }

  @override
  Future<void> onWillStart(Keyring keyring) async {
    await GetStorage.init(plugin_cache_key[basic.name]);

    _store = PluginStore(_cache);

    try {
      loadBalances(keyring.current);

      _store.assets.loadCache(keyring.current.pubKey);
      print('${basic.name} plugin cache data loaded');
    } catch (err) {
      print(err);
      print('load ${basic.name} cache data failed');
    }

    _service = PluginService(this, keyring);
  }

  @override
  Future<void> onStarted(Keyring keyring) async {
    await _service.assets.getAllAssets();

    updateBalances(keyring.current);
  }

  @override
  Future<void> onAccountChanged(KeyPairData acc) async {
    _store.assets.loadCache(acc.pubKey);
  }

  List _randomList(List input) {
    final data = input.toList();
    final res = [];
    final _random = Random();
    for (var i = 0; i < input.length; i++) {
      final item = data[_random.nextInt(data.length)];
      res.add(item);
      data.remove(item);
    }
    return res;
  }
}
