//  Copyright © 2019 650 Industries. All rights reserved.

import Foundation

/**
 * Factory class to ease the construction of [SelectionPolicy] objects whose three methods all use
 * the same ordering policy.
 */
@objc(EXUpdatesSelectionPolicyFactory)
@objcMembers
public final class SelectionPolicyFactory: NSObject {
  public static func filterAwarePolicy(
    withRuntimeVersion runtimeVersion: String, 
    config: UpdatesConfig? = nil,
    filterByChannel: Bool = false
  ) -> SelectionPolicy {
    // When disableAntiBrickingMeasures is enabled, pass it to the loader selection policy
    // to allow loading updates with older commit times (needed for channel switching)
    let disableAntiBrickingMeasures = config?.disableAntiBrickingMeasures ?? false
    return SelectionPolicy.init(
      launcherSelectionPolicy: LauncherSelectionPolicyFilterAware.init(runtimeVersion: runtimeVersion, config: config, filterByChannel: filterByChannel),
      loaderSelectionPolicy: LoaderSelectionPolicyFilterAware(disableAntiBrickingMeasures: disableAntiBrickingMeasures),
      reaperSelectionPolicy: ReaperSelectionPolicyFilterAware()
    )
  }
}
