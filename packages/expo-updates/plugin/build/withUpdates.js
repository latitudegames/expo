'use strict';
Object.defineProperty(exports, '__esModule', { value: true });
const pkg = require('@latitudegames/expo-updates/package.json');
const config_plugins_1 = require('expo/config-plugins');
// when making changes to this config plugin, ensure the same changes are also made in eas-cli and build-tools
const withUpdates = (config) => {
  config = config_plugins_1.AndroidConfig.Updates.withUpdates(config);
  config = config_plugins_1.IOSConfig.Updates.withUpdates(config);
  return config;
};
exports.default = (0, config_plugins_1.createRunOncePlugin)(withUpdates, pkg.name, pkg.version);
