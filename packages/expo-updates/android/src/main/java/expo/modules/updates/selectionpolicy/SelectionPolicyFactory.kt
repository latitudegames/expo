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
    return SelectionPolicy(
      LauncherSelectionPolicyFilterAware(runtimeVersion, config, filterByChannel),
      LoaderSelectionPolicyFilterAware(),
      ReaperSelectionPolicyFilterAware()
    )
  }
}
