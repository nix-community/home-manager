{
  modulePath,
  name,
  description ? null,
  wrappedPackageName ? null,
  unwrappedPackageName ? null,
  platforms,
  enableBookmarks ? true,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    concatStringsSep
    length
    literalExpression
    mapAttrsToList
    mkDefault
    mkIf
    mkMerge
    mkOption
    mkOptionDefault
    optionalString
    setAttrByPath
    types
    ;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  defaultConfigPath = with platforms; if isDarwin then darwin.configPath else linux.configPath;

  appName = name;

  moduleName = concatStringsSep "." modulePath;

  cfg = lib.getAttrFromPath modulePath config;

  jsonFormat = pkgs.formats.json { };

  supportedPlatforms = lib.flatten (lib.attrVals (lib.attrNames platforms) lib.platforms);

  isWrapped = lib.versionAtLeast config.home.stateVersion "19.09" && wrappedPackageName != null;

  defaultPackageName = if isWrapped then wrappedPackageName else unwrappedPackageName;

  packageName = if wrappedPackageName != null then wrappedPackageName else unwrappedPackageName;

  # The extensions path shared by all profiles; will not be supported
  # by future browser versions.
  extensionPath = "extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";

  # Firefox's toolkit profile entry contains StoreID and Path; the selectable
  # profile service updates the group path as the active profile changes.
  # Upstream (pinned): https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/browser/components/profiles/SelectableProfileService.sys.mjs
  # Datastore location and StoreID: https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/toolkit/profile/ProfilesDatastoreService.sys.mjs
  # Toolkit profiles.ini structure: https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/toolkit/profile/nsToolkitProfileService.cpp
  # Legacy profiles remain managed exactly as before when no selectable profiles
  # are configured. In mixed mode, a Nushell activation maintains a *writable*
  # profiles.ini because Firefox updates the current group path at runtime.
  profileIniPath = profile: if isDarwin then "Profiles/${profile.path}" else profile.path;
  legacyProfiles = lib.filterAttrs (_: profile: profile.storeId == null) cfg.profiles;
  selectableProfiles = lib.filterAttrs (_: profile: profile.storeId != null) cfg.profiles;
  # Keep a writable profiles.ini when groups are declared but currently empty.
  # An activation also runs when all groups have been removed, so the previous
  # ownership state can be reconciled without deleting Firefox-created profiles.
  hasSelectableProfiles = selectableProfiles != { } || cfg.profileGroups != { };

  # Explicit 8-hex store IDs work without any profileGroups declaration.
  # Otherwise, storeId resolves to a declared profile group by name.
  resolveStoreId =
    id:
    if id == null then
      null
    else if builtins.hasAttr id cfg.profileGroups then
      cfg.profileGroups.${id}.storeId
    else
      id;

  isStoreId = id: builtins.match "[0-9a-f]{8}" id != null;

  groupDefinitions = lib.mapAttrsToList (groupName: group: {
    inherit groupName;
    inherit (group)
      storeId
      name
      showSelector
      defaultProfile
      sharedSettings
      ;
  }) cfg.profileGroups;

  implicitStoreIds = lib.unique (
    lib.filter (id: id != null && !(lib.elem id (map (g: g.storeId) groupDefinitions))) (
      map (profile: resolveStoreId profile.storeId) (attrValues selectableProfiles)
    )
  );

  groupDefinitionsWithImplicit =
    groupDefinitions
    ++ map (id: {
      groupName = id;
      storeId = id;
      name = id;
      showSelector = true;
      defaultProfile = null;
      sharedSettings = { };
    }) implicitStoreIds;

  currentStoreId = resolveStoreId cfg.currentProfileGroup;

  # Firefox Nova theme IDs and palette (pinned upstream source):
  # https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/browser/themes/ThemesList.sys.mjs
  # The foreground/background values are representative *cached selector*
  # colors drawn from upstream preview text/picker colors and gradients; they
  # do not replicate the gradients or install/activate browser themes.
  # Cached theme metadata is defined in: https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/browser/components/profiles/SelectableProfile.sys.mjs
  novaProfileThemes = {
    default = {
      id = "default-theme@mozilla.org";
      foreground = "#161423";
      background = "#EADDFF";
    };

    sun = {
      id = "nova-sun@mozilla.org";
      foreground = "#270F00";
      background = "#FDE8B5";
    };

    spark = {
      id = "nova-spark@mozilla.org";
      foreground = "#250E0B";
      background = "#FFDBC5";
    };

    flame = {
      id = "nova-flame@mozilla.org";
      foreground = "#211014";
      background = "#FFD9DF";
    };

    flare = {
      id = "nova-flare@mozilla.org";
      foreground = "#1E111B";
      background = "#FFD5EE";
    };

    lavender = {
      id = "nova-lavender@mozilla.org";
      foreground = "#1A1220";
      background = "#F6D7FF";
    };

    dusk = {
      id = "nova-dusk@mozilla.org";
      foreground = "#161423";
      background = "#EADDFF";
    };

    lagoon = {
      id = "nova-lagoon@mozilla.org";
      foreground = "#111524";
      background = "#C5EAFE";
    };

    pine = {
      id = "nova-pine@mozilla.org";
      foreground = "#001E12";
      background = "#C4F1E0";
    };

    tide = {
      id = "nova-tide@mozilla.org";
      foreground = "#011C23";
      background = "#C3EEF8";
    };

    ash = {
      id = "nova-ash@mozilla.org";
      foreground = "#121114";
      background = "#EFEDF2";
    };

    smoke = {
      id = "nova-smoke@mozilla.org";
      foreground = "#181310";
      background = "#FBF4EE";
    };
  };

  # Firefox's older PROFILE_THEMES_MAP maps colorway IDs to light/dark colors:
  # https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/browser/components/profiles/SelectableProfileService.sys.mjs
  legacyThemeColors = {
    yellow = {
      id = "{cd6791f7-4b6d-47b4-8877-1d4c82c6699d}";
      light = "#FFE699";
      dark = "#271000";
    };

    orange = {
      id = "{7a301b7b-c3e2-40bf-a06b-6d517bbf138b}";
      light = "#FFCD9E";
      dark = "#270F00";
    };

    red = {
      id = "{8de5f8c3-bfc2-443b-9913-7bbadbd1ba0d}";
      light = "#FFC3C9";
      dark = "#290B0F";
    };

    pink = {
      id = "{2b0fadbf-238d-43db-aa9d-e06c9a7e000b}";
      light = "#FFC2DB";
      dark = "#270B15";
    };

    purple = {
      id = "{1d73a1eb-128d-4e9e-83f8-c0c51f8c5fd3}";
      light = "#F7CAFF";
      dark = "#1E0E25";
    };

    violet = {
      id = "{aab1adac-5449-47fd-b836-c2f43dc28f3f}";
      light = "#DDCFFF";
      dark = "#16112B";
    };

    blue = {
      id = "{4223a94a-d3f9-40e9-95dd-99aca80ea04b}";
      light = "#ABDFFF";
      dark = "#08152C";
    };

    green = {
      id = "{7063abff-a690-4b87-a548-fc32d3ce5708}";
      light = "#B5F0B5";
      dark = "#051C07";
    };

    cyan = {
      id = "{0683b144-0d4a-4815-963e-55a8ec8d386b}";
      light = "#A6ECF4";
      dark = "#001F2B";
    };
  };

  predefinedProfileThemes =
    novaProfileThemes
    // {
      system = novaProfileThemes.default;

      light = {
        id = "firefox-compact-light@mozilla.org";
        foreground = "#15141A";
        background = "#EAEAED";
      };

      dark = {
        id = "firefox-compact-dark@mozilla.org";
        foreground = "#FFFFFF";
        background = "#1C1B22";
      };

      gray = {
        id = "firefox-compact-light@mozilla.org";
        foreground = "#15141A";
        background = "#EAEAED";
      };

      gray-dark = {
        id = "firefox-compact-dark@mozilla.org";
        foreground = "#FFFFFF";
        background = "#1C1B22";
      };
    }
    // lib.listToAttrs (
      lib.concatMap (
        themeName:
        let
          theme = legacyThemeColors.${themeName};
        in
        [
          (lib.nameValuePair themeName {
            inherit (theme) id;
            foreground = "#15141A";
            background = theme.light;
          })
          (lib.nameValuePair "${themeName}-dark" {
            inherit (theme) id;
            foreground = "#FFFFFF";
            background = theme.dark;
          })
        ]
      ) (lib.attrNames legacyThemeColors)
    );

  # Firefox's STANDARD_AVATARS set (pinned upstream source):
  # https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/browser/components/profiles/SelectableProfile.sys.mjs
  standardProfileAvatars = [
    "barbell"
    "bike"
    "book"
    "briefcase"
    "canvas"
    "craft"
    "default-favicon"
    "diamond"
    "flower"
    "folder"
    "hammer"
    "heart"
    "heart-rate"
    "history"
    "leaf"
    "lightbulb"
    "makeup"
    "message"
    "musical-note"
    "palette"
    "paw-print"
    "plane"
    "present"
    "shopping"
    "soccer"
    "sparkle-single"
    "star"
    "video-game-controller"
  ];

  themeSpec = theme: if builtins.isString theme then predefinedProfileThemes.${theme} else theme;

  prefValue =
    pref:
    if lib.isBool pref || lib.isInt pref || lib.isString pref then
      pref
    else if lib.isPath pref then
      toString pref
    else
      builtins.toJSON pref;

  # Empty groups must be passed to the activation as well: if a user removes
  # the last managed profile we still need to reconcile the old database.
  groups = map (
    group:
    let
      members = lib.filterAttrs (_: p: resolveStoreId p.storeId == group.storeId) selectableProfiles;
      memberNames = lib.attrNames members;
      markedDefaults = lib.attrNames (lib.filterAttrs (_: p: p.isDefault) members);

      firstProfile =
        if memberNames == [ ] then
          null
        else if group.defaultProfile != null && builtins.hasAttr group.defaultProfile members then
          group.defaultProfile
        else if markedDefaults != [ ] then
          builtins.head markedDefaults
        else
          builtins.head memberNames;

      profilesForDB = lib.mapAttrsToList (
        _: p:
        let
          theme = themeSpec p.theme;
        in
        {
          inherit (p) name avatar;
          path = profileIniPath p;
          themeId = theme.id;
          themeFg = theme.foreground;
          themeBg = theme.background;
        }
      ) members;
    in
    group
    // {
      profiles = profilesForDB;
      defaultPath = if firstProfile == null then null else profileIniPath members.${firstProfile};

      sharedSettings = lib.mapAttrsToList (n: v: {
        name = n;
        value = prefValue v;
        isBoolean = if lib.isBool v then 1 else 0;
      }) group.sharedSettings;
    }
  ) groupDefinitionsWithImplicit;

  selectableManifest = jsonFormat.generate "${appName}-selectable-profiles.json" {
    configPath =
      if lib.hasPrefix "/" cfg.configPath then
        cfg.configPath
      else
        "${config.home.homeDirectory}/${cfg.configPath}";

    inherit (cfg) profileVersion;
    inherit currentStoreId;
    inherit (cfg) removeUnmanagedProfiles;
    # In legacy-only mode Home Manager creates profiles.ini as a symlink,
    # rather than the selectable-profile activation writing to it.
    legacyOnly = !hasSelectableProfiles && cfg.profiles != { };
    inherit groups;

    legacyProfiles = map (p: {
      inherit (p) name;
      path = profileIniPath p;
    }) (lib.sort (a: b: a.id < b.id) (attrValues legacyProfiles));
  };

  profiles =
    lib.flip lib.mapAttrs' legacyProfiles (
      _: profile:
      lib.nameValuePair "Profile${toString profile.id}" {
        Name = profile.name;
        Path = profileIniPath profile;
        IsRelative = 1;
        Default = if profile.isDefault then 1 else 0;
      }
    )
    // {
      General = {
        StartWithLastProfile = 1;
      }
      // lib.optionalAttrs (cfg.profileVersion != null) {
        Version = cfg.profileVersion;
      };
    };

  profilesIni = lib.generators.toINI { } profiles;

  userPrefValue =
    pref:
    builtins.toJSON (
      if lib.isBool pref || lib.isInt pref || lib.isString pref || lib.isPath pref then
        pref
      else
        builtins.toJSON pref
    );

  extensionSettingsNeedForce =
    extensionSettings: builtins.any (ext: ext.settings != { }) (attrValues extensionSettings);

  extensionSettingsMissingForce =
    extensionSettings:
    builtins.any (ext: ext.settings != { } && !ext.force) (attrValues extensionSettings);

  mkUserJs =
    prePrefs: prefs: extraPrefs: bookmarksFile: extensions:
    let
      prefs' =
        lib.optionalAttrs (bookmarksFile != null) {
          "browser.bookmarks.file" = toString bookmarksFile;
          "browser.places.importBookmarksHTML" = true;
        }
        // lib.optionalAttrs (extensionSettingsNeedForce extensions) {
          "extensions.webextensions.ExtensionStorageIDB.enabled" = false;
        }
        // prefs;
    in
    ''
      // Generated by Home Manager.

      ${prePrefs}

      ${lib.concatStrings (
        mapAttrsToList (name: value: ''
          user_pref("${name}", ${userPrefValue value});
        '') prefs'
      )}

      ${extraPrefs}
    '';

  mkContainersJson =
    containers:
    let
      containerToIdentity = _: container: {
        userContextId = container.id;
        inherit (container) color icon name;
        public = true;
      };
    in
    ''
      ${builtins.toJSON {
        version = 5;
        lastUserContextId = lib.foldlAttrs (
          acc: _: value:
          if value.id > acc then value.id else acc
        ) 0 containers;
        identities = mapAttrsToList containerToIdentity containers ++ [
          {
            userContextId = 4294967294; # 2^32 - 2
            name = "userContextIdInternal.thumbnail";
            icon = "";
            color = "";
            accessKey = "";
            public = false;
          }
          {
            userContextId = 4294967295; # 2^32 - 1
            name = "userContextIdInternal.webextStorageLocal";
            icon = "";
            color = "";
            accessKey = "";
            public = false;
          }
        ];
      }}
    '';

  mkNoDuplicateAssertion =
    entities: entityKind:
    (
      let
        # Return an attribute set with entity IDs as keys and a list of
        # entity names with corresponding ID as value. An ID is present in
        # the result only if more than one entity has it. The argument
        # entities is a list of AttrSet of one id/name pair.
        findDuplicateIds =
          entities: lib.filterAttrs (_entityId: entityNames: length entityNames != 1) (lib.zipAttrs entities);

        duplicates = findDuplicateIds (
          mapAttrsToList (entityName: entity: { "${toString entity.id}" = entityName; }) entities
        );

        mkMsg = entityId: entityNames: "  - ID ${entityId} is used by " + concatStringsSep ", " entityNames;
      in
      {
        assertion = duplicates == { };
        message = ''
          Must not have a ${appName} ${entityKind} with an existing ID but
        ''
        + concatStringsSep "\n" (mapAttrsToList mkMsg duplicates);
      }
    );

  wrapPackage =
    package:
    let
      browserName = package.browserName or (builtins.parseDrvName package.name).name;

      configureAppDataDir = cfg.configPath != defaultConfigPath;

      absoluteConfigPath =
        if lib.hasPrefix "/" cfg.configPath then
          cfg.configPath
        else
          "${config.home.homeDirectory}/${cfg.configPath}";

      callWithAppDataDir =
        wrapper: args:
        let
          wrapperArgs = lib.functionArgs wrapper;
          supportsAppDataDir = wrapperArgs ? appDataDir;
          # Gracefully handle wrappers that don't, yet, support appDataDir.
          appDataDirArgs = lib.optionalAttrs (configureAppDataDir && supportsAppDataDir) {
            appDataDir = absoluteConfigPath;
          };
          argsWithAppDataDir =
            if lib.isFunction args then
              # Modern wrapped packages pass an override function.
              old: args old // appDataDirArgs
            else
              # Legacy wrapFirefox passes an attribute set.
              args // appDataDirArgs;
        in
        lib.warnIf (configureAppDataDir && !supportsAppDataDir)
          "${moduleName}: '${browserName}' does not support the 'appDataDir' wrapper argument; 'configPath' will not be applied to the package wrapper."
          (wrapper argsWithAppDataDir);
    in
    if package == null then
      null
    else if isWrapped then
      if lib.functionArgs package.override ? cfg then
        callWithAppDataDir package.override (old: {
          # An explicit cfg keeps the wrapper from reading nixpkgs config.<browser>.
          cfg = old.cfg or { };
          extraPolicies = (old.extraPolicies or { }) // cfg.policies;
          pkcs11Modules = (old.pkcs11Modules or [ ]) ++ cfg.pkcs11Modules;
        })
      else
        let
          droppedPolicies = cfg.policies != { } && (!isDarwin || cfg.darwinDefaultsId == null);
          droppedOptions = droppedPolicies || cfg.pkcs11Modules != [ ] || configureAppDataDir;
        in
        lib.warnIf droppedOptions
          "${moduleName}: '${browserName}' cannot be reconfigured; 'policies', 'pkcs11Modules', and 'configPath' will not be applied."
          package
    else
      # The wrapper reads browser features from the nixpkgs config; keep them at
      # the wrapper's defaults instead of the user's nixpkgs settings.
      callWithAppDataDir ((pkgs.wrapFirefox.override { config = { }; }) package) { };

in
{
  imports = [
    (lib.mkRemovedOptionModule (
      modulePath ++ [ "enableGnomeExtensions" ]
    ) "Add `pkgs.gnome-browser-connector` to `${moduleName}.nativeMessagingHosts` instead.")
    (lib.mkRemovedOptionModule (
      modulePath ++ [ "vendorPath" ]
    ) "Native messaging hosts work without specifying a vendor path.")
  ];

  options = setAttrByPath modulePath {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to enable ${appName}.${optionalString (description != null) " ${description}"}
      '';
    };

    package = mkOption {
      type = with types; nullOr package;
      default = pkgs.${defaultPackageName};
      defaultText = literalExpression "pkgs.${packageName}";
      example = literalExpression ''
        pkgs.${packageName}.override {
          # See nixpkgs' firefox/wrapper.nix to check which options you can use
          nativeMessagingHosts = [
            # Gnome shell native connector
            pkgs.gnome-browser-connector
            # Tridactyl native connector
            pkgs.tridactyl-native
          ];
        }
      '';
      description = ''
        The ${appName} package to use. If state version ≥ 19.09 then
        this should be a wrapped ${appName} package. For earlier state
        versions it should be an unwrapped ${appName} package.
        Set to `null` to disable installing ${appName}.

        Note that by default ${appName} will attempt to update the `profiles.ini`
        configuration file on startup which will fail if Home Manager is managing
        it. If you wish to use an unwrapped ${appName} (e.g. from outside Nix),
        consider setting the environment variable `MOZ_LEGACY_PROFILES=1` to
        disable attempts to write to the file. For macOS specifically, this
        should be done via `/bin/launchctl setenv MOZ_LEGACY_PROFILES 1` to
        ensure it is set when ${appName} is launched through the Finder or Dock.
      '';
    };

    release = mkOption {
      internal = true;
      type = types.str;
      description = "Upstream release version used to fetch from `releases.mozilla.org`.";
    };

    globalExtensions = mkOption {
      type = types.listOf (
        types.oneOf [
          types.package
          (types.submodule {
            options = {
              package = mkOption {
                type = types.package;
              };

              settings = mkOption {
                type = types.attrsOf jsonFormat.type;
                default = { };
                description = "Json formatted options for this extension.";
              };
            };
          })
        ]
      );
      default = [ ];
      example = literalExpression ''
        with pkgs.nur.repos.rycee.firefox-addons; [
          privacy-badger
          {
            package = ublock-origin;
            settings = {
              private_browsing = true;
            };
          }
        ]
      '';
      description = ''
        Add-on package to install under policies.
        For a package to work here it needs and addonId exposed in it's passthru.
        This will be included in all add-ons accessible from the Nix User Repository.
        Once you have NUR installed run

        ```console
        $ nix-env -f '<nixpkgs>' -qaP -A nur.repos.rycee.firefox-addons
        ```

        to list the available ${name} add-ons.

        Installing extensions this way will automatically enable extensions
        inside ${name} after the first installation.
      '';
    };

    languagePacks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        The language packs to install. Available language codes can be found
        on the releases page:
        `https://releases.mozilla.org/pub/firefox/releases/''${version}/linux-x86_64/xpi/`,
        replacing `''${version}` with the version of ${appName} you have. If
        the version string of your Firefox derivative diverts from the upstream
        version, try setting the `release` option.
      '';
      example = [
        "en-GB"
        "de"
      ];
    };

    name = mkOption {
      internal = true;
      type = types.str;
      default = name;
      example = "Firefox";
      description = "The name of the browser.";
    };

    wrappedPackageName = mkOption {
      internal = true;
      type = with types; nullOr str;
      default = wrappedPackageName;
      description = "Name of the wrapped browser package.";
    };
    darwinDefaultsId = mkOption rec {
      type = types.nullOr types.str;
      default = if platforms.darwin ? "defaultsId" then platforms.darwin.defaultsId else null;
      example = if default != null then default else "com.developer.app";
      description = "The id for the darwin defaults in order to set policies";
    };

    darwinAppName = mkOption {
      internal = true;
      type = types.str;
      default =
        if platforms.darwin ? "appName" then
          platforms.darwin.appName
        else
          lib.toUpper (lib.substring 0 1 cfg.wrappedPackageName)
          + lib.toLower (
            lib.substring 1 ((lib.stringLength cfg.wrappedPackageName) - 1) cfg.wrappedPackageName
          );
      description = "Name of browser app on Darwin.";
    };

    profilesPath = mkOption {
      internal = true;
      type = types.str;
      default = if isDarwin then "${cfg.configPath}/Profiles" else cfg.configPath;
      description = "Path to profiles.";
    };

    configPath = mkOption {
      type = types.str;
      default = defaultConfigPath;
      defaultText = literalExpression "platform specific default config path";
      example = ".mozilla/firefox";
      description = ''
        Directory containing the ${appName} configuration files. A relative
        path is interpreted relative to the user's home directory.

        Setting this to a non-default path also configures the package wrapper
        to use it as the application data directory. This can be useful on
        macOS 27 and later, where wrapped applications may be denied access to
        the traditional application data directory.
      '';
    };

    nativeMessagingHosts = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        Additional packages containing native messaging hosts that should be
        made available to ${appName} extensions.
      '';
    };

    finalPackage = mkOption {
      type = with types; nullOr package;
      readOnly = true;
      description = "Resulting ${appName} package.";
    };

    policies = lib.optionalAttrs (wrappedPackageName != null) (mkOption {
      type = types.attrsOf jsonFormat.type;
      default = { };
      description = "[See list of policies](https://mozilla.github.io/policy-templates/).";
      example = {
        DefaultDownloadDirectory = "\${home}/Downloads";
        BlockAboutConfig = true;
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
            default_area = "menupanel";
            private_browsing = true;
          };
        };
      };
    });

    profileVersion = mkOption {
      internal = true;
      type = types.nullOr types.ints.unsigned;
      default = if isDarwin then null else 2;
      description = "profile version, set null for nix-darwin";
    };

    removeUnmanagedProfiles = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to unregister Firefox-created selectable profiles that are not
        declared in Nix. This only affects current or previously Home Manager-
        managed profile groups; independent Firefox groups and legacy profiles
        are left alone. The default (false) preserves Firefox-created profiles,
        but profiles previously declared in Nix are always unregistered once
        removed from the configuration. Profile directories and user data are
        never deleted by this option.
      '';
    };

    # Firefox's datastore creates one SQLite database per StoreID:
    # https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/toolkit/profile/ProfilesDatastoreService.sys.mjs
    # Group membership and the toolkit profile link are managed by:
    # https://searchfox.org/firefox-main/rev/64cfaf34e56f4c82eea77d032ec592c083b5b161/browser/components/profiles/SelectableProfileService.sys.mjs
    # An attrsOf submodule lets different groups coexist.
    profileGroups = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }: {
            options = {
              name = mkOption {
                type = types.str;
                default = name;
                description = "Name of the group as displayed by the toolkit profile manager.";
              };

              storeId = mkOption {
                type = types.strMatching "[0-9a-f]{8}";
                default = builtins.substring 0 8 (builtins.hashString "sha256" "${moduleName}:${name}");
                defaultText = literalExpression ''builtins.substring 0 8 (builtins.hashString "sha256" "<module>:<group>")'';
                example = "e41de5fe";
                description = "Stable store ID. Defaults to the first eight hex digits of a name-derived SHA-256 hash.";
              };

              defaultProfile = mkOption {
                # References are checked by assertions. Dynamically enumerating cfg.profiles
                # here would make the option documentation depend on user configuration.
                type = types.nullOr types.str;
                default = null;
                example = "work";
                description = "Initial default member (the attribute name under profiles). Firefox may subsequently change the group path.";
              };

              showSelector = mkOption {
                type = types.bool;
                default = true;
                description = "Whether to show Firefox's selectable profile selector on startup.";
              };

              sharedSettings = mkOption {
                type = types.attrsOf jsonFormat.type;
                default = { };
                example = {
                  "browser.shell.checkDefaultBrowser" = false;
                };
                description = ''
                  Shared preferences stored in this group's SQLite SharedPrefs table.
                  Supports boolean, integer and string Firefox prefs. JSON-compatible
                  complex values are converted to JSON strings, like profile settings.
                  Other existing shared preferences are preserved.
                '';
              };
            };
          }
        )
      );
      default = { };
      description = ''
        Selectable profile groups. Each referenced group has one toolkit profile
        in profiles.ini and one SQLite database under Profile Groups.
      '';
    };

    currentProfileGroup = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "personal";
      description = ''
        The currently selected default group for this browser. Required when
        using selectable profiles. May be a profileGroups key or a literal
        eight-character hexadecimal store ID used by one of the profiles.
      '';
    };

    profiles = mkOption {
      type = types.attrsOf (
        types.submodule (
          {
            config,
            name,
            ...
          }:
          let
            profilePath = modulePath ++ [
              "profiles"
              name
            ];
          in
          {
            imports = [ (pkgs.path + "/nixos/modules/misc/assertions.nix") ];

            options = {
              name = mkOption {
                type = types.str;
                default = name;
                description = "Profile name.";
              };

              id = mkOption {
                type = types.ints.unsigned;
                default = 0;
                description = ''
                  Profile ID. This should be set to a unique number per profile.
                '';
              };

              storeId = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "personal";
                description = ''
                  null creates a legacy toolkit profile. A literal eight-character
                  lowercase hexadecimal ID, or a key in profileGroups, creates a
                  selectable profile. All selectable profiles resolving to the
                  same ID share a SQLite datastore and one profiles.ini entry.
                '';
              };

              avatar = mkOption {
                type = types.enum standardProfileAvatars;
                default = "star";
                example = "briefcase";
                description = ''
                  Built-in selectable profile avatar name. For custom avatars,
                  use Firefox's interface (custom image files are not installed
                  by this module).
                '';
              };

              theme = mkOption {
                type = types.oneOf [
                  (types.enum (lib.attrNames predefinedProfileThemes))
                  (types.submodule {
                    options = {
                      id = mkOption {
                        type = types.str;
                        description = "Add-on ID of a custom Firefox theme.";
                      };
                      foreground = mkOption {
                        type = types.str;
                        description = "Cached CSS foreground color for the profile selector.";
                      };
                      background = mkOption {
                        type = types.str;
                        description = "Cached CSS background color for the profile selector.";
                      };
                    };
                  })
                ];
                default = "default";
                example = "spark";
                description = ''
                  Selectable profile theme. Firefox Nova (157+) names: default,
                  sun, spark, flame, flare, lavender, dusk, lagoon, pine, tide,
                  ash and smoke. The old color names remain accepted for older
                  configurations. Or use { id, foreground, background } for a
                  custom theme. This option only sets profile-selector metadata
                  in SQLite; it does not install or activate the browser theme.
                  Manage the theme add-on separately with
                  `${moduleName}.globalExtensions`,
                  `${moduleName}.profiles.<name>.extensions.packages`, or
                  `${moduleName}.policies` (for example, `ExtensionSettings`).
                  You may still need to enable the theme in Firefox's
                  Add-ons and Themes interface after installation.
                '';
              };

              preConfig = mkOption {
                type = types.lines;
                default = "";
                description = ''
                  Extra preferences to add to {file}`user.js`, before
                  [](#opt-programs.firefox.profiles._name_.settings).

                  Use [](#opt-programs.firefox.profiles._name_.extraConfig), unless
                  you want to overwrite in
                  [](#opt-programs.firefox.profiles._name_.settings), then use this
                  option.
                '';
              };

              settings = mkOption {
                type = types.attrsOf (
                  jsonFormat.type
                  // {
                    description = "${appName} preference (int, bool, string, and also attrs, list, float as a JSON string)";
                  }
                );
                default = { };
                example = literalExpression ''
                  {
                    "browser.startup.homepage" = "https://nixos.org";
                    "browser.search.region" = "GB";
                    "browser.search.isUS" = false;
                    "distribution.searchplugins.defaultLocale" = "en-GB";
                    "general.useragent.locale" = "en-GB";
                    "browser.bookmarks.showMobileBookmarks" = true;
                    "browser.newtabpage.pinned" = [{
                      title = "NixOS";
                      url = "https://nixos.org";
                    }];
                  }
                '';
                description = ''
                  Attribute set of ${appName} preferences.

                  ${appName} only supports int, bool, and string types for
                  preferences, but home-manager will automatically
                  convert all other JSON-compatible values into strings.
                '';
              };

              extraConfig = mkOption {
                type = types.lines;
                default = "";
                description = ''
                  Extra preferences to add to {file}`user.js`.
                '';
              };

              userChrome = mkOption {
                type = types.oneOf [
                  types.lines
                  types.path
                ];
                default = "";
                description = "Custom ${appName} user chrome CSS.";
                example = ''
                  /* Hide tab bar in FF Quantum */
                  @-moz-document url(chrome://browser/content/browser.xul), url(chrome://browser/content/browser.xhtml) {
                    #TabsToolbar {
                      visibility: collapse !important;
                      margin-bottom: 21px !important;
                    }

                    #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"] #sidebar-header {
                      visibility: collapse !important;
                    }
                  }
                '';
              };

              userContent = mkOption {
                type = types.oneOf [
                  types.lines
                  types.path
                ];
                default = "";
                description = "Custom ${appName} user content CSS.";
                example = ''
                  /* Hide scrollbar in FF Quantum */
                  *{scrollbar-width:none !important}
                '';
              };

              bookmarks = mkOption {
                type = types.submodule (
                  { config, ... }:
                  import ./profiles/bookmarks.nix {
                    inherit config lib pkgs;
                    modulePath = modulePath ++ [
                      "profiles"
                      name
                      "bookmarks"
                    ];
                  }
                );
                default = { };
                internal = !enableBookmarks;
                description = "Declarative bookmarks.";
              };

              path = mkOption {
                type = types.str;
                default = name;
                description = "Profile path.";
              };

              isDefault = mkOption {
                type = types.bool;
                default = config.storeId == null && config.id == 0;
                defaultText = "true for a legacy profile with ID 0";
                description = "Legacy default, or initial default within a selectable group. Use currentProfileGroup to select the current group.";
              };

              search = mkOption {
                type = types.submodule (
                  args:
                  import ./profiles/search.nix {
                    inherit (args) config;
                    inherit lib pkgs appName;
                    package = cfg.finalPackage;
                    modulePath = modulePath ++ [
                      "profiles"
                      name
                      "search"
                    ];
                    profilePath = config.path;
                  }
                );
                default = { };
                description = "Declarative search engine configuration.";
              };

              handlers = mkOption {
                type = types.submodule (
                  args:
                  import ./profiles/handlers.nix {
                    inherit (args) config;
                    inherit lib pkgs appName;
                    package = cfg.finalPackage;
                    modulePath = modulePath ++ [
                      "profiles"
                      name
                      "handlers"
                    ];
                    profilePath = config.path;
                  }
                );
                default = { };
                description = "Declarative handlers configuration for MIME types and URL schemes.";
              };

              containersForce = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to force replace the existing containers configuration.
                  This is recommended since ${appName} will replace the symlink on
                  every launch, but note that you'll lose any existing configuration
                  by enabling this.
                '';
              };

              containers = mkOption {
                type = types.attrsOf (
                  types.submodule (
                    { name, ... }:
                    {
                      options = {
                        name = mkOption {
                          type = types.str;
                          default = name;
                          description = "Container name, e.g., shopping.";
                        };

                        id = mkOption {
                          type = types.ints.unsigned;
                          default = 1;
                          description = ''
                            Container ID. This should be set to a unique number per container in this profile.
                          '';
                        };

                        # List of colors at
                        # https://searchfox.org/mozilla-central/rev/5ad226c7379b0564c76dc3b54b44985356f94c5a/toolkit/components/extensions/parent/ext-contextualIdentities.js#32
                        color = mkOption {
                          type = types.enum [
                            "blue"
                            "turquoise"
                            "green"
                            "yellow"
                            "orange"
                            "red"
                            "pink"
                            "purple"
                            "toolbar"
                          ];
                          default = "pink";
                          description = "Container color.";
                        };

                        icon = mkOption {
                          type = types.enum [
                            "briefcase"
                            "cart"
                            "circle"
                            "dollar"
                            "fence"
                            "fingerprint"
                            "gift"
                            "vacation"
                            "food"
                            "fruit"
                            "pet"
                            "tree"
                            "chill"
                          ];
                          default = "fruit";
                          description = "Container icon.";
                        };
                      };
                    }
                  )
                );
                default = { };
                example = {
                  "shopping" = {
                    id = 1;
                    color = "blue";
                    icon = "cart";
                  };
                  "dangerous" = {
                    id = 2;
                    color = "red";
                    icon = "fruit";
                  };
                };
                description = ''
                  Attribute set of container configurations. See
                  [Multi-Account
                  Containers](https://support.mozilla.org/en-US/kb/containers)
                  for more information.
                '';
              };
              extensions = mkOption {
                type = types.submodule {
                  options = {
                    packages = mkOption {
                      type = types.listOf types.package;
                      default = [ ];
                      example = literalExpression ''
                        with pkgs.nur.repos.rycee.firefox-addons; [
                          privacy-badger
                        ]
                      '';
                      description = ''
                        List of ${name} add-on packages to install for this profile.
                        Some pre-packaged add-ons are accessible from the Nix User Repository.
                        Once you have NUR installed run

                        ```console
                        $ nix-env -f '<nixpkgs>' -qaP -A nur.repos.rycee.firefox-addons
                        ```

                        to list the available ${name} add-ons.

                        Note that it is necessary to manually enable these extensions
                        inside ${name} after the first installation.

                        To automatically enable extensions add
                        `"extensions.autoDisableScopes" = 0;`
                        to
                        [{option}`${moduleName}.profiles.<profile>.settings`](#opt-${moduleName}.profiles._name_.settings)

                        On systems using impermanence, this only prevents
                        ${name} from requiring manual extension approval. It
                        does not preserve extension runtime state such as
                        extension UUIDs, logins, local storage, or
                        per-extension data. Persist the ${name} profile state
                        needed by your extensions, or configure supported
                        extension settings declaratively with
                        [{option}`${moduleName}.profiles.<profile>.extensions.settings`](#opt-${moduleName}.profiles._name_.extensions.settings).

                        Persisting only the `extensions` directory is generally
                        not sufficient, because ${name} stores extension state
                        in other profile files and databases that are managed
                        outside Home Manager.
                      '';
                    };

                    force = mkOption {
                      description = ''
                        Whether to override all previous firefox settings.

                        This is required when using `settings`.
                      '';
                      default = false;
                      example = true;
                      type = types.bool;
                    };

                    exhaustivePermissions = mkOption {
                      description = ''
                        When enabled, the user must authorize requested
                        permissions for all extensions from
                        {option}`${moduleName}.profiles.<profile>.extensions.packages`
                        in
                        {option}`${moduleName}.profiles.<profile>.extensions.settings.<extensionID>.permissions`
                      '';
                      default = false;
                      example = true;
                      type = types.bool;
                    };

                    exactPermissions = mkOption {
                      description = ''
                        When enabled,
                        {option}`${moduleName}.profiles.<profile>.extensions.settings.<extensionID>.permissions`
                        must specify the exact set of permissions that the
                        extension will request.

                        This means that if the authorized permissions are
                        broader than what the extension requests, the
                        assertion will fail.
                      '';
                      default = false;
                      example = true;
                      type = types.bool;
                    };

                    settings = mkOption {
                      default = { };
                      example = literalExpression ''
                        {
                          # Example with uBlock origin's extensionID
                          "uBlock0@raymondhill.net".settings = {
                            selectedFilterLists = [
                              "ublock-filters"
                              "ublock-badware"
                              "ublock-privacy"
                              "ublock-unbreak"
                              "ublock-quick-fixes"
                            ];
                          };

                          # Example with Stylus' UUID-form extensionID
                          "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}".settings = {
                            dbInChromeStorage = true; # required for Stylus
                          }
                        }
                      '';
                      description = ''
                        Attribute set of options for each extension.
                        The keys of the attribute set consist of the ID of the extension
                        or its UUID wrapped in curly braces.
                      '';
                      type = types.attrsOf (
                        types.submodule {
                          options = {
                            settings = mkOption {
                              type = types.attrsOf jsonFormat.type;
                              default = { };
                              description = "Json formatted options for this extension.";
                            };
                            permissions = mkOption {
                              type = types.nullOr (types.listOf types.str);
                              default = null;
                              example = [ "activeTab" ];
                              defaultText = "Any permissions";
                              description = ''
                                Allowed permissions for this extension. See
                                <https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json/permissions>
                                for a list of relevant permissions.
                              '';
                            };
                            force = mkOption {
                              type = types.bool;
                              default = false;
                              example = true;
                              description = ''
                                Forcibly override any existing configuration for
                                this extension.
                              '';
                            };
                          };
                        }
                      );
                    };
                  };
                };
                default = { };
                description = ''
                  Submodule for installing and configuring extensions.
                '';
                example = literalExpression ''
                  {
                    packages = with pkgs.nur.repos.rycee.firefox-addons; [
                      ublock-origin
                    ];
                    settings."uBlock0@raymondhill.net".settings = {
                      selectedFilterLists = [
                        "ublock-filters"
                        "ublock-badware"
                        "ublock-privacy"
                        "ublock-unbreak"
                        "ublock-quick-fixes"
                      ];
                    };
                  }
                '';
              };
            };

            config = {
              settings = mkMerge [
                (mkIf (config.userChrome != "") {
                  "toolkit.legacyUserProfileCustomizations.stylesheets" = mkDefault true;
                })

                (mkIf (config.storeId != null) {
                  "toolkit.profiles.storeID" = mkDefault (resolveStoreId config.storeId);
                  "browser.profiles.enabled" = mkDefault true;
                  "browser.profiles.created" = mkDefault true;
                })
              ];

              assertions = [
                (mkNoDuplicateAssertion config.containers "container")
                {
                  assertion = !(extensionSettingsMissingForce config.extensions.settings) || config.extensions.force;
                  message = ''
                    Using '${lib.showOption profilePath}.extensions.settings' will override all
                    previous extensions settings. Enable either
                    '${lib.showOption profilePath}.extensions.force' or the corresponding
                    '${lib.showOption profilePath}.extensions.settings.<extensionId>.force'
                    to acknowledge this.
                  '';
                }
                {
                  assertion =
                    (config.storeId == null)
                    || (
                      (config.settings."toolkit.profiles.storeID" or (resolveStoreId config.storeId))
                      == (resolveStoreId config.storeId)
                    );
                  message = ''
                    ${moduleName}.profiles.${name}.settings."toolkit.profiles.storeID"
                    must match the resolved storeId.
                  '';
                }
                {
                  assertion =
                    config.storeId == null
                    || builtins.hasAttr config.storeId cfg.profileGroups
                    || isStoreId config.storeId;
                  message = "${moduleName}.profiles.${name}.storeId must be a group name or eight lowercase hex characters.";
                }
                {
                  assertion =
                    builtins.isString config.theme || (config.theme.id != "" && !(lib.hasInfix "\n" config.theme.id));
                  message = "${moduleName}.profiles.${name}.theme.id must be a non-empty add-on ID without newlines.";
                }
                {
                  assertion =
                    config.storeId == null
                    || (
                      (config.settings."browser.profiles.enabled" or true) == true
                      && (config.settings."browser.profiles.created" or true) == true
                    );
                  message = "${moduleName}.profiles.${name}: selectable profiles require browser.profiles.enabled and browser.profiles.created to be true.";
                }
              ]
              ++ (builtins.concatMap (
                {
                  addonId ? null,
                  name,
                  meta,
                  ...
                }:
                let
                  safeAddonId = if addonId != null then addonId else name;
                  permissions = config.extensions.settings.${safeAddonId}.permissions or null;
                  requireCheck = config.extensions.exhaustivePermissions || permissions != null;
                  authorizedPermissions = lib.optionals (permissions != null) permissions;
                  missingPermissions = lib.subtractLists authorizedPermissions meta.mozPermissions;
                  redundantPermissions = lib.subtractLists meta.mozPermissions authorizedPermissions;
                  checkSatisfied =
                    if config.extensions.exactPermissions then
                      missingPermissions == [ ] && redundantPermissions == [ ]
                    else
                      missingPermissions == [ ];
                  errorMessage =
                    if
                      config.extensions.exactPermissions && missingPermissions != [ ] && redundantPermissions != [ ]
                    then
                      ''
                        Extension ${safeAddonId} requests permissions that weren't
                        authorized: ${builtins.toJSON missingPermissions}.
                        Additionally, the following permissions were authorized,
                        but extension ${safeAddonId} did not request them:
                        ${builtins.toJSON redundantPermissions}.
                        Consider adjusting the permissions in''
                    else if config.extensions.exactPermissions && redundantPermissions != [ ] then
                      ''
                        The following permissions were authorized, but extension
                        ${safeAddonId} did not request them: ${builtins.toJSON redundantPermissions}.
                        Consider removing the redundant permissions from''
                    else
                      ''
                        Extension ${safeAddonId} requests permissions that weren't
                        authorized: ${builtins.toJSON missingPermissions}.
                        Consider adding the missing permissions to'';
                in
                [
                  {
                    assertion = !requireCheck || checkSatisfied;
                    message = ''
                      ${errorMessage}
                      '${
                        lib.showAttrPath (
                          profilePath
                          ++ [
                            "extensions"
                            safeAddonId
                          ]
                        )
                      }.permissions'.
                    '';
                  }
                ]
              ) config.extensions.packages)
              ++ (builtins.concatMap (
                {
                  name,
                  value,
                }:
                let
                  packages = builtins.filter (pkg: (pkg.addonId or pkg.name) == name) config.extensions.packages;
                in
                [
                  {
                    assertion = value.permissions == null || length packages == 1;
                    message = ''
                      Must have exactly one extension with addonId '${name}'
                      in '${lib.showOption profilePath}.extensions.packages' but found ${toString (length packages)}.
                    '';
                  }
                ]
              ) (lib.attrsToList config.extensions.settings))
              ++ config.bookmarks.assertions;
            };
          }
        )
      );
      default = { };
      example = lib.optionalAttrs (moduleName == "programs.firefox") (literalExpression ''
        {
          "dev-edition-default" = {
            id = 0;
            path = config.home.username;

            settings = {
              "browser.aboutConfig.showWarning" = false;
            };
          };
        }
      '');
      description = ''
        Attribute set of ${appName} profiles.

        ${lib.optionalString (moduleName == "programs.firefox") ''
          When using Firefox Developer Edition, the profile name should be
          `dev-edition-default`. You can still set {option}`path` to store the
          profile in a custom directory.
        ''}
      '';
    };

    pkcs11Modules = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        Additional packages to be loaded as PKCS #11 modules in Firefox.
      '';
    };
  };

  config = mkIf cfg.enable (
    {
      assertions = [
        (lib.hm.assertions.assertPlatform moduleName pkgs supportedPlatforms)

        (
          let
            defaults = lib.catAttrs "name" (lib.filter (a: a.isDefault) (attrValues legacyProfiles));
          in
          {
            assertion = selectableProfiles != { } || legacyProfiles == { } || length defaults == 1;
            message =
              "Must have exactly one default ${appName} profile but found "
              + toString (length defaults)
              + optionalString (length defaults > 1) (", namely " + concatStringsSep ", " defaults);
          }
        )

        (
          let
            getContainers =
              profiles: lib.flatten (mapAttrsToList (_: value: (attrValues value.containers)) profiles);

            findInvalidContainerIds =
              profiles:
              lib.filter (container: container.id == 0 || container.id >= 4294967294) (getContainers profiles);
          in
          {
            assertion = cfg.profiles == { } || length (findInvalidContainerIds cfg.profiles) == 0;
            message = "Container id must be between 1 and 4294967293";
          }
        )

        {
          assertion = cfg.languagePacks == [ ] || cfg.package != null;
          message = ''
            '${moduleName}.languagePacks' requires '${moduleName}.package'
            to be set to a non-null value.
          '';
        }

        {
          assertion =
            cfg.globalExtensions == [ ] || cfg.package != null || (isDarwin && cfg.darwinDefaultsId != null);
          message =
            "'${moduleName}.globalExtensions' requires '${moduleName}.package'"
            + " to be set to a non-null value unless"
            + " '${moduleName}.darwinDefaultsId' is set on Darwin.";
        }

        {
          assertion = builtins.all (
            elem:
            let
              package = elem.package or elem;
            in
            package ? addonId
          ) cfg.globalExtensions;
          message = "${moduleName}.globalExtensions requires each package to expose addonId in passthru.";
        }

        (mkNoDuplicateAssertion legacyProfiles "legacy profile")

        {
          assertion =
            selectableProfiles == { }
            || (
              currentStoreId != null
              && lib.elem currentStoreId (map (g: g.storeId) (lib.filter (g: g.profiles != [ ]) groups))
            );
          message = "${moduleName}.currentProfileGroup must select a group containing a selectable profile.";
        }
        {
          assertion = length (lib.unique (map (g: g.storeId) groupDefinitions)) == length groupDefinitions;
          message = "${moduleName}.profileGroups must have unique resolved storeIds.";
        }
        {
          assertion = builtins.all (
            g:
            g.defaultProfile == null
            || (
              builtins.hasAttr g.defaultProfile cfg.profiles
              && resolveStoreId cfg.profiles.${g.defaultProfile}.storeId == g.storeId
            )
          ) groupDefinitions;
          message = "${moduleName}.profileGroups.<name>.defaultProfile must refer to a member of that group.";
        }
        {
          assertion = builtins.all (
            g:
            length (
              lib.filter (p: p.isDefault && resolveStoreId p.storeId == g.storeId) (attrValues selectableProfiles)
            ) <= 1
          ) groupDefinitionsWithImplicit;
          message = "Only one profile in each selectable profile group may have isDefault = true.";
        }
        {
          assertion =
            length (lib.unique (map profileIniPath (attrValues selectableProfiles)))
            == length (attrValues selectableProfiles);
          message = "${moduleName}.selectable profiles must have distinct profile paths.";
        }
        {
          assertion = builtins.all (
            p:
            !(lib.hasPrefix "/" p.path)
            && !(lib.elem ".." (lib.splitString "/" p.path))
            && !(lib.hasInfix "\n" p.path)
            && !(lib.hasInfix "\r" p.path)
            && !(lib.hasInfix "\n" p.name)
            && !(lib.hasInfix "\r" p.name)
          ) (attrValues selectableProfiles);
          message = "${moduleName}.selectable profile paths must be relative without '..'; names and paths may not contain newlines.";
        }
        {
          assertion = builtins.all (
            g: !(lib.hasInfix "\n" g.name) && !(lib.hasInfix "\r" g.name)
          ) groupDefinitions;
          message = "${moduleName}.profileGroups names must not contain newlines.";
        }
        {
          assertion = builtins.all (
            g:
            builtins.all (
              prefName:
              !(lib.elem prefName [
                "browser.profiles.enabled"
                "browser.profiles.created"
                "toolkit.profiles.storeID"
              ])
            ) (lib.attrNames g.sharedSettings)
          ) groupDefinitions;
          message = "${moduleName}.profileGroups sharedSettings cannot override the selectable-profile control preferences.";
        }
      ]
      ++ (lib.concatMap (profile: profile.assertions) (attrValues cfg.profiles));

      targets.darwin.defaults = (
        mkIf (cfg.darwinDefaultsId != null && isDarwin) {
          ${cfg.darwinDefaultsId} = {
            EnterprisePoliciesEnabled = true;
          }
          // cfg.policies;
        }
      );
      home.packages = lib.optional (cfg.finalPackage != null) cfg.finalPackage;

      # Transitioning from selectable profiles back to legacy-only profiles
      # replaces the old writable profiles.ini with a Home Manager symlink.
      # Back it up before linking only if an old ownership marker exists.
      home.activation.prepareLegacyFirefoxProfiles =
        mkIf (!hasSelectableProfiles && cfg.profiles != { })
          (
            lib.hm.dag.entryBefore [ "linkGeneration" ] ''
              run ${lib.getExe pkgs.nushell} --no-config-file ${./profiles/sync-selectable.nu} ${selectableManifest} prepare-legacy-ini
            ''
          );

      # Always run the reconciler. Even with no currently declared selectable
      # groups it must be able to unregister profiles from a previous generation.
      # It is a no-op for a pure legacy installation with no ownership marker.
      home.activation.syncSelectableFirefoxProfiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run ${lib.getExe pkgs.nushell} --no-config-file ${./profiles/sync-selectable.nu} ${selectableManifest}
      '';

      home.file = mkMerge (
        [
          {
            "${cfg.configPath}/profiles.ini" = mkIf (!hasSelectableProfiles && cfg.profiles != { }) {
              text = profilesIni;
            };
          }
        ]
        ++ lib.flip mapAttrsToList cfg.profiles (
          _: profile:
          # Merge the regular profile settings with extension settings
          mkMerge [
            {
              "${cfg.profilesPath}/${profile.path}/.keep".text = "";

              "${cfg.profilesPath}/${profile.path}/chrome/userChrome.css" = mkIf (profile.userChrome != "") (
                let
                  key = if builtins.isString profile.userChrome then "text" else "source";
                in
                {
                  "${key}" = profile.userChrome;
                }
              );

              "${cfg.profilesPath}/${profile.path}/chrome/userContent.css" = mkIf (profile.userContent != "") (
                let
                  key = if builtins.isString profile.userContent then "text" else "source";
                in
                {
                  "${key}" = profile.userContent;
                }
              );

              "${cfg.profilesPath}/${profile.path}/user.js" =
                mkIf
                  (
                    profile.preConfig != ""
                    || profile.settings != { }
                    || profile.extraConfig != ""
                    || profile.bookmarks.configFile != null
                    || extensionSettingsNeedForce profile.extensions.settings
                  )
                  {
                    text =
                      mkUserJs profile.preConfig profile.settings profile.extraConfig profile.bookmarks.configFile
                        profile.extensions.settings;
                  };

              "${cfg.profilesPath}/${profile.path}/containers.json" = mkIf (profile.containers != { }) {
                text = mkContainersJson profile.containers;
                force = profile.containersForce;
              };

              "${cfg.profilesPath}/${profile.path}/search.json.mozlz4" = mkIf (profile.search.enable) {
                inherit (profile.search) enable force;
                source = profile.search.file;
              };

              "${cfg.profilesPath}/${profile.path}/handlers.json" = mkIf (profile.handlers.enable) {
                source = profile.handlers.configFile;
                inherit (profile.handlers) force;
              };

              "${cfg.profilesPath}/${profile.path}/extensions" = mkIf (profile.extensions.packages != [ ]) {
                source =
                  let
                    extensionsEnvPkg = pkgs.buildEnv {
                      name = "hm-firefox-extensions";
                      paths = profile.extensions.packages;
                    };
                  in
                  "${extensionsEnvPkg}/share/mozilla/${extensionPath}";
                recursive = true;
                force = true;
              };
            }

            (mkMerge (
              mapAttrsToList (
                name: settingConfig:
                mkIf (settingConfig.settings != { }) {
                  "${cfg.profilesPath}/${profile.path}/browser-extension-data/${name}/storage.js" = {
                    force = settingConfig.force || profile.extensions.force;
                    text = lib.generators.toJSON { } settingConfig.settings;
                  };
                }
              ) profile.extensions.settings
            ))
          ]
        )
      );
    }
    // setAttrByPath modulePath {
      finalPackage = wrapPackage cfg.package;
      release = mkOptionDefault (builtins.head (lib.splitString "-" cfg.package.version));

      policies = {
        NoDefaultBookmarks = lib.mkIf (builtins.any (profile: profile.bookmarks.enable) (
          builtins.attrValues cfg.profiles
        )) false;
        ExtensionSettings = mkMerge [
          (lib.mkIf (cfg.languagePacks != [ ]) (
            lib.listToAttrs (
              map (
                lang:
                lib.nameValuePair "langpack-${lang}@firefox.mozilla.org" {
                  installation_mode = "normal_installed";
                  install_url = "https://releases.mozilla.org/pub/firefox/releases/${cfg.release}/linux-x86_64/xpi/${lang}.xpi";
                }
              ) cfg.languagePacks
            )
          ))

          (lib.mkIf (cfg.globalExtensions != [ ]) (
            lib.listToAttrs (
              map (
                elem:
                let
                  package = elem.package or elem;
                  settings = elem.settings or { };
                in
                lib.nameValuePair package.addonId (
                  {
                    installation_mode = "force_installed";
                    install_url = "file://${package.outPath}/share/mozilla/${extensionPath}/${package.addonId}.xpi";
                  }
                  // settings
                )
              ) (builtins.filter (elem: (elem.package or elem) ? addonId) cfg.globalExtensions)
            )
          ))
        ];
      };
    }
  );
}
