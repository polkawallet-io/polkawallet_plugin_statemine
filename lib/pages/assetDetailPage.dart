import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class AssetDetailPage extends StatefulWidget {
  AssetDetailPage(this.plugin);

  static final String route = '/statemine/assets/detail';

  final PluginStatemine plugin;

  @override
  _AssetDetailPageState createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  Widget _buildAddressInfo(Map detail, String role) {
    final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'common');
    final icon = widget.plugin.store.accounts.addressIconsMap[detail[role]];
    final accInfo = widget.plugin.store.accounts.addressIndexMap[detail[role]];
    final address = Fmt.address(detail[role]);
    return ListTile(
      dense: true,
      leading: icon != null
          ? AddressIcon(detail[role], svg: icon)
          : Container(width: 24, height: 24),
      title: accInfo != null
          ? Text(UI.accountDisplayNameString(detail[role], accInfo))
          : Text(address),
      subtitle: Text(address),
      trailing: Text(dic['asset.$role'],
          style: Theme.of(context).textTheme.headline4),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final TokenBalanceData asset = ModalRoute.of(context).settings.arguments;
      if (widget.plugin.store.assets.assetsDetails[asset.id] == null) {
        widget.plugin.service.assets.getAssetsDetail(asset.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'common');

    final TokenBalanceData asset = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
          title: Text('${dic['assets']} #${asset.id}'), centerTitle: true),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final detail = widget.plugin.store.assets.assetsDetails[asset.id];
            return ListView(
              padding: EdgeInsets.all(16),
              children: [
                RoundedCard(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      InfoItemRow(dic['asset.symbol'], asset.symbol),
                      InfoItemRow(dic['asset.name'], asset.name),
                      InfoItemRow(
                          dic['asset.decimals'], asset.decimals.toString()),
                      detail != null
                          ? Column(
                              children: [
                                Divider(),
                                InfoItemRow(
                                    dic['asset.supply'],
                                    Fmt.balance(detail['supply'].toString(),
                                        asset.decimals)),
                                InfoItemRow(
                                    dic['asset.minBalance'],
                                    Fmt.balance(detail['minBalance'].toString(),
                                        asset.decimals))
                              ],
                            )
                          : Container(),
                    ],
                  ),
                ),
                RoundedCard(
                  margin: EdgeInsets.only(top: 16, bottom: 32),
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: detail == null
                      ? Container(
                          height: MediaQuery.of(context).size.width,
                          child: CupertinoActivityIndicator(),
                        )
                      : Column(
                          children: [
                            _buildAddressInfo(detail, 'owner'),
                            _buildAddressInfo(detail, 'issuer'),
                            _buildAddressInfo(detail, 'admin'),
                            _buildAddressInfo(detail, 'freezer'),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
