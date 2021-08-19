import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_statemine/common/constants.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressInputField.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class TransferPage extends StatefulWidget {
  TransferPage(this.plugin, this.keyring);
  final PluginStatemine plugin;
  final Keyring keyring;

  static final String route = '/assets/asset/transfer';

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();

  KeyPairData _accountTo;

  String _accountToError;

  TxFeeEstimateResult _fee;

  Future<String> _checkAccountTo(KeyPairData acc) async {
    if (widget.keyring.allAccounts.indexWhere((e) => e.pubKey == acc.pubKey) >=
        0) {
      return null;
    }

    final addressCheckValid = await widget.plugin.sdk.webView.evalJavascript(
        '(account.checkAddressFormat != undefined ? {}:null)',
        wrapPromise: false);
    if (addressCheckValid != null) {
      final res = await widget.plugin.sdk.api.account.checkAddressFormat(
          acc.address, plugin_ss58_format[widget.plugin.basic.name]);
      if (res != null && !res) {
        return I18n.of(context)
            .getDic(i18n_full_dic_ui, 'account')['ss58.mismatch'];
      }
    }
    return null;
  }

  Future<String> _getTxFee({bool reload = false}) async {
    if (_fee?.partialFee != null && !reload) {
      return _fee.partialFee.toString();
    }

    final sender = TxSenderData(
        widget.keyring.current.address, widget.keyring.current.pubKey);
    final txInfo = TxInfoData('assets', 'transfer', sender);
    final fee = await widget.plugin.sdk.api.tx.estimateFees(
        txInfo, ['0', widget.keyring.current.address, '1000000000']);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee.partialFee.toString();
  }

  Future<void> _onScan() async {
    final to = await Navigator.of(context).pushNamed(ScanPage.route);
    if (to == null) return;
    final acc = KeyPairData();
    acc.address = (to as QRCodeResult).address.address;
    acc.name = (to as QRCodeResult).address.name;
    final res = await Future.wait([
      widget.plugin.sdk.api.account.getAddressIcons([acc.address]),
      _checkAccountTo(acc),
    ]);
    if (res != null && res[0] != null) {
      final List icon = res[0];
      acc.icon = icon[0][1];
    }
    setState(() {
      _accountTo = acc;
      _accountToError = res[1];
    });
    print(_accountTo.address);
  }

  Future<TxConfirmParams> _getTxParams() async {
    if (_accountToError == null && _formKey.currentState.validate()) {
      final TokenBalanceData asset = ModalRoute.of(context).settings.arguments;

      final params = [
        // params.assetId
        int.parse(asset.id),
        // params.to
        _accountTo.address,
        // params.amount
        Fmt.tokenInt(_amountCtrl.text.trim(), asset.decimals).toString(),
      ];
      return TxConfirmParams(
        module: 'assets',
        call: 'transfer',
        txTitle:
            '${I18n.of(context).getDic(i18n_full_dic_statemine, 'common')['transfer']} ${asset.symbol}',
        txDisplay: {
          "destination": _accountTo.address,
          "currency": asset.symbol,
          "amount": _amountCtrl.text.trim(),
        },
        params: params,
      );
    }
    return null;
  }

  Future<void> _initAccountTo(KeyPairData acc) async {
    final to = KeyPairData();
    to.address = acc.address;
    to.pubKey = acc.pubKey;
    setState(() {
      _accountTo = to;
    });
    final icon =
        await widget.plugin.sdk.api.account.getAddressIcons([acc.address]);
    if (icon != null) {
      final accWithIcon = KeyPairData();
      accWithIcon.address = acc.address;
      accWithIcon.pubKey = acc.pubKey;
      accWithIcon.icon = icon[0][1];
      setState(() {
        _accountTo = accWithIcon;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getTxFee();

      if (widget.keyring.allWithContacts.length > 0) {
        _initAccountTo(widget.keyring.allWithContacts[0]);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'common');
        final TokenBalanceData asset =
            ModalRoute.of(context).settings.arguments;

        final nativeToken = widget.plugin.networkState.tokenSymbol[0];
        final nativeDecimals = widget.plugin.networkState.tokenDecimals[0];
        final available = Fmt.balanceInt(asset.amount);
        final assetDetail = widget.plugin.store.assets.assetsDetails[asset.id];
        final minBalance = Fmt.balanceInt(
            assetDetail != null ? assetDetail['minBalance'].toString() : '0');

        final existDeposit = Fmt.balanceInt(widget
            .plugin.networkConst['balances']['existentialDeposit']
            .toString());

        final colorGrey = Theme.of(context).unselectedWidgetColor;

        return Scaffold(
          appBar: AppBar(
            title: Text(dic['transfer']),
            centerTitle: true,
            actions: <Widget>[
              IconButton(
                padding: EdgeInsets.only(right: 8),
                icon: SvgPicture.asset(
                  'assets/images/scan.svg',
                  color: Theme.of(context).cardColor,
                  width: 28,
                ),
                onPressed: _onScan,
              )
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: <Widget>[
                        AddressInputField(
                          widget.plugin.sdk.api,
                          widget.keyring.allAccounts,
                          label: dic['address'],
                          initialValue: _accountTo,
                          onChanged: (KeyPairData acc) async {
                            final error = await _checkAccountTo(acc);
                            setState(() {
                              _accountTo = acc;
                              _accountToError = error;
                            });
                          },
                          key: ValueKey<KeyPairData>(_accountTo),
                        ),
                        _accountToError != null
                            ? Container(
                                margin: EdgeInsets.only(top: 4),
                                child: Text(_accountToError,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.red)),
                              )
                            : Container(),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: dic['amount'],
                            labelText:
                                '${dic['amount']} (${dic['balance']}: ${Fmt.priceFloorBigInt(
                              available,
                              asset.decimals,
                              lengthMax: 6,
                            )})',
                          ),
                          inputFormatters: [
                            UI.decimalInputFormatter(asset.decimals)
                          ],
                          controller: _amountCtrl,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v.isEmpty) {
                              return dic['amount.error'];
                            }
                            if (double.parse(v.trim()) >
                                available /
                                    BigInt.from(pow(10, asset.decimals))) {
                              return dic['amount.low'];
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Text(dic['transfer.exist']),
                              ),
                              TapTooltip(
                                message: dic['transfer.exist.info'],
                                child: Icon(
                                  Icons.info,
                                  size: 16,
                                  color:
                                      Theme.of(context).unselectedWidgetColor,
                                ),
                              ),
                              Expanded(child: Container(width: 2)),
                              Text(
                                  '${Fmt.priceCeilBigInt(existDeposit, nativeDecimals, lengthMax: 6)} $nativeToken'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Text(dic['transfer.min']),
                              ),
                              TapTooltip(
                                message: dic['transfer.min.info'],
                                child: Icon(
                                  Icons.info,
                                  size: 16,
                                  color:
                                      Theme.of(context).unselectedWidgetColor,
                                ),
                              ),
                              Expanded(child: Container(width: 2)),
                              Text(
                                  '${Fmt.priceCeilBigInt(minBalance, asset.decimals, lengthMax: 6)} ${asset.symbol}'),
                            ],
                          ),
                        ),
                        _fee?.partialFee != null
                            ? Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Text(dic['transfer.fee']),
                                    ),
                                    Expanded(child: Container(width: 2)),
                                    Text(
                                        '${Fmt.priceCeilBigInt(Fmt.balanceInt(_fee.partialFee.toString()), asset.decimals, lengthMax: 6)} $nativeToken'),
                                  ],
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  child: TxButton(
                    text: dic['make'],
                    getTxParams: _getTxParams,
                    onFinish: (res) {
                      if (res != null) {
                        Navigator.of(context).pop(res);
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
