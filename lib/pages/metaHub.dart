import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_statemine/common/constants.dart';
import 'package:polkawallet_plugin_statemine/pages/assetsListPage.dart';
import 'package:polkawallet_plugin_statemine/pages/defi/karuraEntryPage.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginItemCard.dart';

class MetaHubPanel extends StatelessWidget {
  MetaHubPanel(this.plugin);

  final PluginStatemine plugin;

  final _liveModuleRoutes = {
    module_name_assets: AssetsListPage.route,
    module_name_defi: KaruraEntryPage.route,
  };

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'common');
    return Observer(builder: (_) {
      final modulesConfig =
          plugin.store.settings.remoteConfig['modules'] ?? config_modules;
      final List liveModules = modulesConfig.keys.toList();

      liveModules.retainWhere((e) => modulesConfig[e]['visible']);

      return Container(
        child: Column(
          children: liveModules.map((e) {
            final enabled = modulesConfig[e]['enabled'];

            String title = '';
            String describe = '';
            switch (e) {
              case module_name_assets:
                title = dic['assets'];
                describe = dic['assets.brief'];
                break;
              case module_name_defi:
                title = I18n.of(context)
                    .getDic(i18n_full_dic_statemine, 'defi')['kar.title'];
                describe = I18n.of(context)
                    .getDic(i18n_full_dic_statemine, 'defi')['kar.brief'];
                break;
            }

            return GestureDetector(
              child: PluginItemCard(
                margin: EdgeInsets.only(bottom: 16),
                title: title,
                describe: describe,
                // icon: Image.asset(
                //     "packages/polkawallet_plugin_karura/assets/images/icon_$e.png",
                //     width: 18),
              ),
              onTap: () {
                if (enabled) {
                  Navigator.of(context).pushNamed(_liveModuleRoutes[e]);
                } else {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) {
                      return CupertinoAlertDialog(
                        title: Text(dic['upgrading']),
                        content: Text(dic['upgrading.context']),
                        actions: <Widget>[
                          CupertinoDialogAction(
                            child: Text(dic['upgrading.btn']),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            );
          }).toList(),
        ),
      );
    });
  }
}
