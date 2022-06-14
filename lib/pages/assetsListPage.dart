import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_statemine/pages/assetDetailPage.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/utils/index.dart';

class AssetsListPage extends StatefulWidget {
  AssetsListPage(this.plugin);

  final PluginStatemine plugin;

  static final String route = '/assets/list';

  @override
  _AssetsListPageState createState() => _AssetsListPageState();
}

class _AssetsListPageState extends State<AssetsListPage> {
  final TextEditingController _filterCtrl = new TextEditingController();

  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'common');

    final list = widget.plugin.store.assets.assetsAll.toList();
    list.retainWhere((e) =>
        e.name.toUpperCase().contains(_filter) ||
        e.symbol.toUpperCase().contains(_filter) ||
        e.id.toUpperCase().contains(_filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['assets']),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            child: CupertinoTextField(
              autofocus: false,
              padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(24)),
                border: Border.all(
                    width: 0.5, color: Theme.of(context).dividerColor),
              ),
              controller: _filterCtrl,
              placeholder: dic['assets.filter'],
              placeholderStyle: TextStyle(
                  fontSize: UI.getTextSize(14, context),
                  color: Theme.of(context).disabledColor),
              cursorHeight: 14,
              style: TextStyle(fontSize: 14),
              suffix: Container(
                margin: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.search,
                  color: Theme.of(context).disabledColor,
                  size: 20,
                ),
              ),
              onChanged: (v) {
                setState(() {
                  _filter = _filterCtrl.text.trim().toUpperCase();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length + 1,
              itemBuilder: (_, i) {
                if (i == list.length) {
                  return ListTail(
                    isEmpty: list.length == 0,
                    isLoading: false,
                  );
                }
                return ListTile(
                  dense: true,
                  leading: TokenIcon(
                    list[i].id,
                    widget.plugin.tokenIcons,
                    symbol: list[i].symbol,
                  ),
                  title: Text(list[i].symbol),
                  subtitle: Text(list[i].name),
                  trailing: Text(
                    '#${list[i].id}',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AssetDetailPage.route, arguments: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
