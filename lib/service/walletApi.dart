import 'dart:convert';

import 'package:http/http.dart';

class WalletApi {
  static const String _endpoint = 'https://api.polkawallet.io';
  static const String _configEndpoint = 'https://acala.subdao.com';

  static Future<Map> getTokensConfig() async {
    final url = '$_configEndpoint/config/statemineTokens.json';
    try {
      Response res = await get(Uri.parse(url));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<Map> getTokenPrice(String token) async {
    final url = '$_endpoint/price-server/?token=$token';
    try {
      Response res = await get(Uri.parse(url));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }
}