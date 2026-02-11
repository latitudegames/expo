//  Copyright © 2019 650 Industries. All rights reserved.

import Foundation

/**
 * Factory class to ease the construction of [SelectionPolicy] objects whose three methods all use
 * the same ordering policy.
 */
@objc(EXUpdatesSelectionPolicyFactory)
@objcMembers
public final class SelectionPolicyFactory: NSObject {
  public static func filterAwarePolicy(withRuntimeVersion runtimeVersion: String, config: UpdatesConfig, filterByChannel: Bool = false) -> SelectionPolicy {
    return SelectionPolicy.init(
      launcherSelectionPolicy: LauncherSelectionPolicyFilterAware.init(runtimeVersion: runtimeVersion, filterByChannel: filterByChannel, config: config),
      loaderSelectionPolicy: LoaderSelectionPolicyFilterAware(disableAntiBrickingMeasures: config.disableAntiBrickingMeasures),
      reaperSelectionPolicy: ReaperSelectionPolicyFilterAware()
    )
  }
}
