package expo.modules.updates.selectionpolicy

import expo.modules.updates.UpdatesConfiguration

/**
 * Factory class to ease the construction of [SelectionPolicy] objects whose three methods all use
 * the same ordering policy.
 */
object SelectionPolicyFactory {
  @JvmStatic fun createFilterAwarePolicy(
    runtimeVersion: String, 
    config: UpdatesConfiguration? = null,
    filterByChannel: Boolean = false
  ): SelectionPolicy {
    // When disableAntiBrickingMeasures is enabled, pass it to the loader selection policy
    // to allow loading updates with older commit times (needed for channel switching)
    val disableAntiBrickingMeasures = config?.disableAntiBrickingMeasures ?: false
    return SelectionPolicy(
      LauncherSelectionPolicyFilterAware(runtimeVersion, config, filterByChannel),
      LoaderSelectionPolicyFilterAware(disableAntiBrickingMeasures),
      ReaperSelectionPolicyFilterAware()
    )
  }
}
