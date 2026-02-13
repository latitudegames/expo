//  Copyright © 2019 650 Industries. All rights reserved.

import Foundation

/**
 * A LauncherSelectionPolicy which chooses an update to launch based on the manifest
 * filters provided by the server. If multiple updates meet the criteria, the newest one (using
 * `commitTime` for ordering) is chosen, but the manifest filters are always taken into account
 * before the `commitTime`.
 */
@objc(EXUpdatesLauncherSelectionPolicyFilterAware)
@objcMembers
public final class LauncherSelectionPolicyFilterAware: NSObject, LauncherSelectionPolicy {
  let runtimeVersion: String
  private let filterByChannel: Bool
  private let config: UpdatesConfig?

  public required init(runtimeVersion: String, filterByChannel: Bool = false, config: UpdatesConfig? = nil) {
    self.runtimeVersion = runtimeVersion
    self.filterByChannel = filterByChannel
    self.config = config
  }

  public func launchableUpdate(fromUpdates updates: [Update], filters: [String: Any]?) -> Update? {
    let matchingUpdates = updates
      .filter { runtimeVersion == $0.runtimeVersion && SelectionPolicies.doesUpdate($0, matchFilters: filters) }
      .filter { update in
        guard let config = config else {
          return true
        }
        return (update.url == nil && update.requestHeaders == nil) || (update.url == config.updateUrl && update.requestHeaders == config.requestHeaders)
      }

    if filterByChannel, let configuredChannelName = channelNameFromConfig(), !configuredChannelName.isEmpty {
      NSLog("[ChannelSwitch] Filtering updates for channel %@", configuredChannelName)
      let channelFilteredUpdates = matchingUpdates.filter { update in
        guard let updateChannel = channelName(for: update) else {
          return false
        }
        return updateChannel == configuredChannelName
      }

      if !channelFilteredUpdates.isEmpty {
        NSLog("[ChannelSwitch] Found %d updates matching channel %@", channelFilteredUpdates.count, configuredChannelName)
        return channelFilteredUpdates.sorted { $0.commitTime > $1.commitTime }.first
      }

      NSLog("[ChannelSwitch] No updates matched channel %@; falling back to unfiltered selection", configuredChannelName)
    }

    return matchingUpdates.sorted { $0.commitTime > $1.commitTime }.first
  }

  private func channelNameFromConfig() -> String? {
    guard let requestHeaders = config?.requestHeaders else {
      return nil
    }
    return requestHeaders.first(where: { $0.key.lowercased() == "expo-channel-name" })?.value
  }

  private func channelName(for update: Update) -> String? {
    let rawManifest = update.manifest.rawManifestJSON()
    if let branch = rawManifest["branch"] as? String {
      return branch
    }
    if let extra = rawManifest["extra"] as? [String: Any],
      let expoClient = extra["expoClient"] as? [String: Any],
      let expoClientExtra = expoClient["extra"] as? [String: Any],
      let latitudeStage = expoClientExtra["LATITUDE_RELEASE_STAGE"] as? String {
      return latitudeStage
    }
    return nil
  }
}
