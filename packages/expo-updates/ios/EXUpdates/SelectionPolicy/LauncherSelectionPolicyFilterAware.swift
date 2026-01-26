//  Copyright © 2019 650 Industries. All rights reserved.

import Foundation

/**
 * A LauncherSelectionPolicy which chooses an update to launch based on the manifest
 * filters provided by the server. If multiple updates meet the criteria, the newest one (using
 * `commitTime` for ordering) is chosen, but the manifest filters are always taken into account
 * before the `commitTime`.
 *
 * Additionally filters by channel/branch to ensure channel-specific updates are
 * selected when a runtime configuration override is in effect.
 */
@objc(EXUpdatesLauncherSelectionPolicyFilterAware)
@objcMembers
public final class LauncherSelectionPolicyFilterAware: NSObject, LauncherSelectionPolicy {
  let runtimeVersion: String
  private let config: UpdatesConfig?
  private let filterByChannel: Bool  // Only true when actively switching channels

  public required init(runtimeVersion: String, config: UpdatesConfig? = nil, filterByChannel: Bool = false) {
    self.runtimeVersion = runtimeVersion
    self.config = config
    self.filterByChannel = filterByChannel
  }

  public func launchableUpdate(fromUpdates updates: [Update], filters: [String: Any]?) -> Update? {
    NSLog("[ChannelSwitch] launchableUpdate called")
    NSLog("[ChannelSwitch] filterByChannel: \(filterByChannel)")
    NSLog("[ChannelSwitch] config.requestHeaders: \(String(describing: config?.requestHeaders))")
    NSLog("[ChannelSwitch] config.disableAntiBrickingMeasures: \(String(describing: config?.disableAntiBrickingMeasures))")
    NSLog("[ChannelSwitch] total updates: \(updates.count)")
    
    // Filter by runtime version and manifest filters first
    let eligibleUpdates = updates.filter { 
      runtimeVersion == $0.runtimeVersion && SelectionPolicies.doesUpdate($0, matchFilters: filters) 
    }
    NSLog("[ChannelSwitch] eligible updates after runtime filter: \(eligibleUpdates.count)")

    // Only apply channel filtering when explicitly requested (during channel switching)
    guard filterByChannel else {
      let selected = eligibleUpdates.sorted { $0.commitTime > $1.commitTime }.first
      NSLog("[ChannelSwitch] filterByChannel is false, selecting by commitTime: \(String(describing: selected?.updateId))")
      return selected
    }

    // Get the target channel from config request headers
    guard let targetChannel = config?.requestHeaders["expo-channel-name"] else {
      let selected = eligibleUpdates.sorted { $0.commitTime > $1.commitTime }.first
      NSLog("[ChannelSwitch] targetChannel is nil, selecting by commitTime: \(String(describing: selected?.updateId))")
      return selected
    }
    NSLog("[ChannelSwitch] targetChannel from config: \(targetChannel)")

    // Filter by channel when switching environments
    let channelFilteredUpdates = eligibleUpdates.filter { update in
      // Try to extract the branch/channel from the update's manifest
      let rawManifest = update.manifest.rawManifestJSON()
      let updateBranch: String? = {
        // First try direct "branch" field
        if let branch = rawManifest["branch"] as? String {
          return branch
        }
        // Then try nested path: extra.expoClient.extra.LATITUDE_RELEASE_STAGE
        if let extra = rawManifest["extra"] as? [String: Any],
           let expoClient = extra["expoClient"] as? [String: Any],
           let expoClientExtra = expoClient["extra"] as? [String: Any],
           let stage = expoClientExtra["LATITUDE_RELEASE_STAGE"] as? String {
          return stage
        }
        return nil
      }()
      
      NSLog("[ChannelSwitch] update \(update.updateId) branch: \(String(describing: updateBranch)), target: \(targetChannel)")

      // If update has no branch info, it's an embedded or legacy update - accept it
      guard let updateBranch = updateBranch else { return true }

      // Only accept updates that match the target channel
      return updateBranch == targetChannel
    }

    NSLog("[ChannelSwitch] channel filtered updates: \(channelFilteredUpdates.count)")

    // If channel filtering removed all updates, fall back to non-filtered selection
    // This handles the case where the server returned updates from a different channel
    if channelFilteredUpdates.isEmpty {
      let selected = eligibleUpdates.sorted { $0.commitTime > $1.commitTime }.first
      NSLog("[ChannelSwitch] no channel matches, fallback to commitTime: \(String(describing: selected?.updateId))")
      return selected
    }

    let selected = channelFilteredUpdates.sorted { $0.commitTime > $1.commitTime }.first
    NSLog("[ChannelSwitch] selected update: \(String(describing: selected?.updateId)) with branch matching \(targetChannel)")
    return selected
  }
}
