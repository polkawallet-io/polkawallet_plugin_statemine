import 'package:flutter/material.dart';

const int SECONDS_OF_DAY = 24 * 60 * 60; // seconds of one day
const int SECONDS_OF_YEAR = 365 * 24 * 60 * 60; // seconds of one year

const relay_chain_kusama = 'kusama';
const relay_chain_polkadot = 'polkadot';
const network_name_statemine = 'statemine';
const network_name_statemint = 'statemint';
const network_name_westmint = 'westmint';
const network_name_karura = 'karura';

const plugin_node_list = {
  network_name_statemine: [
    {
      'name': 'Statemine (hosted by Parity)',
      'ss58': 2,
      'endpoint': 'wss://kusama-statemine-rpc.paritytech.net',
    },
    {
      'name': 'Statemine (hosted by onfinality)',
      'ss58': 2,
      'endpoint': 'wss://statemine.api.onfinality.io/public-ws',
    },
    {
      'name': 'Statemine (hosted by dwellir)',
      'ss58': 2,
      'endpoint': 'wss://statemine-rpc.dwellir.com',
    },
    {
      'name': 'Statemine (hosted by pinknode)',
      'ss58': 2,
      'endpoint': 'wss://public-rpc.pinknode.io/statem',
    },
    // {
    //   'name': 'Westmint (hosted by Parity)',
    //   'ss58': 42,
    //   'endpoint': 'wss://westmint-rpc.polkadot.io',
    // },
  ],
  network_name_statemint: [
    {
      'name': 'Statemint (hosted by Parity)',
      'ss58': 0,
      'endpoint': 'wss://statemint-rpc.polkadot.io',
    },
    {
      'name': 'Statemint (hosted by onfinality)',
      'ss58': 0,
      'endpoint': 'wss://statemint.api.onfinality.io/publi',
    },
    {
      'name': 'Statemint (hosted by dwellir)',
      'ss58': 0,
      'endpoint': 'wss://statemint-rpc.dwellir.com',
    },
    {
      'name': 'Statemint (hosted by pinknode)',
      'ss58': 0,
      'endpoint': 'wss://public-rpc.pinknode.io/statemi',
    },
  ],
};

const plugin_genesis_hash = {
  network_name_statemine:
      '0x48239ef607d7928874027a43a67689209727dfb3d3dc5e5b03a39bdc2eda771a',
  network_name_statemint:
      '0x48239ef607d7928874027a43a67689209727dfb3d3dc5e5b03a39bdc2eda771a',
};

const plugin_ss58_format = {
  relay_chain_kusama: 2,
  relay_chain_polkadot: 0,
  network_name_statemine: 2,
  network_name_statemint: 0,
  network_name_westmint: 42,
  network_name_karura: 8,
};

const xcm_dest_weight_kusama = '3000000000';
const xcm_dest_weight_karura = '600000000';
const xcm_dest_weight_v2 = '5000000000';

const image_assets_uri = 'packages/polkawallet_plugin_statemine/assets/images';
const relay_chain_token_symbol = 'KSM';
const foreign_token_symbol_RMRK = 'RMRK';
const foreign_token_symbol_ARIS = 'ARIS';
const config_xcm = {
  'xcm': {
    '8': [network_name_karura],
    '16': [network_name_karura],
  },
  'xcmInfo': {
    network_name_karura: {
      foreign_token_symbol_RMRK: {
        'fee': '6400000',
        'existentialDeposit': '100000000',
      },
      foreign_token_symbol_ARIS: {
        'fee': '6400000',
        'existentialDeposit': "10000000",
      }
    },
  },
  'xcmChains': {
    network_name_statemine: {'id': '1000', 'ss58': 2},
    network_name_karura: {'id': '2000', 'ss58': 8}
  }
};

const module_name_assets = 'assets';
const module_name_defi = 'defi';
const config_modules = {
  module_name_assets: {
    'visible': true,
    'enabled': true,
  },
  module_name_defi: {
    'visible': false,
    'enabled': true,
    'items': {"loan": false, "swap": true, "earn": true}
  },
};

const plugin_primary_color = {
  network_name_statemine: MaterialColor(0xFF057AA9, {
    50: Color(0xFF057AA9),
    100: Color(0xFF057AA9),
    200: Color(0xFF057AA9),
    300: Color(0xFF057AA9),
    400: Color(0xFF057AA9),
    500: Color(0xFF057AA9),
    600: Color(0xFF057AA9),
    700: Color(0xFF057AA9),
    800: Color(0xFF057AA9),
    900: Color(0xFF057AA9)
  }),
  network_name_statemint: MaterialColor(0xFF3DB36A, {
    50: Color(0xFF3DB36A),
    100: Color(0xFF3DB36A),
    200: Color(0xFF3DB36A),
    300: Color(0xFF3DB36A),
    400: Color(0xFF3DB36A),
    500: Color(0xFF3DB36A),
    600: Color(0xFF3DB36A),
    700: Color(0xFF3DB36A),
    800: Color(0xFF3DB36A),
    900: Color(0xFF3DB36A)
  }),
};

const plugin_gradient_color = {
  network_name_statemine: Color(0xFF3CD3A0),
  network_name_statemint: Color(0xFF90CD55),
};

const plugin_cache_key = {
  network_name_statemine: 'plugin_statemine',
  network_name_statemint: 'plugin_statemint',
};
