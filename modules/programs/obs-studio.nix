{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.obs-studio;
  iniFormat = pkgs.formats.ini { };
  jsonFormat = pkgs.formats.json { };
  pluginPackages = lib.filterAttrs (_: value: lib.isDerivation value) pkgs.obs-studio-plugins;
  pluginNames = lib.attrNames pluginPackages;

  fileType = types.submodule (
    { config, ... }:
    {
      options = {
        source = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to the file to install.";
        };

        text = mkOption {
          type = types.nullOr types.lines;
          default = null;
          description = "Text content to install.";
        };
      };

      config.source = mkIf (config.text != null) (
        lib.mkDefault (pkgs.writeText "obs-studio-extra-file" config.text)
      );
    }
  );

  uuidFor =
    seed:
    let
      hash = builtins.hashString "sha256" seed;
    in
    lib.concatStringsSep "-" [
      (builtins.substring 0 8 hash)
      (builtins.substring 8 4 hash)
      (builtins.substring 12 4 hash)
      (builtins.substring 16 4 hash)
      (builtins.substring 20 12 hash)
    ];

  restoreActionValue = {
    prompt = 0;
    skip = 1;
    error = 2;
  };

  renderRestoreRules =
    rules:
    lib.concatStringsSep "\n" (
      map (rule: if rule.scope == "any_app" then "any_app: ${rule.pattern}" else rule.pattern) rules
    );

  safePathComponent =
    value: value != "" && value != "." && value != ".." && !(lib.hasInfix "/" value);
  safeRelativePath =
    path:
    path != ""
    && !(lib.hasPrefix "/" path)
    && lib.all (part: part != "" && part != "." && part != "..") (lib.splitString "/" path);

  profileGeneratedPaths =
    profile:
    lib.optionals (profile.settings != { }) [ "basic.ini" ]
    ++ lib.optionals (profile.streamEncoder != { }) [ "streamEncoder.json" ]
    ++ lib.optionals (profile.recordEncoder != { }) [ "recordEncoder.json" ];

  listIntersection = left: right: lib.filter (value: builtins.elem value right) left;

  integrationConfigPaths = lib.concatMapAttrs (
    pluginName: integration:
    lib.genAttrs (map (path: "${pluginName}/${path}") (lib.attrNames integration.extraConfigFiles)) (
      _: true
    )
  ) cfg.integrations;

  mergeJson = a: b: lib.recursiveUpdate a b;

  portalSettings =
    source:
    lib.optionalAttrs (source.portal.restorePolicyAction != null) {
      RestorePolicyAction = restoreActionValue.${source.portal.restorePolicyAction};
    }
    // lib.optionalAttrs (source.portal.restoreMatchRules != [ ]) {
      RestoreMatchRules = renderRestoreRules source.portal.restoreMatchRules;
    }
    // lib.optionalAttrs (source.portal.restoreToken != null) {
      RestoreToken = source.portal.restoreToken;
    };

  renderSource =
    _collectionName: _name: source:
    mergeJson {
      inherit (source) name;
      inherit (source) uuid;
      inherit (source) id;
      versioned_id = source.versionedId;
      settings = mergeJson source.settings (portalSettings source);
      inherit (source) mixers;
      inherit (source) sync;
      inherit (source) flags;
      inherit (source) volume;
      inherit (source) balance;
      inherit (source) enabled;
      inherit (source) muted;
      push-to-mute = source.pushToMute;
      push-to-mute-delay = source.pushToMuteDelay;
      push-to-talk = source.pushToTalk;
      push-to-talk-delay = source.pushToTalkDelay;
      inherit (source) hotkeys;
      deinterlace_mode = source.deinterlaceMode;
      deinterlace_field_order = source.deinterlaceFieldOrder;
      monitoring_type = source.monitoringType;
      private_settings = source.privateSettings;
      inherit (source) filters;
    } source.raw;

  renderSceneItem =
    collectionName: collection: _index: item:
    let
      resolvedSourceUuid =
        if item.sourceUuid != null then
          item.sourceUuid
        else if builtins.hasAttr item.source collection.sources then
          collection.sources.${item.source}.uuid
        else if builtins.hasAttr item.source collection.scenes then
          collection.scenes.${item.source}.uuid
        else
          uuidFor "${collectionName}:source:${item.source}";
    in
    mergeJson {
      inherit (item) name;
      source_uuid = resolvedSourceUuid;
      inherit (item) visible;
      inherit (item) locked;
      inherit (item) rot;
      scale_ref = item.scaleRef;
      inherit (item) align;
      bounds_type = item.boundsType;
      bounds_align = item.boundsAlign;
      bounds_crop = item.boundsCrop;
      crop_left = item.cropLeft;
      crop_top = item.cropTop;
      crop_right = item.cropRight;
      crop_bottom = item.cropBottom;
      inherit (item) id;
      group_item_backup = item.groupItemBackup;
      inherit (item) pos;
      pos_rel = item.posRel;
      inherit (item) scale;
      scale_rel = item.scaleRel;
      inherit (item) bounds;
      bounds_rel = item.boundsRel;
      scale_filter = item.scaleFilter;
      blend_method = item.blendMethod;
      blend_type = item.blendType;
      show_transition = item.showTransition;
      hide_transition = item.hideTransition;
      private_settings = item.privateSettings;
    } item.raw;

  renderSceneSource =
    collectionName: collection: _sceneName: scene:
    mergeJson {
      inherit (scene) name;
      inherit (scene) uuid;
      id = "scene";
      versioned_id = "scene";
      settings = mergeJson {
        id_counter = lib.length scene.items;
        custom_size = scene.customSize;
        items = lib.imap0 (renderSceneItem collectionName collection) scene.items;
      } scene.settings;
      inherit (scene) mixers;
      sync = 0;
      flags = 0;
      volume = 1.0;
      balance = 0.5;
      enabled = true;
      muted = false;
      push-to-mute = false;
      push-to-mute-delay = 0;
      push-to-talk = false;
      push-to-talk-delay = 0;
      inherit (scene) hotkeys;
      deinterlace_mode = 0;
      deinterlace_field_order = 0;
      monitoring_type = 0;
      private_settings = scene.privateSettings;
    } scene.raw;

  renderSceneCollection =
    name: collection:
    let
      sceneOrder =
        if collection.sceneOrder == [ ] then lib.attrNames collection.scenes else collection.sceneOrder;
    in
    mergeJson {
      inherit (collection) name;
      DesktopAudioDevice1 = collection.desktopAudioDevice;
      AuxAudioDevice1 = collection.auxAudioDevice;
      sources =
        (lib.mapAttrsToList (renderSource name) collection.sources)
        ++ (lib.mapAttrsToList (renderSceneSource name collection) collection.scenes);
      inherit (collection) groups;
      scene_order = map (sceneName: { name = sceneName; }) sceneOrder;
      current_scene = collection.currentScene;
      current_program_scene = collection.currentProgramScene;
      inherit (collection) canvases;
      current_transition = collection.currentTransition;
      transition_duration = collection.transitionDuration;
      inherit (collection) transitions;
      quick_transitions = collection.quickTransitions;
      saved_projectors = collection.savedProjectors;
      preview_locked = collection.previewLocked;
      scaling_enabled = collection.scalingEnabled;
      scaling_level = collection.scalingLevel;
      scaling_off_x = collection.scalingOffX;
      scaling_off_y = collection.scalingOffY;
      virtual-camera = collection.virtualCamera;
      inherit (collection) modules;
      inherit (collection) resolution;
      inherit (collection) version;
    } collection.raw;

  mkGeneratedFile = origin: kind: source: {
    inherit kind origin source;
  };

  generatedFileEntries =
    lib.optionalAttrs (cfg.settings.global != { }) {
      "global.ini" = mkGeneratedFile "settings.global" "ini" (
        iniFormat.generate "obs-studio-global.ini" cfg.settings.global
      );
    }
    // lib.optionalAttrs (cfg.settings.user != { }) {
      "user.ini" = mkGeneratedFile "settings.user" "ini" (
        iniFormat.generate "obs-studio-user.ini" cfg.settings.user
      );
    }
    // lib.concatMapAttrs (
      name: profile:
      lib.optionalAttrs (profile.settings != { }) {
        "basic/profiles/${name}/basic.ini" = mkGeneratedFile "profiles.${name}.settings" "ini" (
          iniFormat.generate "obs-studio-profile-${name}.ini" profile.settings
        );
      }
      // lib.optionalAttrs (profile.streamEncoder != { }) {
        "basic/profiles/${name}/streamEncoder.json" =
          mkGeneratedFile "profiles.${name}.streamEncoder" "json"
            (jsonFormat.generate "obs-studio-stream-encoder-${name}.json" profile.streamEncoder);
      }
      // lib.optionalAttrs (profile.recordEncoder != { }) {
        "basic/profiles/${name}/recordEncoder.json" =
          mkGeneratedFile "profiles.${name}.recordEncoder" "json"
            (jsonFormat.generate "obs-studio-record-encoder-${name}.json" profile.recordEncoder);
      }
      // lib.mapAttrs' (
        path: file:
        lib.nameValuePair "basic/profiles/${name}/${path}" (
          mkGeneratedFile "profiles.${name}.extraFiles.${path}" "raw" file.source
        )
      ) (lib.filterAttrs (_: file: file.source != null) profile.extraFiles)
    ) cfg.profiles
    // lib.mapAttrs' (
      name: collection:
      lib.nameValuePair "basic/scenes/${name}.json" (
        mkGeneratedFile "sceneCollections.${name}" "json" (
          jsonFormat.generate "obs-studio-scene-collection-${name}.json" (
            renderSceneCollection name collection
          )
        )
      )
    ) cfg.sceneCollections
    // lib.mapAttrs' (
      path: file:
      lib.nameValuePair "plugin_config/${path}" (
        mkGeneratedFile "extraConfigFiles.${path}" "raw" file.source
      )
    ) (lib.filterAttrs (_: file: file.source != null) cfg.extraConfigFiles)
    // lib.concatMapAttrs (
      pluginName: integration:
      lib.mapAttrs' (
        path: file:
        lib.nameValuePair "plugin_config/${pluginName}/${path}" (
          mkGeneratedFile "integrations.${pluginName}.extraConfigFiles.${path}" "raw" file.source
        )
      ) (lib.filterAttrs (_: file: file.source != null) integration.extraConfigFiles)
    ) cfg.integrations;

  generatedFiles = lib.mapAttrs (_: file: file.source) generatedFileEntries;

  generatedManifest = jsonFormat.generate "obs-studio-generated-files-manifest.json" {
    version = 1;
    module = "programs.obs-studio";
    files = lib.mapAttrsToList (path: file: {
      inherit path;
      source = toString file.source;
      target = "${config.xdg.configHome}/obs-studio/${path}";
      sha256 = builtins.hashFile "sha256" file.source;
      inherit (file) kind origin;
    }) generatedFileEntries;
  };

  installGeneratedFiles = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      path: source:
      let
        target = "${config.xdg.configHome}/obs-studio/${path}";
      in
      ''
        target=${lib.escapeShellArg target}
        tmp="$target.tmp.$$"
        run mkdir -p "$(dirname "$target")"
        run install -m 0644 ${lib.escapeShellArg source} "$tmp"
        run mv "$tmp" "$target"
      ''
    ) generatedFiles
  );

  installGeneratedManifest =
    let
      target = "${config.xdg.stateHome}/home-manager/obs-studio/manifest.json";
    in
    ''
      target=${lib.escapeShellArg target}
      tmp="$target.tmp.$$"
      run mkdir -p "$(dirname "$target")"
      run install -m 0644 ${lib.escapeShellArg generatedManifest} "$tmp"
      run mv "$tmp" "$target"
    '';

  managedFileCount = lib.length (lib.attrNames generatedFiles);

  enabledIntegrations = lib.filter (integration: integration.enable) (
    lib.attrValues cfg.integrations
  );

  enabledIntegrationPackages = map (integration: integration.package) (
    lib.filter (integration: integration.package != null) enabledIntegrations
  );

  sourceModule =
    collectionName:
    {
      name,
      config,
      ...
    }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
          description = "OBS source display name.";
        };

        uuid = mkOption {
          type = types.str;
          default = uuidFor "${collectionName}:source:${name}";
          description = "OBS source UUID.";
        };

        id = mkOption {
          type = types.str;
          description = "OBS source kind identifier.";
          example = "pipewire-screen-capture-source";
        };

        versionedId = mkOption {
          type = types.str;
          default = config.id;
          defaultText = literalExpression "id";
          description = "OBS versioned source kind identifier.";
        };

        settings = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "OBS source settings JSON.";
        };

        portal = mkOption {
          type = types.submodule {
            options = {
              restorePolicyAction = mkOption {
                type = types.nullOr (
                  types.enum [
                    "prompt"
                    "skip"
                    "error"
                  ]
                );
                default = null;
                example = "skip";
                description = ''
                  Patched PipeWire portal restore failure action. When set,
                  writes OBS's `RestorePolicyAction` setting.
                '';
              };

              restoreMatchRules = mkOption {
                type = types.listOf (
                  types.submodule {
                    options = {
                      pattern = mkOption {
                        type = types.str;
                        description = "Rust regex searched case-insensitively within window titles.";
                      };

                      scope = mkOption {
                        type = types.enum [
                          "same_app"
                          "any_app"
                        ];
                        default = "same_app";
                        description = "Whether the rule is limited to the original application id.";
                      };
                    };
                  }
                );
                default = [ ];
                example = literalExpression ''
                  [
                    { pattern = "project-a"; }
                    { pattern = "shared-title"; scope = "any_app"; }
                  ]
                '';
                description = ''
                  Patched PipeWire portal restore title aliases. Renders to
                  OBS's multiline `RestoreMatchRules` setting.
                '';
              };

              restoreToken = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Machine-local portal restore token. Defaults to null so
                  portable configs do not persist portal tokens.
                '';
              };
            };
          };
          default = { };
          description = "Patched OBS PipeWire portal settings.";
        };

        mixers = mkOption {
          type = types.int;
          default = 0;
          description = "OBS audio mixer bitmask.";
        };

        sync = mkOption {
          type = types.int;
          default = 0;
          description = "OBS source audio sync offset.";
        };

        flags = mkOption {
          type = types.int;
          default = 0;
          description = "OBS source flags.";
        };

        volume = mkOption {
          type = types.float;
          default = 1.0;
          description = "OBS source volume.";
        };

        balance = mkOption {
          type = types.float;
          default = 0.5;
          description = "OBS source stereo balance.";
        };

        enabled = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the source is enabled.";
        };

        muted = mkOption {
          type = types.bool;
          default = false;
          description = "Whether the source is muted.";
        };

        pushToMute = mkOption {
          type = types.bool;
          default = false;
          description = "Whether push-to-mute is enabled.";
        };

        pushToMuteDelay = mkOption {
          type = types.int;
          default = 0;
          description = "Push-to-mute delay.";
        };

        pushToTalk = mkOption {
          type = types.bool;
          default = false;
          description = "Whether push-to-talk is enabled.";
        };

        pushToTalkDelay = mkOption {
          type = types.int;
          default = 0;
          description = "Push-to-talk delay.";
        };

        hotkeys = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "OBS source hotkeys.";
        };

        deinterlaceMode = mkOption {
          type = types.int;
          default = 0;
          description = "OBS deinterlace mode.";
        };

        deinterlaceFieldOrder = mkOption {
          type = types.int;
          default = 0;
          description = "OBS deinterlace field order.";
        };

        monitoringType = mkOption {
          type = types.int;
          default = 0;
          description = "OBS audio monitoring type.";
        };

        privateSettings = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "OBS private source settings.";
        };

        filters = mkOption {
          inherit (jsonFormat) type;
          default = [ ];
          description = "OBS source filters.";
        };

        raw = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "Raw OBS source JSON merged after typed fields.";
        };
      };
    };

  sceneModule =
    collectionName:
    {
      name,
      ...
    }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
          description = "OBS scene display name.";
        };

        uuid = mkOption {
          type = types.str;
          default = uuidFor "${collectionName}:scene:${name}";
          description = "OBS scene source UUID.";
        };

        customSize = mkOption {
          type = types.bool;
          default = false;
          description = "Whether this scene uses a custom size.";
        };

        settings = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "Extra OBS scene settings merged into the generated settings object.";
        };

        items = mkOption {
          type = types.listOf (
            types.submodule (
              { config, ... }:
              {
                options = {
                  source = mkOption {
                    type = types.str;
                    description = "Referenced source name.";
                  };

                  name = mkOption {
                    type = types.str;
                    default = config.source;
                    defaultText = literalExpression "source";
                    description = "Scene item display name.";
                  };

                  sourceUuid = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Explicit source UUID for imported OBS scene items.";
                  };

                  visible = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Whether the scene item is visible.";
                  };

                  locked = mkOption {
                    type = types.bool;
                    default = false;
                    description = "Whether the scene item is locked.";
                  };

                  rot = mkOption {
                    type = types.float;
                    default = 0.0;
                    description = "Scene item rotation.";
                  };

                  scaleRef = mkOption {
                    inherit (jsonFormat) type;
                    default = {
                      x = 0.0;
                      y = 0.0;
                    };
                    description = "OBS scale reference.";
                  };

                  align = mkOption {
                    type = types.int;
                    default = 5;
                    description = "OBS scene item alignment.";
                  };

                  boundsType = mkOption {
                    type = types.int;
                    default = 0;
                    description = "OBS bounds type.";
                  };

                  boundsAlign = mkOption {
                    type = types.int;
                    default = 0;
                    description = "OBS bounds alignment.";
                  };

                  boundsCrop = mkOption {
                    type = types.bool;
                    default = false;
                    description = "Whether bounds cropping is enabled.";
                  };

                  cropLeft = mkOption {
                    type = types.int;
                    default = 0;
                    description = "Left crop.";
                  };

                  cropTop = mkOption {
                    type = types.int;
                    default = 0;
                    description = "Top crop.";
                  };

                  cropRight = mkOption {
                    type = types.int;
                    default = 0;
                    description = "Right crop.";
                  };

                  cropBottom = mkOption {
                    type = types.int;
                    default = 0;
                    description = "Bottom crop.";
                  };

                  id = mkOption {
                    type = types.int;
                    default = 0;
                    description = "OBS scene item id.";
                  };

                  groupItemBackup = mkOption {
                    type = types.bool;
                    default = false;
                    description = "Whether this item is a group item backup.";
                  };

                  pos = mkOption {
                    inherit (jsonFormat) type;
                    default = {
                      x = 0.0;
                      y = 0.0;
                    };
                    description = "Scene item position.";
                  };

                  posRel = mkOption {
                    inherit (jsonFormat) type;
                    default = {
                      x = 0.0;
                      y = 0.0;
                    };
                    description = "Relative scene item position.";
                  };

                  scale = mkOption {
                    inherit (jsonFormat) type;
                    default = {
                      x = 1.0;
                      y = 1.0;
                    };
                    description = "Scene item scale.";
                  };

                  scaleRel = mkOption {
                    inherit (jsonFormat) type;
                    default = {
                      x = 1.0;
                      y = 1.0;
                    };
                    description = "Relative scene item scale.";
                  };

                  bounds = mkOption {
                    inherit (jsonFormat) type;
                    default = {
                      x = 0.0;
                      y = 0.0;
                    };
                    description = "Scene item bounds.";
                  };

                  boundsRel = mkOption {
                    inherit (jsonFormat) type;
                    default = {
                      x = 0.0;
                      y = 0.0;
                    };
                    description = "Relative scene item bounds.";
                  };

                  scaleFilter = mkOption {
                    type = types.str;
                    default = "disable";
                    description = "OBS scale filter.";
                  };

                  blendMethod = mkOption {
                    type = types.str;
                    default = "default";
                    description = "OBS blend method.";
                  };

                  blendType = mkOption {
                    type = types.str;
                    default = "normal";
                    description = "OBS blend type.";
                  };

                  showTransition = mkOption {
                    inherit (jsonFormat) type;
                    default = {
                      duration = 300;
                    };
                    description = "Scene item show transition.";
                  };

                  hideTransition = mkOption {
                    inherit (jsonFormat) type;
                    default = {
                      duration = 300;
                    };
                    description = "Scene item hide transition.";
                  };

                  privateSettings = mkOption {
                    inherit (jsonFormat) type;
                    default = { };
                    description = "Scene item private settings.";
                  };

                  raw = mkOption {
                    inherit (jsonFormat) type;
                    default = { };
                    description = "Raw OBS scene item JSON merged after typed fields.";
                  };
                };
              }
            )
          );
          default = [ ];
          description = "Scene items.";
        };

        mixers = mkOption {
          type = types.int;
          default = 0;
          description = "OBS scene mixer bitmask.";
        };

        hotkeys = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "OBS scene hotkeys.";
        };

        privateSettings = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "OBS scene private settings.";
        };

        raw = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "Raw OBS scene source JSON merged after typed fields.";
        };
      };
    };

  collectionModule =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
          description = "OBS scene collection name.";
        };

        resolution = mkOption {
          inherit (jsonFormat) type;
          default = {
            x = 0;
            y = 0;
          };
          description = "OBS scene collection UI resolution metadata.";
        };

        currentScene = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Current OBS scene name.";
        };

        currentProgramScene = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Current OBS program scene name.";
        };

        sceneOrder = mkOption {
          type = types.listOf types.str;
          default = [ ];
          defaultText = literalExpression "attribute names of scenes";
          description = "Scene order by scene name.";
        };

        currentTransition = mkOption {
          type = types.str;
          default = "Fade";
          description = "Current transition name.";
        };

        transitionDuration = mkOption {
          type = types.int;
          default = 300;
          description = "Current transition duration in milliseconds.";
        };

        quickTransitions = mkOption {
          inherit (jsonFormat) type;
          default = [ ];
          description = "OBS quick transitions JSON.";
        };

        transitions = mkOption {
          inherit (jsonFormat) type;
          default = [ ];
          description = "OBS transitions JSON.";
        };

        groups = mkOption {
          inherit (jsonFormat) type;
          default = [ ];
          description = "OBS groups JSON.";
        };

        canvases = mkOption {
          inherit (jsonFormat) type;
          default = [ ];
          description = "OBS canvases JSON.";
        };

        savedProjectors = mkOption {
          inherit (jsonFormat) type;
          default = [ ];
          description = "OBS saved projectors JSON.";
        };

        previewLocked = mkOption {
          type = types.bool;
          default = false;
          description = "Whether the preview is locked.";
        };

        scalingEnabled = mkOption {
          type = types.bool;
          default = false;
          description = "Whether preview scaling is enabled.";
        };

        scalingLevel = mkOption {
          type = types.int;
          default = 0;
          description = "OBS preview scaling level.";
        };

        scalingOffX = mkOption {
          type = types.float;
          default = 0.0;
          description = "OBS preview X scaling offset.";
        };

        scalingOffY = mkOption {
          type = types.float;
          default = 0.0;
          description = "OBS preview Y scaling offset.";
        };

        virtualCamera = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "OBS virtual camera JSON.";
        };

        modules = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "OBS scene collection module JSON.";
        };

        desktopAudioDevice = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "OBS DesktopAudioDevice1 JSON.";
        };

        auxAudioDevice = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "OBS AuxAudioDevice1 JSON.";
        };

        sources = mkOption {
          type = types.attrsOf (types.submodule (sourceModule name));
          default = { };
          description = "OBS non-scene sources.";
        };

        scenes = mkOption {
          type = types.attrsOf (types.submodule (sceneModule name));
          default = { };
          description = "OBS scenes.";
        };

        raw = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = "Raw OBS scene collection JSON merged after typed fields.";
        };

        version = mkOption {
          type = types.int;
          default = 2;
          description = "OBS scene collection file version.";
        };
      };
    };

  integrationModule =
    {
      name,
      ...
    }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to install the ${name} OBS Studio plugin from nixpkgs.";
        };

        package = mkOption {
          type = types.nullOr types.package;
          default = if builtins.hasAttr name pluginPackages then pluginPackages.${name} else null;
          defaultText = literalExpression "pkgs.obs-studio-plugins.<name>";
          description = "Plugin package to use for this integration.";
        };

        extraConfigFiles = mkOption {
          type = types.attrsOf fileType;
          default = { };
          description = ''
            Additional writable files installed relative to
            {file}`$XDG_CONFIG_HOME/obs-studio/plugin_config/${name}`.
          '';
        };

        settings = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = ''
            Reserved for verified typed settings for this plugin. Unsupported or
            dynamic plugin state should use `extraConfigFiles` or scene/source raw
            JSON until the plugin schema is verified.
          '';
        };
      };
    };
in
{
  meta.maintainers = [ lib.maintainers.adisbladis ];

  options = {
    programs.obs-studio = {
      enable = lib.mkEnableOption "obs-studio";

      package = lib.mkPackageOption pkgs "obs-studio" { };

      finalPackage = lib.mkOption {
        type = lib.types.package;
        visible = false;
        readOnly = true;
        description = "Resulting customized OBS Studio package.";
      };

      plugins = lib.mkOption {
        default = [ ];
        example = lib.literalExpression "[ pkgs.obs-studio-plugins.wlrobs ]";
        description = "Optional OBS plugins.";
        type = lib.types.listOf lib.types.package;
      };

      integrations = mkOption {
        type = types.attrsOf (types.submodule integrationModule);
        default = { };
        example = literalExpression ''
          {
            wlrobs.enable = true;
            obs-websocket = {
              enable = true;
              extraConfigFiles."config.json".text = '''
                {"server_port":4455}
              ''';
            };
          }
        '';
        description = ''
          Named integrations for OBS Studio plugins available in
          `pkgs.obs-studio-plugins`. Supported names in the current nixpkgs are:
          ${lib.concatStringsSep ", " pluginNames}.
        '';
      };

      settings = {
        global = mkOption {
          inherit (iniFormat) type;
          default = { };
          example = literalExpression ''
            {
              General = {
                MaxLogs = 10;
                ProcessPriority = "Normal";
              };
            }
          '';
          description = "Configuration written to {file}`$XDG_CONFIG_HOME/obs-studio/global.ini`.";
        };

        user = mkOption {
          inherit (iniFormat) type;
          default = { };
          description = "Configuration written to {file}`$XDG_CONFIG_HOME/obs-studio/user.ini`.";
        };
      };

      profiles = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              settings = mkOption {
                inherit (iniFormat) type;
                default = { };
                description = "Configuration written to the profile's {file}`basic.ini`.";
              };

              streamEncoder = mkOption {
                inherit (jsonFormat) type;
                default = { };
                description = "Configuration written to the profile's {file}`streamEncoder.json`.";
              };

              recordEncoder = mkOption {
                inherit (jsonFormat) type;
                default = { };
                description = "Configuration written to the profile's {file}`recordEncoder.json`.";
              };

              extraFiles = mkOption {
                type = types.attrsOf fileType;
                default = { };
                description = "Additional writable files installed relative to the OBS profile directory.";
              };
            };
          }
        );
        default = { };
        description = "Declarative OBS profiles.";
      };

      sceneCollections = mkOption {
        type = types.attrsOf (types.submodule collectionModule);
        default = { };
        example = literalExpression ''
          {
            streaming = {
              currentScene = "Main";
              sources.desktop = {
                id = "pipewire-screen-capture-source";
                portal = {
                  restorePolicyAction = "skip";
                  restoreMatchRules = [
                    { pattern = "project-a"; }
                    { pattern = "shared-title"; scope = "any_app"; }
                  ];
                };
              };
              scenes.Main.items = [ { source = "desktop"; } ];
            };
          }
        '';
        description = "Declarative OBS scene collections.";
      };

      extraConfigFiles = mkOption {
        type = types.attrsOf fileType;
        default = { };
        description = ''
          Additional writable files installed relative to
          {file}`$XDG_CONFIG_HOME/obs-studio/plugin_config`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (
          profile: lib.all (file: file.source != null) (lib.attrValues profile.extraFiles)
        ) (lib.attrValues cfg.profiles);
        message = "programs.obs-studio.profiles.*.extraFiles entries must set source or text.";
      }
      {
        assertion = lib.all (file: file.source != null) (lib.attrValues cfg.extraConfigFiles);
        message = "programs.obs-studio.extraConfigFiles entries must set source or text.";
      }
      {
        assertion = lib.all safePathComponent (lib.attrNames cfg.profiles);
        message = "programs.obs-studio.profiles attribute names must be safe relative path components.";
      }
      {
        assertion = lib.all safePathComponent (lib.attrNames cfg.sceneCollections);
        message = "programs.obs-studio.sceneCollections attribute names must be safe relative path components.";
      }
      {
        assertion = lib.all safeRelativePath (lib.attrNames cfg.extraConfigFiles);
        message = "programs.obs-studio.extraConfigFiles attribute names must be safe relative paths.";
      }
      {
        assertion = lib.all (profile: lib.all safeRelativePath (lib.attrNames profile.extraFiles)) (
          lib.attrValues cfg.profiles
        );
        message = "programs.obs-studio.profiles.*.extraFiles attribute names must be safe relative paths.";
      }
      {
        assertion = lib.all (
          profile: listIntersection (lib.attrNames profile.extraFiles) (profileGeneratedPaths profile) == [ ]
        ) (lib.attrValues cfg.profiles);
        message = "programs.obs-studio.profiles.*.extraFiles must not override generated OBS profile files.";
      }
      {
        assertion = lib.all (
          name:
          !cfg.integrations.${name}.enable
          || builtins.hasAttr name pluginPackages
          || cfg.integrations.${name}.package != null
        ) (lib.attrNames cfg.integrations);
        message = "programs.obs-studio.integrations.*.enable requires a matching derivation in pkgs.obs-studio-plugins or an explicit package override.";
      }
      {
        assertion = lib.all (
          integration: lib.all (file: file.source != null) (lib.attrValues integration.extraConfigFiles)
        ) (lib.attrValues cfg.integrations);
        message = "programs.obs-studio.integrations.*.extraConfigFiles entries must set source or text.";
      }
      {
        assertion = lib.all safePathComponent (lib.attrNames cfg.integrations);
        message = "programs.obs-studio.integrations attribute names must be safe relative path components.";
      }
      {
        assertion = lib.all (
          integration: lib.all safeRelativePath (lib.attrNames integration.extraConfigFiles)
        ) (lib.attrValues cfg.integrations);
        message = "programs.obs-studio.integrations.*.extraConfigFiles attribute names must be safe relative paths.";
      }
      {
        assertion =
          listIntersection (lib.attrNames cfg.extraConfigFiles) (lib.attrNames integrationConfigPaths) == [ ];
        message = "programs.obs-studio.extraConfigFiles must not override generated integration config files.";
      }
    ]
    ++ lib.flatten (
      lib.mapAttrsToList (
        collectionName: collection:
        let
          sceneNames = lib.attrNames collection.scenes;
          sourceNames = lib.attrNames collection.sources;
          itemTargetNames = sourceNames ++ sceneNames;
        in
        [
          {
            assertion = collection.currentScene == null || builtins.elem collection.currentScene sceneNames;
            message = "programs.obs-studio.sceneCollections.${collectionName}.currentScene must reference a declared scene.";
          }
          {
            assertion =
              collection.currentProgramScene == null || builtins.elem collection.currentProgramScene sceneNames;
            message = "programs.obs-studio.sceneCollections.${collectionName}.currentProgramScene must reference a declared scene.";
          }
          {
            assertion = lib.all (sceneName: builtins.elem sceneName sceneNames) collection.sceneOrder;
            message = "programs.obs-studio.sceneCollections.${collectionName}.sceneOrder must only reference declared scenes.";
          }
          {
            assertion = lib.all (scene: lib.all (item: builtins.elem item.source itemTargetNames) scene.items) (
              lib.attrValues collection.scenes
            );
            message = "programs.obs-studio.sceneCollections.${collectionName}.scenes.*.items.*.source must reference a declared source.";
          }
          {
            assertion = lib.all (
              source: !(source.settings ? RestoreToken) || source.portal.restoreToken != null
            ) (lib.attrValues collection.sources);
            message = "programs.obs-studio.sceneCollections.${collectionName}.sources.*.settings must not contain RestoreToken unless portal.restoreToken is explicitly set.";
          }
        ]
      ) cfg.sceneCollections
    );

    home.packages = [ cfg.finalPackage ];
    programs.obs-studio.finalPackage = pkgs.wrapOBS.override { obs-studio = cfg.package; } {
      plugins = lib.unique (cfg.plugins ++ enabledIntegrationPackages);
    };

    home.activation.obsStudioConfig = mkIf (managedFileCount > 0) (
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        ${installGeneratedFiles}
        ${installGeneratedManifest}
      ''
    );
  };
}
