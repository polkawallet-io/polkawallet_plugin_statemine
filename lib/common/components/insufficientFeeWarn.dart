import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_statemine/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/textTag.dart';

class InsufficientFeeWarn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'common');
    return Row(
      children: [
        Expanded(
          child: TextTag(
            dic['warn.fee'],
            padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
            margin: EdgeInsets.only(bottom: 8),
            color: Colors.deepOrangeAccent,
          ),
        )
      ],
    );
  }
}
