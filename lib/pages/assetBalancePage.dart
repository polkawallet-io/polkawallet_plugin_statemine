import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_statemine/pages/transferPage.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/borderedTitle.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/components/v3/button.dart';

class AssetBalancePage extends StatefulWidget {
  AssetBalancePage(this.plugin, this.keyring);
  final PluginStatemine plugin;
  final Keyring keyring;

  static final String route = '/asset/balance/detail';

  @override
  _AssetBalancePageSate createState() => _AssetBalancePageSate();
}

class _AssetBalancePageSate extends State<AssetBalancePage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final colorIn = Color(0xFF62CFE4);
  final colorOut = Color(0xFF3394FF);

  Future<void> _updateData() async {
    widget.plugin.updateBalances(widget.keyring.current);

    final TokenBalanceData asset = ModalRoute.of(context).settings.arguments;
    widget.plugin.service.assets.queryMarketPrices([asset.symbol]);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateData();

      final TokenBalanceData asset = ModalRoute.of(context).settings.arguments;
      if (widget.plugin.store.assets.assetsDetails[asset.id] == null) {
        widget.plugin.service.assets.getAssetsDetail(asset.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'common');

    final TokenBalanceData token = ModalRoute.of(context).settings.arguments;
    final btnTextColor = Color(0xFF242528);

    final labelStyle = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(fontWeight: FontWeight.w600);

    final valueStyle = Theme.of(context).textTheme.headline4;

    return Scaffold(
      appBar: AppBar(
        title: Text(token.symbol),
        centerTitle: true,
        elevation: 0.0,
        leading: BackBtn(),
      ),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final balance =
                widget.plugin.store.assets.tokenBalanceMap[token.id];
            final free = Fmt.balanceInt(balance?.amount ?? '0');

            final tokenPrice =
                widget.plugin.store.assets.marketPrices[token.symbol];
            final tokenValue = (tokenPrice ?? 0) > 0
                ? tokenPrice * Fmt.bigIntToDouble(free, balance.decimals)
                : 0;

            final detail = widget.plugin.store.assets.assetsDetails[token.id];
            return RefreshIndicator(
              color: Colors.transparent,
              backgroundColor: Colors.white,
              key: _refreshKey,
              onRefresh: _updateData,
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      RoundedCard(
                        padding: EdgeInsets.all(8),
                        child: TokenIcon(
                          token.id,
                          widget.plugin.tokenIcons,
                          size: 60,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 8, top: 16),
                        child: Text(
                          Fmt.token(free, token.decimals, length: 8),
                          style: Theme.of(context).textTheme.headline1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          tokenValue > 0
                              ? '≈ \$ ${Fmt.priceFloor(tokenValue as double)}'
                              : "",
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.only(top: 20, bottom: 16),
                          child: BorderedTitle(
                            title: dic['asset.tokenInfo'],
                          )),
                      RoundedCard(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 6),
                                child: InfoItemRow(
                                  dic['asset.symbol'],
                                  token.symbol,
                                  labelStyle: labelStyle,
                                  contentStyle: valueStyle,
                                )),
                            Divider(
                              height: 1,
                            ),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 6),
                                child: InfoItemRow(
                                  dic['asset.name'],
                                  token.name,
                                  labelStyle: labelStyle,
                                  contentStyle: valueStyle,
                                )),
                            Divider(
                              height: 1,
                            ),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 6),
                                child: InfoItemRow(
                                  dic['asset.decimals'],
                                  token.decimals.toString(),
                                  labelStyle: labelStyle,
                                  contentStyle: valueStyle,
                                )),
                            detail != null
                                ? Column(children: [
                                    Divider(
                                      height: 1,
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 6),
                                        child: InfoItemRow(
                                          dic['asset.supply'],
                                          Fmt.priceFloorBigInt(
                                              Fmt.balanceInt(
                                                  detail['supply'].toString()),
                                              token.decimals,
                                              lengthMax: 8),
                                          labelStyle: labelStyle,
                                          contentStyle: valueStyle,
                                        )),
                                    Divider(
                                      height: 1,
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 6),
                                        child: InfoItemRow(
                                          dic['asset.minBalance'],
                                          Fmt.priceFloorBigInt(
                                              Fmt.balanceInt(
                                                  detail['minBalance']
                                                      .toString()),
                                              token.decimals,
                                              lengthMax: 6),
                                          labelStyle: labelStyle,
                                          contentStyle: valueStyle,
                                        )),
                                  ])
                                : Container()
                          ],
                        ),
                      ),
                      Container(
                        color: Colors.transparent,
                        margin: EdgeInsets.only(top: 36),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Button(
                                height: 44,
                                style: Theme.of(context)
                                    .textTheme
                                    .button
                                    ?.copyWith(color: btnTextColor),
                                icon: SizedBox(
                                  height: 24,
                                  child: Image.asset(
                                      'packages/polkawallet_plugin_statemine/assets/images/receive.png'),
                                ),
                                title: dic['receive'],
                                isBlueBg: false,
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, AccountQrCodePage.route);
                                },
                              ),
                            ),
                            Container(width: 20),
                            Expanded(
                              child: Button(
                                height: 44,
                                icon: SizedBox(
                                  height: 24,
                                  child: Image.asset(
                                      'packages/polkawallet_plugin_statemine/assets/images/send.png'),
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .button
                                    ?.copyWith(color: btnTextColor),
                                title: dic['transfer'],
                                isBlueBg: true,
                                onPressed: () async {
                                  final res = await Navigator.pushNamed(
                                    context,
                                    TransferPage.route,
                                    arguments: {
                                      'tokenId': token.id,
                                      'network': widget.plugin.basic.name
                                    },
                                  );
                                  if (res != null) {
                                    _refreshKey.currentState.show();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
            );
          },
        ),
      ),
    );
  }
}
