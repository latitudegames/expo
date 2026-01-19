package expo.modules.updates.selectionpolicy

import expo.modules.updates.UpdatesConfiguration
import expo.modules.updates.db.entity.UpdateEntity
import org.json.JSONObject

/**
 * LauncherSelectionPolicy which chooses an update to launch based on the manifest filters
 * provided by the server. If multiple updates meet the criteria, the newest one (using `commitTime`
 * for ordering) is chosen, but the manifest filters are always taken into account before the
 * `commitTime`.
 *
 * Additionally filters by channel/branch to ensure channel-specific updates are
 * selected when a runtime configuration override is in effect.
 */
class LauncherSelectionPolicyFilterAware(
  private val runtimeVersion: String,
  private val config: UpdatesConfiguration?,
  private val filterByChannel: Boolean = false  // Only true when actively switching channels
) : LauncherSelectionPolicy {

  override fun selectUpdateToLaunch(
    updates: List<UpdateEntity>,
    filters: JSONObject?
  ): UpdateEntity? {
    // Filter by runtime version and manifest filters first
    val eligibleUpdates = updates.filter { 
      runtimeVersion == it.runtimeVersion && SelectionPolicies.matchesFilters(it, filters) 
    }

    // Only apply channel filtering when explicitly requested (during channel switching)
    if (!filterByChannel) {
      return eligibleUpdates.maxByOrNull { it.commitTime }
    }

    // Get the target channel from config request headers
    val targetChannel = config?.requestHeaders?.get("expo-channel-name")
    if (targetChannel == null) {
      return eligibleUpdates.maxByOrNull { it.commitTime }
    }

    // Filter by channel when switching environments
    val channelFilteredUpdates = eligibleUpdates.filter { update ->
      // Try to extract the branch/channel from the update's manifest
      val manifest = update.manifest
      val updateBranch = manifest.optString("branch", null)
        ?: manifest.optJSONObject("extra")?.optJSONObject("expoClient")?.optJSONObject("extra")?.optString("LATITUDE_RELEASE_STAGE", null)

      // If update has no branch info, it's an embedded or legacy update - accept it
      if (updateBranch == null) return@filter true

      // Only accept updates that match the target channel
      updateBranch == targetChannel
    }

    // If channel filtering removed all updates, fall back to non-filtered selection
    // This handles the case where the server returned updates from a different channel
    if (channelFilteredUpdates.isEmpty()) {
      return eligibleUpdates.maxByOrNull { it.commitTime }
    }

    return channelFilteredUpdates.maxByOrNull { it.commitTime }
  }
}
