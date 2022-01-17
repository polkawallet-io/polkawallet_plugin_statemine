import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
              PageRouteParams('/karura/loan', args: {'loanType': 'LKSM'}),
        );
        break;
      case 'swap':
        plugin.appUtils.switchNetwork(
          'karura',
          pageRoute: PageRouteParams('/karura/dex', args: {
            'swapPair': ['BNC', 'KUSD']
          }),
        );
        break;
      case 'earn':
        plugin.appUtils.switchNetwork(
          'karura',
          pageRoute: PageRouteParams('/karura/earn/deposit',
              args: {'poolId': 'lp://KAR/LKSM'}),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'defi');
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['kar.title']),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: ['loan', 'swap', 'earn'].map((e) {
            return GestureDetector(
              child: RoundedCard(
                margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dic['kar.$e'],
                      style: Theme.of(context).textTheme.headline1,
                    ),
                    Text(dic['kar.$e.brief'])
                  ],
                ),
              ),
              onTap: () => _goToKar(context, e),
            );
          }).toList(),
        ),
      ),
    );
  }
}
