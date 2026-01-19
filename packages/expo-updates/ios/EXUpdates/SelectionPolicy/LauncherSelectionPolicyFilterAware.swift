//  Copyright © 2019 650 Industries. All rights reserved.

import Foundation

/**
 * A LauncherSelectionPolicy which chooses an update to launch based on the manifest
 * filters provided by the server. If multiple updates meet the criteria, the newest one (using
 * `commitTime` for ordering) is chosen, but the manifest filters are always taken into account
 * before the `commitTime`.
 *
 * Additionally filters by updateUrl and requestHeaders to ensure channel-specific updates are
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
    return updates
      .filter { runtimeVersion == $0.runtimeVersion && SelectionPolicies.doesUpdate($0, matchFilters: filters) }
      .filter { update in
        // If no config is provided, accept all updates (backwards compatibility)
        guard let config = config else { return true }
        // If update has no url/headers stored, it's an embedded or legacy update - accept it
        if update.url == nil && update.requestHeaders == nil { return true }
        // Otherwise, only accept updates that match the current config
        return update.url == config.updateUrl && update.requestHeaders == config.requestHeaders
      }
      .sorted { $0.commitTime > $1.commitTime }.first
  }
}
