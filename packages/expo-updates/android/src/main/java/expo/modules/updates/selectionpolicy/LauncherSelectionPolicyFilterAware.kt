package expo.modules.updates.selectionpolicy

import android.util.Log
import expo.modules.updates.UpdatesConfiguration
import expo.modules.updates.db.entity.UpdateEntity
import org.json.JSONObject

/**
 * LauncherSelectionPolicy which chooses an update to launch based on the manifest filters
 * provided by the server. If multiple updates meet the criteria, the newest one (using `commitTime`
 * for ordering) is chosen, but the manifest filters are always taken into account before the
 * `commitTime`.
 */
class LauncherSelectionPolicyFilterAware(
  private val runtimeVersion: String,
  private val filterByChannel: Boolean = false,
  private val config: UpdatesConfiguration? = null
) : LauncherSelectionPolicy {

  override fun selectUpdateToLaunch(
    updates: List<UpdateEntity>,
    filters: JSONObject?
  ): UpdateEntity? =
    run {
      val matchingUpdates = updates
        .filter { runtimeVersion == it.runtimeVersion && SelectionPolicies.matchesFilters(it, filters) }
        .filter { update ->
          val config = config ?: return@filter true
          (update.url == null && update.requestHeaders == null) || (update.url == config.updateUrl && update.requestHeaders == config.requestHeaders)
        }

      val channelName = channelNameFromConfig()
      if (filterByChannel && !channelName.isNullOrBlank()) {
        Log.d(TAG, "[ChannelSwitch] Filtering updates for channel $channelName")
        val channelFilteredUpdates = matchingUpdates.filter { update ->
          val updateChannel = channelNameForUpdate(update)
          updateChannel != null && updateChannel == channelName
        }
        if (channelFilteredUpdates.isNotEmpty()) {
          Log.d(TAG, "[ChannelSwitch] Found ${channelFilteredUpdates.size} updates matching channel $channelName")
          return@run channelFilteredUpdates.maxByOrNull { it.commitTime }
        }
        Log.d(TAG, "[ChannelSwitch] No updates matched channel $channelName; falling back to unfiltered selection")
      }

      matchingUpdates.maxByOrNull { it.commitTime }
    }

  private fun channelNameFromConfig(): String? {
    val requestHeaders = config?.requestHeaders ?: return null
    return requestHeaders.entries.firstOrNull { it.key.equals("expo-channel-name", ignoreCase = true) }?.value
  }

  private fun channelNameForUpdate(update: UpdateEntity): String? {
    val manifest = update.manifest
    if (manifest.has("branch")) {
      val branch = manifest.optString("branch", null)
      if (!branch.isNullOrEmpty()) {
        return branch
      }
    }
    val extra = manifest.optJSONObject("extra")
    val expoClient = extra?.optJSONObject("expoClient")
    val expoClientExtra = expoClient?.optJSONObject("extra")
    if (expoClientExtra?.has("LATITUDE_RELEASE_STAGE") == true) {
      val stage = expoClientExtra.optString("LATITUDE_RELEASE_STAGE", null)
      if (!stage.isNullOrEmpty()) {
        return stage
      }
    }
    return null
  }

  private companion object {
    private const val TAG = "ExpoUpdates"
  }
}
