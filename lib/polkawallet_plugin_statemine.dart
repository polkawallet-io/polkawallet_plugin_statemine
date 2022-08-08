library polkawallet_plugin_statemine;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_statemine/common/constants.dart';
import 'package:polkawallet_plugin_statemine/pages/assetBalancePage.dart';
import 'package:polkawallet_plugin_statemine/pages/assetDetailPage.dart';
import 'package:polkawallet_plugin_statemine/pages/assetsListPage.dart';
import 'package:polkawallet_plugin_statemine/pages/defi/karuraEntryPage.dart';
import 'package:polkawallet_plugin_statemine/pages/metaHub.dart';
import 'package:polkawallet_plugin_statemine/pages/public/bannerRMRKPage.dart';
import 'package:polkawallet_plugin_statemine/pages/transferPage.dart';
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
      : tokenIcons = name == 'statemine'
            ? {
                'KSM': Image.asset(
                    'packages/polkawallet_plugin_statemine/assets/images/tokens/KSM.png'),
                '8': Image.asset(
                    'packages/polkawallet_plugin_statemine/assets/images/tokens/RMRK.png'),
                '16': Image.asset(
                    'packages/polkawallet_plugin_statemine/assets/images/tokens/ARIS.png'),
              }
            : {
                'DOT': Image.asset(
                    'packages/polkawallet_plugin_statemine/assets/images/tokens/DOT.png'),
              },
        basic = PluginBasicData(
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
          jsCodeVersion: 22201,
          isTestNet: false,
          isXCMSupport: true,
          parachainId: '1000',
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
  Map<String, Widget> tokenIcons;

  @override
  List<TokenBalanceData> get noneNativeTokensAll {
    return store?.assets?.tokenBalanceMap?.values?.toList();
  }

  @override
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) {
    return [
      HomeNavItem(
        text: basic.name.toUpperCase(),
        icon: Container(),
        iconActive: Container(),
        isAdapter: true,
        content: MetaHubPanel(this),
      ),
    ];
  }

  @override
  Map<String, WidgetBuilder> getRoutes(Keyring keyring) {
    return {
      TxConfirmPage.route: (_) =>
          TxConfirmPage(this, keyring, _service.getPassword),

      // assets pages
      AssetsListPage.route: (_) => AssetsListPage(this),
      AssetDetailPage.route: (_) => AssetDetailPage(this),
      AssetBalancePage.route: (_) => AssetBalancePage(this, keyring),
      TransferPage.route: (_) => TransferPage(this, keyring),

      // banners
      BannerRMRKPage.route: (_) => BannerRMRKPage(this),

      // defi entry
      KaruraEntryPage.route: (_) => KaruraEntryPage(this),
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

    await service.assets.getAllAssets();

    final all = store.assets.assetsAll.toList();
    all.removeWhere(
        (element) => element.symbol == (networkState.tokenSymbol ?? [''])[0]);
    final res = await sdk.api.assets
        .queryAssetsBalances(all.map((e) => e.id).toList(), acc.address);
    final assetsBalances = all
        .asMap()
        .map((k, v) {
          v.amount = res[k].balance;
          v.detailPageRoute = AssetBalancePage.route;
          v.getPrice = () {
            final tokenPrice = _store.assets.marketPrices[v.symbol];
            return (tokenPrice ?? 0) > 0
                ? tokenPrice *
                    Fmt.bigIntToDouble(
                        Fmt.balanceInt(v.amount ?? '0'), v.decimals)
                : 0;
          };
          return MapEntry(k, v);
        })
        .values
        .toList();
    store.assets.setTokenBalanceMap(assetsBalances, acc.pubKey);

    assetsBalances.retainWhere(
        (e) => Fmt.balanceInt(e.amount) > BigInt.zero || e.symbol == 'RMRK');

    _service.assets
        .queryMarketPrices(assetsBalances.map((e) => e.symbol).toList());
    balances.setTokens(assetsBalances);

    Future.wait(
        assetsBalances.map((e) => service.assets.getAssetsDetail(e.id)));
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

    _service.fetchRemoteConfig();
    _service.assets.queryIconsSrc();
  }

  @override
  Future<void> onStarted(Keyring keyring) async {
    await _service.assets.getAllAssets();

    updateBalances(keyring.current);
  }

  @override
  Future<void> onAccountChanged(KeyPairData acc) async {
    balances.setTokens([]);

    _store.assets.loadCache(acc.pubKey);

    updateBalances(acc);
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
