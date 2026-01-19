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

  public required init(runtimeVersion: String, config: UpdatesConfig? = nil) {
    self.runtimeVersion = runtimeVersion
    self.config = config
  }

  public func launchableUpdate(fromUpdates updates: [Update], filters: [String: Any]?) -> Update? {
    // Get the target channel from config request headers
    let targetChannel = config?.requestHeaders["expo-channel-name"]

    return updates
      .filter { runtimeVersion == $0.runtimeVersion && SelectionPolicies.doesUpdate($0, matchFilters: filters) }
      .filter { update in
        // If no target channel is configured, accept all updates (backwards compatibility)
        guard let targetChannel = targetChannel else { return true }

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

        // If update has no branch info, it's an embedded or legacy update - accept it
        guard let updateBranch = updateBranch else { return true }

        // Only accept updates that match the target channel
        return updateBranch == targetChannel
      }
      .sorted { $0.commitTime > $1.commitTime }.first
  }
}
