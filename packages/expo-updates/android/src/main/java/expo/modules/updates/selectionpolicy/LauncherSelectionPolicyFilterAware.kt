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
 * Additionally filters by updateUrl and requestHeaders to ensure channel-specific updates are
 * selected when a runtime configuration override is in effect.
 */
class LauncherSelectionPolicyFilterAware(
  private val runtimeVersion: String,
  private val config: UpdatesConfiguration?
) : LauncherSelectionPolicy {

  override fun selectUpdateToLaunch(
    updates: List<UpdateEntity>,
    filters: JSONObject?
  ): UpdateEntity? =
    updates
      .filter { runtimeVersion == it.runtimeVersion && SelectionPolicies.matchesFilters(it, filters) }
      .filter { update ->
        // If no config is provided, accept all updates (backwards compatibility)
        if (config == null) return@filter true
        // If update has no url/headers stored, it's an embedded or legacy update - accept it
        if (update.url == null && update.requestHeaders == null) return@filter true
        // Otherwise, only accept updates that match the current config
        update.url == config.updateUrl && update.requestHeaders == config.requestHeaders
      }
      .maxByOrNull { it.commitTime }
}
