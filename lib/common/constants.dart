import 'package:flutter/material.dart';

const int SECONDS_OF_DAY = 24 * 60 * 60; // seconds of one day
const int SECONDS_OF_YEAR = 365 * 24 * 60 * 60; // seconds of one year

const network_name_statemine = 'statemine';
const network_name_statemint = 'statemint';

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
  ],
  network_name_statemint: [],
};

const plugin_genesis_hash = {
  network_name_statemine:
      '0x48239ef607d7928874027a43a67689209727dfb3d3dc5e5b03a39bdc2eda771a',
  network_name_statemint:
      '0x48239ef607d7928874027a43a67689209727dfb3d3dc5e5b03a39bdc2eda771a',
};

const plugin_ss58_format = {
  network_name_statemine: 2,
  network_name_statemint: 0,
};

const plugin_primary_color = {
  network_name_statemine: Colors.teal,
  network_name_statemint: Colors.green,
};

const plugin_gradient_color = {
  network_name_statemine: Colors.green,
  network_name_statemint: Colors.lightGreen,
};

const plugin_cache_key = {
  network_name_statemine: 'plugin_statemine',
  network_name_statemint: 'plugin_statemint',
};
