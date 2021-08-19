import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_statemine/pages/transferPage.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/utils/format.dart';

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

    final primaryColor = Theme.of(context).primaryColor;
    final titleColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(token.symbol),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final balance =
                widget.plugin.store.assets.tokenBalanceMap[token.id];
            final free = Fmt.balanceInt(balance?.amount ?? '0');
            return RefreshIndicator(
              key: _refreshKey,
              onRefresh: _updateData,
              child: Column(
                children: <Widget>[
                  Stack(
                    alignment: AlignmentDirectional.bottomCenter,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.center,
                        color: primaryColor,
                        padding: EdgeInsets.only(bottom: 24),
                        margin: EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 40),
                          child: Column(
                            children: [
                              Container(
                                margin: EdgeInsets.only(bottom: 24),
                                child: Text(
                                  Fmt.token(free, token.decimals, length: 8),
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 48,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: titleColor,
                          borderRadius:
                              const BorderRadius.all(const Radius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    color: titleColor,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(16, 8, 8, 8),
                            child: RoundedButton(
                              icon: Icon(Icons.qr_code,
                                  color: titleColor, size: 24),
                              text: dic['receive'],
                              color: colorIn,
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, AccountQrCodePage.route);
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
                            child: RoundedButton(
                              icon: SizedBox(
                                height: 20,
                                child: Image.asset(
                                    'packages/polkawallet_plugin_acala/assets/images/assets_send.png'),
                              ),
                              text: dic['transfer'],
                              color: colorOut,
                              onPressed: () async {
                                final res = await Navigator.pushNamed(
                                  context,
                                  TransferPage.route,
                                  arguments: token,
                                );
                                if (res != null) {
                                  _refreshKey.currentState.show();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
