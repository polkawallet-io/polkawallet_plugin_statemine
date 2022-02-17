import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_statemine/common/constants.dart';
import 'package:polkawallet_plugin_statemine/pages/defi/karuraEntryPage.dart';
import 'package:polkawallet_plugin_statemine/pages/transferPage.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';

class BannerRMRKPage extends StatelessWidget {
  BannerRMRKPage(this.plugin);
  final PluginStatemine plugin;

  static final route = '/banner/rmrk';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'defi');
    final modulesConfig =
        plugin.store.settings.remoteConfig['modules'] ?? config_modules;
    final deFiConfig = modulesConfig['defi'] ?? {};
    final isDeFiEnabled =
        deFiConfig['visible'] == true && deFiConfig['enabled'] == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['fast.title']),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            RoundedCard(
              margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Stack(
                alignment: AlignmentDirectional.centerEnd,
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 80),
                    child: Image.asset(
                      'packages/polkawallet_plugin_statemine/assets/images/tokens/RMRK_transparent.png',
                      height: 56,
                    ),
                  ),
                  ListTile(
                    title: Text(dic['fast.transfer']),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.of(context).pushNamed(TransferPage.route,
                          arguments: {'tokenId': '8', 'network': 'karura'});
                    },
                  ),
                ],
              ),
            ),
            Visibility(
                visible: isDeFiEnabled,
                child: RoundedCard(
                  margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: ListTile(
                    title: Text(dic['fast.defi']),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () =>
                        Navigator.of(context).pushNamed(KaruraEntryPage.route),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
