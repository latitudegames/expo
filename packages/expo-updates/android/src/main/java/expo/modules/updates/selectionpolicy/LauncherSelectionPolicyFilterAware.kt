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
    android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] selectUpdateToLaunch called")
    android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] filterByChannel: $filterByChannel")
    android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] config.requestHeaders: ${config?.requestHeaders}")
    android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] config.disableAntiBrickingMeasures: ${config?.disableAntiBrickingMeasures}")
    android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] total updates: ${updates.size}")
    
    // Filter by runtime version and manifest filters first
    val eligibleUpdates = updates.filter { 
      runtimeVersion == it.runtimeVersion && SelectionPolicies.matchesFilters(it, filters) 
    }
    android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] eligible updates after runtime filter: ${eligibleUpdates.size}")

    // Only apply channel filtering when explicitly requested (during channel switching)
    if (!filterByChannel) {
      val selected = eligibleUpdates.maxByOrNull { it.commitTime }
      android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] filterByChannel is false, selecting by commitTime: ${selected?.id}")
      return selected
    }

    // Get the target channel from config request headers
    val targetChannel = config?.requestHeaders?.get("expo-channel-name")
    android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] targetChannel from config: $targetChannel")
    if (targetChannel == null) {
      val selected = eligibleUpdates.maxByOrNull { it.commitTime }
      android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] targetChannel is null, selecting by commitTime: ${selected?.id}")
      return selected
    }

    // Filter by channel when switching environments
    val channelFilteredUpdates = eligibleUpdates.filter { update ->
      // Try to extract the branch/channel from the update's manifest
      val manifest = update.manifest
      val updateBranch = manifest.optString("branch", null)
        ?: manifest.optJSONObject("extra")?.optJSONObject("expoClient")?.optJSONObject("extra")?.optString("LATITUDE_RELEASE_STAGE", null)
      
      android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] update ${update.id} branch: $updateBranch, target: $targetChannel")

      // If update has no branch info, it's an embedded or legacy update - accept it
      if (updateBranch == null) return@filter true

      // Only accept updates that match the target channel
      updateBranch == targetChannel
    }

    android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] channel filtered updates: ${channelFilteredUpdates.size}")

    // If channel filtering removed all updates, fall back to non-filtered selection
    // This handles the case where the server returned updates from a different channel
    if (channelFilteredUpdates.isEmpty()) {
      val selected = eligibleUpdates.maxByOrNull { it.commitTime }
      android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] no channel matches, fallback to commitTime: ${selected?.id}")
      return selected
    }

    val selected = channelFilteredUpdates.maxByOrNull { it.commitTime }
    android.util.Log.d("LauncherSelectionPolicy", "[ChannelSwitch] selected update: ${selected?.id} with branch matching $targetChannel")
    return selected
  }
}
