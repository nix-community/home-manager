# Idempotent Home Manager activation for Firefox selectable profiles.
# Usage: nu --no-config-file sync-selectable.nu <manifest.json> [prepare-legacy-ini]
# The manifest comes from mkFirefoxModule.nix; never interpolate user data into SQL.

def ini-value [section: record, key: string] {
  let prefix = $"($key)="
  let matches = ($section.lines | where {|line| $line | str starts-with $prefix })
  if ($matches | is-empty) {
    null
  } else {
    let line = ($matches | first)
    $line | str replace $prefix ''
  }
}

def ini-set [section: record, key: string, value: string] {
  let prefix = $"($key)="
  let other = ($section.lines | where {|line| not ($line | str starts-with $prefix) })
  $section | upsert lines ($other | append $"($key)=($value)")
}

def ini-remove [section: record, key: string] {
  let prefix = $"($key)="
  $section | upsert lines ($section.lines | where {|line| not ($line | str starts-with $prefix) })
}

def read-ini [file: string] {
  mut result = []
  mut current = {name: "", lines: []}
  if ($file | path exists) {
    for line in (open --raw $file | lines) {
      if (($line | str starts-with "[") and ($line | str ends-with "]")) {
        $result = ($result | append $current)
        $current = {name: ($line | str substring 1..-2), lines: []}
      } else {
        $current = ($current | upsert lines ($current.lines | append $line))
      }
    }
  }
  $result | append $current
}

def write-ini [file: string, sections: list] {
  mut text = ""
  for section in $sections {
    if ($section.name == "" and ($section.lines | is-empty)) { continue }
    if $section.name != "" {
      $text = $text + $"[($section.name)]\n"
    }
    let body = ($section.lines | str join "\n" | str trim --right)
    if $body != "" { $text = $text + $body + "\n" }
    $text = $text + "\n"
  }
  # Avoid unnecessary writes, but always replace an old Home Manager symlink.
  if (($file | path type) == 'file' and (open --raw $file) == $text) {
    return
  }
  # Replace the inode (not the content of a pre-existing Home Manager symlink).
  # Firefox must be able to update this file when switching profiles.
  let temporary = $"($file).tmp.((random uuid))"
  $text | save --force $temporary
  mv --force $temporary $file
}

# Ownership is tracked outside Firefox's database so a profile created in
# Firefox is not confused with one formerly declared in Nix.  The initial
# activation records the currently declared paths as a baseline; it does not
# assume that every pre-existing SQLite row is Nix-managed.
def read-state [file: string] {
  if not ($file | path exists) {
    return {version: 1, groups: []}
  }
  let state = (open $file)
  if $state.version != 1 {
    error make {msg: 'Unsupported Home Manager selectable-profile state version'}
  }
  for group in $state.groups {
    if not ($group.storeId =~ '^[0-9a-f]{8}$') {
      error make {msg: 'Invalid store ID in Home Manager selectable-profile state'}
    }
  }
  $state
}

def write-state [file: string, groups: list] {
  # A missing marker means there is no previous Home Manager ownership.
  if ($groups | is-empty) {
    if ($file | path exists) { rm $file }
    return
  }
  let state = {
    version: 1
    groups: ($groups | each {|group|
      {storeId: $group.storeId, paths: ($group.profiles | each {|profile| $profile.path })}
    })
  }
  let text = ($state | to json)
  if (($file | path type) == 'file' and (open --raw $file) == $text) { return }
  let temporary = $"($file).tmp.((random uuid))"
  $text | save --force $temporary
  mv --force $temporary $file
}

# SQLite Profiles/SharedPrefs schemas, user_version migrations, and per-StoreID
# database location come from Mozilla's ProfilesDatastoreService (pinned):
# https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/toolkit/profile/ProfilesDatastoreService.sys.mjs
# SharedPrefs boolean encoding and profile upsert columns match Firefox's
# SelectableProfileService: https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/browser/components/profiles/SelectableProfileService.sys.mjs
def sync-database [directory: string, group: record, previouslyManaged: list, removeUnmanaged: bool] {
  let file = ([$directory 'Profile Groups' $"($group.storeId).sqlite"] | path join)
  # Removing a whole group must not recreate a previously deleted database.
  if not ($file | path exists) {
    if ($group.profiles | is-empty) { return [] }
    mkdir ($file | path dirname)
    # Nushell `open` recognizes SQLite by its header. Seed a new file first.
    {home_manager_init: 1} | into sqlite $file --table-name HomeManagerInit
    open $file | query db 'DROP TABLE HomeManagerInit;'
  }

  open $file | query db 'CREATE TABLE IF NOT EXISTS "Profiles" (
    id INTEGER NOT NULL PRIMARY KEY,
    path TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    avatar TEXT NOT NULL,
    themeId TEXT NOT NULL,
    themeFg TEXT NOT NULL,
    themeBg TEXT NOT NULL
  );'
  open $file | query db 'CREATE TABLE IF NOT EXISTS "SharedPrefs" (
    id INTEGER NOT NULL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    value BLOB,
    isBoolean INTEGER
  );'
  # New stores start at schema version 1. Firefox migrates 1 -> current
  # when it first opens the database; never downgrade an existing store.
  let version = (open $file | query db 'PRAGMA user_version;' | get 0.user_version)
  if $version == 0 {
    open $file | query db 'PRAGMA user_version = 1;'
  }

  let desired = ($group.profiles | each {|profile| $profile.path })
  let existing = (open $file | query db 'SELECT path FROM "Profiles";' | get path)
  # Default convergence deletes *only* previously owned paths that disappeared
  # from the desired state. Opt-in strict mode additionally unregisters Firefox-
  # created profiles within groups managed now or in the previous generation.
  let deletions = if $removeUnmanaged {
    $existing | where {|path| not ($path in $desired) }
  } else {
    $previouslyManaged | where {|path| not ($path in $desired) }
  }
  for path in $deletions {
    let reason = if $path in $previouslyManaged { 'previously managed' } else { 'unmanaged' }
    print $"Home Manager: unregistering ($reason) Firefox profile '($path)' from StoreID ($group.storeId)"
    open $file | query db 'DELETE FROM "Profiles" WHERE path = ?;' --params [$path]
  }

  for profile in $group.profiles {
    open $file | query db 'INSERT INTO "Profiles"
      (path, name, avatar, themeId, themeFg, themeBg)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(path) DO UPDATE SET
        name = excluded.name, avatar = excluded.avatar,
        themeId = excluded.themeId, themeFg = excluded.themeFg,
        themeBg = excluded.themeBg;' --params [$profile.path $profile.name $profile.avatar $profile.themeId $profile.themeFg $profile.themeBg]
  }
  for pref in $group.sharedSettings {
    open $file | query db 'INSERT INTO "SharedPrefs" (name, value, isBoolean)
      VALUES (?, ?, ?)
      ON CONFLICT(name) DO UPDATE SET
        value = excluded.value, isBoolean = excluded.isBoolean;' --params [$pref.name $pref.value $pref.isBoolean]
  }
  # Return surviving Firefox-created profiles too: profiles.ini may be pointing
  # to any one of them and should preserve that choice when still valid.
  open $file | query db 'SELECT path FROM "Profiles" ORDER BY id;' | get path
}

# Firefox uses one toolkit profiles.ini entry per selectable profile group
# (StoreID, Path, ShowSelector). The active profile may change the group's Path.
# Upstream: https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/browser/components/profiles/SelectableProfileService.sys.mjs
# Toolkit profiles.ini serialization: https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/toolkit/profile/nsToolkitProfileService.cpp
def sync-ini [root: string, manifest: record, allGroupPaths: list, priorState: record] {
  let file = ([$root 'profiles.ini'] | path join)
  let existing = (read-ini $file)
  let profileSections = ($existing | where {|s| $s.name =~ '^Profile[0-9]+$' })
  let nonProfiles = ($existing | where {|s| $s.name !~ '^Profile[0-9]+$' })
  mut remaining = $profileSections
  mut managed = []
  mut managedPaths = []
  mut touchedPaths = ($priorState.groups | each {|g| $g.paths } | flatten)
  mut currentPath = ""

  for entry in $allGroupPaths {
    let group = $entry.group
    let found = ($remaining | where {|s| (ini-value $s 'StoreID') == $group.storeId })
    $remaining = ($remaining | where {|s| (ini-value $s 'StoreID') != $group.storeId })
    if not ($found | is-empty) {
      let oldPath = (ini-value ($found | first) 'Path')
      if $oldPath != null { $touchedPaths = ($touchedPaths | append $oldPath) }
    }
    if ($entry.paths | is-empty) { continue }
    # If a formerly managed group still contains Firefox-created profiles,
    # preserve its old toolkit entry instead of inventing a new one.
    if not $group.configured and ($found | is-empty) { continue }

    let base = if ($found | is-empty) { {name: '', lines: []} } else { $found | first }
    let priorPath = (ini-value $base 'Path')
    let fallback = if ($group.defaultPath != null and $group.defaultPath in $entry.paths) {
      $group.defaultPath
    } else {
      $entry.paths | first
    }
    let path = if ($priorPath != null and $priorPath in $entry.paths) { $priorPath } else { $fallback }
    mut section = (ini-set $base 'Path' $path)
    $section = (ini-set $section 'IsRelative' '1')
    $section = (ini-set $section 'StoreID' $group.storeId)
    if $group.configured {
      $section = (ini-set $section 'Name' $group.name)
      $section = (ini-set $section 'ShowSelector' (if $group.showSelector { '1' } else { '0' }))
    }
    $managed = ($managed | append $section)
    $managedPaths = ($managedPaths | append $entry.paths)
    if $group.storeId == $manifest.currentStoreId { $currentPath = $path }
  }

  for profile in $manifest.legacyProfiles {
    let found = ($remaining | where {|s|
      (ini-value $s 'StoreID') == null and (ini-value $s 'Path') == $profile.path
    })
    let base = if ($found | is-empty) { {name: '', lines: []} } else { $found | first }
    if not ($found | is-empty) {
      let prevName = $base.name
      $remaining = ($remaining | where {|s| $s.name != $prevName })
    }
    mut section = (ini-set $base 'Name' $profile.name)
    $section = (ini-set $section 'Path' $profile.path)
    $section = (ini-set $section 'IsRelative' '1')
    $section = (ini-remove $section 'StoreID')
    $section = (ini-remove $section 'ShowSelector')
    $managed = ($managed | append $section)
    $managedPaths = ($managedPaths | append $profile.path)
  }

  # A group that was removed from Nix may have been the previous default.
  # Choose another existing profile, or clear the stale install default when
  # nothing remains. Never point to an unregistered profile path.
  let candidates = ($remaining | append $managed)
  if $currentPath == "" {
    let defaults = ($candidates | where {|s| (ini-value $s 'Default') == '1' })
    if not ($defaults | is-empty) {
      $currentPath = ((ini-value ($defaults | first) 'Path') | default '')
    } else if not ($candidates | is-empty) {
      $currentPath = ((ini-value ($candidates | first) 'Path') | default '')
    }
  }

  # Nushell closures cannot capture mutable variables. Snapshot the selected
  # profile path after all updates, before enumerating the INI profile sections.
  let selectedPath = $currentPath
  let allProfiles = ($candidates | enumerate | each {|entry|
    let s = $entry.item
    let path = (ini-value $s 'Path')
    let s = (ini-set $s 'Default' (if ($selectedPath != '' and $path == $selectedPath) { '1' } else { '0' }))
    $s | upsert name $"Profile($entry.index)"
  })

  let relevantPaths = ($managedPaths | append $touchedPaths)
  mut other = []
  mut generalSeen = false
  for section in $nonProfiles {
    if $section.name == 'General' {
      $generalSeen = true
      mut g = (ini-set $section 'StartWithLastProfile' '1')
      if $manifest.profileVersion != null {
        $g = (ini-set $g 'Version' ($manifest.profileVersion | into string))
      }
      $other = ($other | append $g)
    } else if ($section.name =~ '^Install[^]]+$') {
      let oldDefault = (ini-value $section 'Default')
      if ($oldDefault != null and $oldDefault in $relevantPaths) {
        if $currentPath != '' {
          $other = ($other | append (ini-set $section 'Default' $currentPath))
        } else {
          $other = ($other | append (ini-remove $section 'Default'))
        }
      } else {
        $other = ($other | append $section)
      }
    } else {
      $other = ($other | append $section)
    }
  }
  if not $generalSeen {
    mut general = (ini-set {name: 'General', lines: []} 'StartWithLastProfile' '1')
    if $manifest.profileVersion != null {
      $general = (ini-set $general 'Version' ($manifest.profileVersion | into string))
    }
    $other = ($other | append $general)
  }
  write-ini $file ($other | append $allProfiles)
}

def main [manifestPath: string, mode: string = 'sync'] {
  let manifest = (open $manifestPath)
  let root = $manifest.configPath
  let stateFile = ([$root '.home-manager-selectable-profiles.json'] | path join)
  if $mode == 'prepare-legacy-ini' {
    if not $manifest.legacyOnly or not ($stateFile | path exists) { return }
    let iniFile = ([$root 'profiles.ini'] | path join)
    # Home Manager is about to link the legacy profiles.ini. Preserve the old
    # mutable file in a backup so it doesn't collide with that symlink.
    if ($iniFile | path type) == 'file' {
      let backup = $"($iniFile).before-home-manager-legacy.((random uuid))"
      cp $iniFile $backup
      rm $iniFile
    }
    return
  }
  if $mode != 'sync' { error make {msg: 'Unknown sync mode'} }

  let previous = (read-state $stateFile)
  if (($manifest.groups | is-empty) and ($previous.groups | is-empty)) { return }
  mkdir $root

  let configuredIds = ($manifest.groups | each {|group| $group.storeId })
  let active = ($manifest.groups | each {|group| $group | upsert configured true })
  let orphaned = ($previous.groups
    | where {|group| not ($group.storeId in $configuredIds) }
    | each {|group| {
      configured: false
      storeId: $group.storeId
      name: $group.storeId
      showSelector: false
      defaultPath: null
      profiles: []
      sharedSettings: []
    }})
  let allGroups = ($active | append $orphaned)
  mut allPaths = []
  for group in $allGroups {
    let prior = ($previous.groups | where {|p| $p.storeId == $group.storeId })
    let previousPaths = if ($prior | is-empty) { [] } else { ($prior | first).paths }
    let paths = (sync-database $root $group $previousPaths $manifest.removeUnmanagedProfiles)
    $allPaths = ($allPaths | append [{group: $group, paths: $paths}])
  }

  if not $manifest.legacyOnly {
    sync-ini $root $manifest $allPaths $previous
  }
  # Persist ownership only after successfully reconciling every database and
  # profiles.ini. If activation fails midway, a retry remains safe.
  write-state $stateFile $manifest.groups
}
