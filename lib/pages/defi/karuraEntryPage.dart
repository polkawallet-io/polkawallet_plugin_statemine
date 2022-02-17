import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_statemine/common/constants.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/app.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/back.dart';

class KaruraEntryPage extends StatelessWidget {
  KaruraEntryPage(this.plugin);
  final PluginStatemine plugin;

  static final String route = '/defi/kar';

  void _goToKar(BuildContext context, String module) {
    Navigator.popUntil(context, ModalRoute.withName('/'));
    switch (module) {
      case 'loan':
        plugin.appUtils.switchNetwork(
          'karura',
          pageRoute:
              PageRouteParams('/karura/loan', args: {'loanType': 'fa://0'}),
        );
        break;
      case 'swap':
        plugin.appUtils.switchNetwork(
          'karura',
          pageRoute: PageRouteParams('/karura/dex', args: {
            'swapPair': ['fa://0', 'KUSD']
          }),
        );
        break;
      case 'earn':
        plugin.appUtils.switchNetwork(
          'karura',
          pageRoute: PageRouteParams('/karura/earn/deposit',
              args: {'poolId': 'lp://KUSD/fa%3A%2F%2F0'}),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'defi');
    final modulesConfig =
        plugin.store.settings.remoteConfig['modules'] ?? config_modules;
    final items = ['loan', 'swap', 'earn'];
    items.retainWhere((e) => modulesConfig['defi']['items'][e] == true);

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['kar.title']),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(left: 16, top: 8),
              child: Row(
                children: [
                  Image.asset(
                    'packages/polkawallet_plugin_statemine/assets/images/tokens/KAR.png',
                    height: 24,
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 6),
                    child: Text(
                      'KARURA',
                      style: Theme.of(context)
                          .textTheme
                          .headline1
                          .copyWith(fontSize: 18),
                    ),
                  )
                ],
              ),
            ),
            ...items.map((e) {
              return RoundedCard(
                margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: EdgeInsets.only(top: 8, bottom: 8),
                child: ListTile(
                  title: Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        child: Text(
                          dic['kar.$e'],
                          style: Theme.of(context)
                              .textTheme
                              .headline1
                              .copyWith(fontSize: 18),
                        ),
                      ),
                      Image.asset(
                          'packages/polkawallet_plugin_statemine/assets/images/defi/icon_$e.png',
                          width: 18)
                    ],
                  ),
                  subtitle: Text(
                    dic['kar.$e.brief'],
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () => _goToKar(context, e),
                ),
              );
            }).toList()
          ],
        ),
      ),
    );
  }
}
