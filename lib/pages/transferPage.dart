import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_statemine/common/components/insufficientFeeWarn.dart';
import 'package:polkawallet_plugin_statemine/common/constants.dart';
import 'package:polkawallet_plugin_statemine/pages/defi/karuraEntryPage.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';
import 'package:polkawallet_plugin_statemine/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/addressTextFormField.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class TransferPage extends StatefulWidget {
  TransferPage(this.plugin, this.keyring);
  final PluginStatemine plugin;
  final Keyring keyring;

  static final String route = '/assets/token/transfer';

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();

  KeyPairData _accountTo;
  List<KeyPairData> _accountOptions = [];
  TokenBalanceData _token;
  String _chainTo;
  bool _accountToEditable = false;

  String _accountToError;

  TxFeeEstimateResult _fee;
  BigInt _amountMax;

  bool _submitting = false;

  Future<String> _checkAccountTo(KeyPairData acc, int chainToSS58) async {
    if (widget.keyring.allAccounts.indexWhere((e) => e.pubKey == acc.pubKey) >=
        0) {
      return null;
    }

    final addressCheckValid = await widget.plugin.sdk.webView.evalJavascript(
        '(account.checkAddressFormat != undefined ? {}:null)',
        wrapPromise: false);
    if (addressCheckValid != null) {
      final res = await widget.plugin.sdk.api.account
          .checkAddressFormat(acc.address, chainToSS58);
      if (res != null && !res) {
        return I18n.of(context)
            .getDic(i18n_full_dic_ui, 'account')['ss58.mismatch'];
      }
    }
    return null;
  }

  Future<void> _validateAccountTo(KeyPairData acc, int chainToSS58) async {
    final error = await _checkAccountTo(acc, chainToSS58);
    setState(() {
      _accountToError = error;
    });
  }

  Future<String> _getTxFee({bool isXCM = false, bool reload = false}) async {
    if (_fee?.partialFee != null && !reload) {
      return _fee.partialFee.toString();
    }

    final sender = TxSenderData(
        widget.keyring.current.address, widget.keyring.current.pubKey);
    final txInfo = TxInfoData(isXCM ? 'polkadotXcm' : 'assets',
        isXCM ? 'limitedReserveTransferAssets' : 'transfer', sender);
    final fee = await widget.plugin.sdk.api.tx.estimateFees(
        txInfo,
        isXCM
            ? [
                {
                  'V0': {
                    'X2': [
                      'Parent',
                      {'Parachain': '1000'}
                    ]
                  }
                },
                {
                  'V0': {
                    'X1': {
                      'AccountId32': {'network': 'Any', 'id': ''}
                    }
                  }
                },
                {
                  'V0': [
                    {
                      'ConcreteFungible': {
                        'id': {
                          'X1': {'GeneralIndex': _token.id}
                        },
                        'amount': '1000000000'
                      }
                    }
                  ]
                },
                0,
                'Unlimited'
              ]
            : [_token.id, widget.keyring.current.address, '1000000000']);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee.partialFee.toString();
  }

  Future<void> _onScan(int chainToSS58) async {
    final to = await Navigator.of(context).pushNamed(ScanPage.route);
    if (to == null) return;
    final acc = KeyPairData();
    acc.address = (to as QRCodeResult).address.address;
    acc.name = (to as QRCodeResult).address.name;
    final res = await Future.wait([
      widget.plugin.sdk.api.account.getAddressIcons([acc.address]),
      _checkAccountTo(acc, chainToSS58),
    ]);
    if (res[0] != null) {
      final List icon = res[0] as List<dynamic>;
      acc.icon = icon[0][1];
    }
    setState(() {
      _accountTo = acc;
      _accountToError = res[1] as String;
    });
    print(_accountTo.address);
  }

  /// XCM only support KSM transfer back to Kusama.
  void _onSelectChain(Map<String, Widget> crossChainIcons) {
    final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'common');

    final tokensConfig =
        widget.plugin.store.settings.remoteConfig['tokens'] ?? {};
    final List tokenXcmConfig =
        (tokensConfig['xcm'] ?? config_xcm['xcm'])[_token.id] ?? [];
    final options = [widget.plugin.basic.name, ...tokenXcmConfig];

    showCupertinoModalPopup(
      context: context,
      builder: (_) => PolkawalletActionSheet(
        title: Text(dic['cross.chain.select']),
        actions: options.map((e) {
          return PolkawalletActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(right: 8),
                  width: 32,
                  height: 32,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: TokenIcon(e, crossChainIcons),
                  ),
                ),
                Text(
                  e.toUpperCase(),
                )
              ],
            ),
            onPressed: () {
              if (e != _chainTo) {
                // set ss58 of _chainTo so we can get according address
                // from AddressInputField
                final chainToSS58 = (tokensConfig['xcmChains'] ??
                    config_xcm['xcmChains'])[e]['ss58'];
                widget.keyring.setSS58(chainToSS58);
                final options = widget.keyring.allWithContacts.toList();
                widget.keyring.setSS58(widget.plugin.basic.ss58);
                setState(() {
                  _chainTo = e;
                  _accountOptions = options;

                  if (e != widget.plugin.basic.name) {
                    _accountTo = widget.keyring.current;
                  }
                });

                _validateAccountTo(_accountTo, chainToSS58);

                // update estimated tx fee if switch ToChain
                _getTxFee(isXCM: e != widget.plugin.basic.name, reload: true);
              }
              Navigator.of(context).pop();
            },
          );
        }).toList(),
        cancelButton: PolkawalletActionSheetAction(
          child: Text(I18n.of(context)
              .getDic(i18n_full_dic_statemine, 'common')['cancel']),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _onSwitchEditable(bool v) async {
    if (v) {
      final confirm = await showCupertinoDialog(
          context: context,
          builder: (_) {
            final dic =
                I18n.of(context).getDic(i18n_full_dic_statemine, 'common');
            return PolkawalletAlertDialog(
              type: DialogType.warn,
              title: Text(dic['cross.warn']),
              content: Text(dic['cross.warn.info']),
              actions: [
                PolkawalletActionSheetAction(
                    child: Text(dic['cancel']),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    }),
                PolkawalletActionSheetAction(
                    isDefaultAction: true,
                    child: Text(dic['ok']),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    }),
              ],
            );
          });
      if (!confirm) return;
    }
    setState(() {
      _accountToEditable = v;
      if (!v) {
        _accountTo = widget.keyring.current;
        _accountToError = null;
      }
    });
  }

  Future<TxConfirmParams> _getTxParams(String chainTo, String chainToId) async {
    if (_accountToError == null &&
        _formKey.currentState.validate() &&
        !_submitting) {
      final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'common');

      /// send XCM tx if cross chain
      if (chainTo != widget.plugin.basic.name) {
        String destPubKey = _accountTo.pubKey;
        // we need to decode address for the pubKey here
        if (destPubKey == null || destPubKey.isEmpty) {
          setState(() {
            _submitting = true;
          });
          final pk = await widget.plugin.sdk.api.account
              .decodeAddress([_accountTo.address]);
          setState(() {
            _submitting = false;
          });
          if (pk == null) return null;

          destPubKey = pk.keys.toList()[0];
        }

        return TxConfirmParams(
          txTitle: '${dic['transfer']} ${_token.symbol} (${dic['cross.xcm']})',
          module: 'polkadotXcm',
          call: 'limitedReserveTransferAssets',
          txDisplay: {
            dic['cross.chain']: chainTo.toUpperCase(),
          },
          txDisplayBold: {
            dic['amount']: Text(
              Fmt.priceFloor(double.tryParse(_amountCtrl.text.trim()),
                      lengthMax: 8) +
                  ' ${_token.symbol}',
              style: Theme.of(context).textTheme.headline1,
            ),
            dic['address']: Row(
              children: [
                AddressIcon(_accountTo.address, svg: _accountTo.icon),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                    child: Text(
                      Fmt.address(_accountTo?.address, pad: 8) ?? '',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                ),
              ],
            ),
          },
          params: [
            // params.dest
            {
              'V0': {
                'X2': [
                  'Parent',
                  {'Parachain': chainToId}
                ]
              }
            },
            // params.beneficiary
            {
              'V0': {
                'X1': {
                  'AccountId32': {'network': 'Any', 'id': destPubKey}
                }
              }
            },
            // params.assets
            {
              'V0': [
                {
                  'ConcreteFungible': {
                    'id': {
                      'X2': [
                        {'PalletInstance': 50},
                        {'GeneralIndex': _token.id}
                      ]
                    },
                    'amount': (_amountMax ??
                            Fmt.tokenInt(
                                _amountCtrl.text.trim(), _token.decimals))
                        .toString()
                  }
                }
              ]
            },
            0,
            'Unlimited'
          ],
        );
      }

      /// else return normal transfer
      final params = [
        // params.assetId
        int.parse(_token.id),
        // params.to
        _accountTo.address,
        // params.amount
        (_amountMax ?? Fmt.tokenInt(_amountCtrl.text.trim(), _token.decimals))
            .toString(),
      ];
      return TxConfirmParams(
        module: 'assets',
        call: 'transfer',
        txTitle: '${dic['transfer']} ${_token.symbol}',
        txDisplay: {},
        txDisplayBold: {
          dic['amount']: Text(
            Fmt.priceFloor(double.tryParse(_amountCtrl.text.trim()),
                    lengthMax: 8) +
                ' ${_token.symbol}',
            style: Theme.of(context).textTheme.headline1,
          ),
          dic['address']: Row(
            children: [
              AddressIcon(_accountTo.address, svg: _accountTo.icon),
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                  child: Text(
                    Fmt.address(_accountTo?.address, pad: 8) ?? '',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ),
              ),
            ],
          ),
        },
        params: params,
      );
    }
    return null;
  }

  Future<void> _goToDeFi(Map crossChainIcons) async {
    return showCupertinoDialog(
      context: context,
      builder: (_) {
        final dic = I18n.of(context).getDic(i18n_full_dic_statemine, 'common');
        final dicDeFi =
            I18n.of(context).getDic(i18n_full_dic_statemine, 'defi');
        return PolkawalletAlertDialog(
          title: Text(dicDeFi['xcm.tip.title']),
          content: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 16, bottom: 16),
                child: Text(dicDeFi['xcm.tip.content']),
              ),
              InfoItemRow(dic['address'], Fmt.address(_accountTo.address)),
              InfoItemRow(
                  dic['amount'], '${_amountCtrl.text.trim()} ${_token.symbol}'),
              Row(
                children: [
                  Expanded(
                      child: Text(
                    dic['cross.chain'],
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.headline5,
                  )),
                  TokenIcon(_chainTo, crossChainIcons, size: 24),
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    child: Text(
                      _chainTo.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .headline5
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            PolkawalletActionSheetAction(
                child: Text(dic['ok']),
                onPressed: () {
                  Navigator.of(context).popAndPushNamed(KaruraEntryPage.route);
                })
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context).settings.arguments as Map;
      setState(() {
        _token = widget.plugin.store.assets.tokenBalanceMap[args['tokenId']];
        _chainTo = args['network'];
        _accountOptions = widget.keyring.allWithContacts.toList();
        _accountTo = widget.keyring.current;
      });

      _getTxFee();
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
        final args = ModalRoute.of(context).settings.arguments as Map;
        final token = _token ??
            widget.plugin.store.assets.tokenBalanceMap[args['tokenId']];
        final tokenSymbol = token.symbol.toUpperCase();

        final tokensConfig =
            widget.plugin.store.settings.remoteConfig['tokens'] ?? {};
        final List tokenXcmConfig = tokensConfig['xcm'] != null
            ? tokensConfig['xcm'][token.id]
            : config_xcm['xcm'][token.id] ?? [];
        final canCrossChain =
            tokenXcmConfig != null && tokenXcmConfig.length > 0;

        final nativeTokenBalance =
            Fmt.balanceInt(widget.plugin.balances.native.freeBalance) -
                Fmt.balanceInt(widget.plugin.balances.native.frozenFee);
        final accountED = Fmt.balanceInt(widget
            .plugin.networkConst['balances']['existentialDeposit']
            .toString());
        final isNativeTokenLow = nativeTokenBalance - accountED <
            Fmt.balanceInt((_fee?.partialFee ?? 0).toString()) * BigInt.two;

        final balanceData =
            widget.plugin.store.assets.tokenBalanceMap[token.id];
        final available = Fmt.balanceInt(balanceData?.amount) -
            Fmt.balanceInt(balanceData?.locked);
        final nativeToken = widget.plugin.networkState.tokenSymbol[0];
        final nativeTokenDecimals = widget.plugin.networkState.tokenDecimals[
            widget.plugin.networkState.tokenSymbol.indexOf(nativeToken)];
        final assetDetail = widget.plugin.store.assets.assetsDetails[token.id];
        final existDeposit = assetDetail != null
            ? Fmt.balanceInt(assetDetail['minBalance'].toString())
            : BigInt.zero;

        final chainTo = _chainTo ?? widget.plugin.basic.name;
        final isCrossChain = widget.plugin.basic.name != chainTo;
        final tokenXcmInfo = tokensConfig['xcmInfo'] != null
            ? tokensConfig['xcmInfo'][chainTo]
            : config_xcm['xcmInfo'][chainTo] ?? {};
        final destExistDeposit = isCrossChain
            ? Fmt.balanceInt(tokenXcmInfo[tokenSymbol]['existentialDeposit'])
            : BigInt.zero;
        final destFee = isCrossChain
            ? Fmt.balanceInt(tokenXcmInfo[tokenSymbol]['fee'])
            : BigInt.zero;

        final crossChainIcons = Map<String, Widget>.from(
            widget.plugin.store.assets.crossChainIcons.map((k, v) => MapEntry(
                k.toUpperCase(),
                (v as String).contains('.svg')
                    ? SvgPicture.network(v)
                    : Image.network(v))));
        final chainToId = (tokensConfig['xcmChains'] ??
            config_xcm['xcmChains'])[chainTo]['id'];
        final chainToSS58 = (tokensConfig['xcmChains'] ??
            config_xcm['xcmChains'])[chainTo]['ss58'];

        final labelStyle = Theme.of(context).textTheme.headline4;

        return Scaffold(
          appBar: AppBar(
            title: Text('${dic['transfer']} $tokenSymbol'),
            centerTitle: true,
            leading: BackBtn(),
            actions: <Widget>[
              Visibility(
                visible: !isCrossChain,
                child: v3.IconButton(
                    margin: EdgeInsets.only(right: 12),
                    icon: SvgPicture.asset(
                      'assets/images/scan.svg',
                      color: Theme.of(context).cardColor,
                      width: 18,
                    ),
                    onPressed: () => _onScan(chainToSS58),
                    isBlueBg: true),
              )
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(dic['address.from'] ?? '', style: labelStyle),
                        AddressFormItem(widget.keyring.current),
                        Container(height: 8.h),
                        Visibility(
                            visible: !(!isCrossChain || _accountToEditable),
                            child:
                                Text(dic['address'] ?? '', style: labelStyle)),
                        Visibility(
                            visible: !(!isCrossChain || _accountToEditable),
                            child: AddressFormItem(widget.keyring.current)),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Visibility(
                                visible: !isCrossChain || _accountToEditable,
                                child: AddressTextFormField(
                                  widget.plugin.sdk.api,
                                  _accountOptions,
                                  labelText: dic['address'],
                                  labelStyle: labelStyle,
                                  hintText: dic['address'],
                                  initialValue: _accountTo,
                                  onChanged: (KeyPairData acc) async {
                                    final error =
                                        await _checkAccountTo(acc, chainToSS58);
                                    setState(() {
                                      _accountTo = acc;
                                      _accountToError = error;
                                    });
                                  },
                                  key: ValueKey<KeyPairData>(_accountTo),
                                  sdk: widget.plugin.sdk,
                                ),
                              ),
                              Visibility(
                                  visible: _accountToError != null,
                                  child: Container(
                                    margin: EdgeInsets.only(top: 4),
                                    child: Text(_accountToError ?? "",
                                        style: TextStyle(
                                            fontSize:
                                                UI.getTextSize(12, context),
                                            color: Colors.red)),
                                  )),
                              Visibility(
                                visible: isCrossChain,
                                child: GestureDetector(
                                  child: Container(
                                    child: Row(
                                      children: [
                                        v3.Checkbox(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 8, 8, 0),
                                          value: _accountToEditable,
                                          onChanged: _onSwitchEditable,
                                        ),
                                        Container(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            dic['cross.edit'],
                                            style: TextStyle(
                                                fontSize: UI.getTextSize(
                                                    14, context)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () =>
                                      _onSwitchEditable(!_accountToEditable),
                                ),
                              ),
                              Container(height: 10.h),
                              v3.TextInputWidget(
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoration: v3.InputDecorationV3(
                                  hintText: dic['amount.hint'],
                                  labelText:
                                      '${dic['amount']} (${dic['balance']}: ${Fmt.priceFloorBigInt(
                                    available,
                                    token.decimals,
                                    lengthMax: 6,
                                  )})',
                                  labelStyle: labelStyle,
                                  suffix: GestureDetector(
                                    child: Text(dic['amount.max'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .toggleableActiveColor)),
                                    onTap: () {
                                      setState(() {
                                        _amountMax = available - existDeposit;
                                        _amountCtrl.text = Fmt.bigIntToDouble(
                                                available - existDeposit,
                                                token.decimals)
                                            .toStringAsFixed(8);
                                      });
                                    },
                                  ),
                                ),
                                inputFormatters: [
                                  UI.decimalInputFormatter(token.decimals)
                                ],
                                controller: _amountCtrl,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                onChanged: (_) {
                                  setState(() {
                                    _amountMax = null;
                                  });
                                },
                                validator: (v) {
                                  final error = Fmt.validatePrice(v, context);
                                  if (error != null) {
                                    return error;
                                  }

                                  final input =
                                      Fmt.tokenInt(v.trim(), token.decimals);
                                  if (_amountMax == null &&
                                      Fmt.bigIntToDouble(
                                              input, token.decimals) >
                                          (available - existDeposit) /
                                              BigInt.from(
                                                  pow(10, token.decimals))) {
                                    return dic['amount.low'];
                                  }
                                  return null;
                                },
                              )
                            ],
                          ),
                        ),
                        Visibility(
                            visible: canCrossChain,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                margin: EdgeInsets.only(bottom: 4, top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        dic['cross.chain'],
                                        style: labelStyle,
                                      ),
                                    ),
                                    RoundedCard(
                                      padding: EdgeInsets.all(8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Container(
                                                margin:
                                                    EdgeInsets.only(right: 8),
                                                width: 32,
                                                height: 32,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(32),
                                                  child: isCrossChain
                                                      ? TokenIcon(_chainTo,
                                                          crossChainIcons)
                                                      : widget
                                                          .plugin.basic.icon,
                                                ),
                                              ),
                                              Text(chainTo.toUpperCase())
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Visibility(
                                                  visible: isCrossChain,
                                                  child: TextTag(
                                                      dic['cross.xcm'],
                                                      margin: EdgeInsets.only(
                                                          right: 8),
                                                      color: Theme.of(context)
                                                          .errorColor)),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .unselectedWidgetColor,
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () => _onSelectChain(crossChainIcons),
                            )),
                        Visibility(
                          visible: isNativeTokenLow,
                          child: Container(
                            margin: EdgeInsets.only(top: 8),
                            child: InsufficientFeeWarn(),
                          ),
                        ),
                        Visibility(
                            visible: isCrossChain,
                            child: Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TapTooltip(
                                      message: dic['cross.exist.msg'],
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(right: 4),
                                            child: Text(dic['cross.exist']),
                                          ),
                                          Icon(
                                            Icons.info,
                                            size: 16,
                                            color: Theme.of(context)
                                                .unselectedWidgetColor,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 0,
                                    child: Text(
                                        '${Fmt.priceCeilBigInt(destExistDeposit, token.decimals, lengthMax: 6)} $tokenSymbol'),
                                  )
                                ],
                              ),
                            )),
                        Visibility(
                            visible: isCrossChain,
                            child: Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Text(dic['cross.fee']),
                                    ),
                                  ),
                                  Text(
                                      '${Fmt.priceCeilBigInt(destFee, token.decimals, lengthMax: 6)} $tokenSymbol'),
                                ],
                              ),
                            )),
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TapTooltip(
                                  message: dic['cross.exist.msg'],
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Text(dic['transfer.exist']),
                                      ),
                                      Icon(
                                        Icons.info,
                                        size: 16,
                                        color: Theme.of(context)
                                            .unselectedWidgetColor,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                  '${Fmt.priceCeilBigInt(existDeposit, token.decimals, lengthMax: 6)} $tokenSymbol'),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: _fee?.partialFee != null,
                          child: Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Text(dic['transfer.fee']),
                                  ),
                                ),
                                Text(
                                    '${Fmt.priceCeilBigInt(Fmt.balanceInt((_fee?.partialFee ?? 0).toString()), nativeTokenDecimals, lengthMax: 6)} $nativeToken'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 14.w, 16.h),
                  child: TxButton(
                    text: dic['make'],
                    getTxParams: () => _getTxParams(chainTo, chainToId),
                    onFinish: (res) async {
                      if (res != null) {
                        // jump to karura defi page if enabled
                        final modulesConfig = widget.plugin.store.settings
                                .remoteConfig['modules'] ??
                            config_modules;
                        final deFiConfig = modulesConfig['defi'] ?? {};
                        if (_token.symbol == foreign_token_symbol_RMRK &&
                            isCrossChain &&
                            deFiConfig['visible'] == true &&
                            deFiConfig['enabled'] == true) {
                          await _goToDeFi(crossChainIcons);
                        } else {
                          Navigator.of(context).pop(res);
                        }
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
