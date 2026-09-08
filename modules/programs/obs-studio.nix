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
  iniFormat = pkgs.formats.ini {
    # libobs/util/config-file.c escapes backslashes, CR, and LF in values.
    mkKeyValue = lib.generators.mkKeyValueDefault {
      mkValueString =
        value:
        lib.replaceStrings [ "\\" "\r" "\n" ] [ "\\\\" "\\r" "\\n" ] (
          lib.generators.mkValueStringDefault { } value
        );
    } "=";
  };
  jsonFormat = pkgs.formats.json { };
  pluginPackages = lib.filterAttrs (_: value: lib.isDerivation value) pkgs.obs-studio-plugins;

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

  safePathComponent =
    value: value != "" && value != "." && value != ".." && !(lib.hasInfix "/" value);
  safeRelativePath = path: lib.all safePathComponent (lib.splitString "/" path);
  profileGeneratedPaths =
    profile:
    lib.optionals (profile.settings != { }) [ "basic.ini" ]
    ++ lib.optionals (profile.streamEncoder != { }) [ "streamEncoder.json" ]
    ++ lib.optionals (profile.recordEncoder != { }) [ "recordEncoder.json" ];
  integrationConfigPaths = lib.concatMap (
    name: map (path: "${name}/${path}") (lib.attrNames cfg.integrations.${name}.extraConfigFiles)
  ) (lib.attrNames cfg.integrations);

  generatedFiles =
    lib.optionalAttrs (cfg.settings.global != { }) {
      "global.ini" = iniFormat.generate "obs-studio-global.ini" cfg.settings.global;
    }
    // lib.optionalAttrs (cfg.settings.user != { }) {
      "user.ini" = iniFormat.generate "obs-studio-user.ini" cfg.settings.user;
    }
    // lib.concatMapAttrs (
      name: profile:
      lib.optionalAttrs (profile.settings != { }) {
        "basic/profiles/${name}/basic.ini" = iniFormat.generate "obs-studio-profile.ini" profile.settings;
      }
      // lib.optionalAttrs (profile.streamEncoder != { }) {
        "basic/profiles/${name}/streamEncoder.json" =
          jsonFormat.generate "obs-studio-stream-encoder.json" profile.streamEncoder;
      }
      // lib.optionalAttrs (profile.recordEncoder != { }) {
        "basic/profiles/${name}/recordEncoder.json" =
          jsonFormat.generate "obs-studio-record-encoder.json" profile.recordEncoder;
      }
      // lib.mapAttrs' (path: file: lib.nameValuePair "basic/profiles/${name}/${path}" file.source) (
        lib.filterAttrs (_: file: file.source != null) profile.extraFiles
      )
    ) cfg.profiles
    // lib.mapAttrs' (
      name: collection:
      lib.nameValuePair "basic/scenes/${name}.json" (
        jsonFormat.generate "obs-studio-scene-collection.json" collection
      )
    ) cfg.sceneCollections
    // lib.mapAttrs' (path: file: lib.nameValuePair "plugin_config/${path}" file.source) (
      lib.filterAttrs (_: file: file.source != null) cfg.extraConfigFiles
    )
    // lib.concatMapAttrs (
      name: integration:
      lib.mapAttrs' (path: file: lib.nameValuePair "plugin_config/${name}/${path}" file.source) (
        lib.filterAttrs (_: file: file.source != null) integration.extraConfigFiles
      )
    ) cfg.integrations;

  enabledIntegrationPackages = map (integration: integration.package) (
    lib.filter (integration: integration.enable && integration.package != null) (
      lib.attrValues cfg.integrations
    )
  );
in
{
  meta.maintainers = [ ];

  options.programs.obs-studio = {
    enable = lib.mkEnableOption "obs-studio";
    package = lib.mkPackageOption pkgs "obs-studio" { };
    finalPackage = mkOption {
      type = types.package;
      visible = false;
      readOnly = true;
      description = "Resulting customized OBS Studio package.";
    };
    plugins = mkOption {
      default = [ ];
      example = literalExpression "[ pkgs.obs-studio-plugins.wlrobs ]";
      description = "Optional OBS plugins.";
      type = types.listOf types.package;
    };

    integrations = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }: {
            options = {
              enable = mkOption {
                type = types.bool;
                default = false;
                description = "Whether to install the ${name} OBS Studio plugin.";
              };
              package = mkOption {
                type = types.nullOr types.package;
                default = pluginPackages.${name} or null;
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
            };
          }
        )
      );
      default = { };
      example = literalExpression ''
        { wlrobs.enable = true; }
      '';
      description = ''
        Named plugin packages and their configuration files. Package names
        default to attributes of `pkgs.obs-studio-plugins`; other plugins
        require an explicit package. Files are installed regardless of enable.
      '';
    };

    settings = {
      global = mkOption {
        inherit (iniFormat) type;
        default = { };
        example = {
          General.MaxLogs = 10;
        };
        description = ''
          Configuration written to {file}`$XDG_CONFIG_HOME/obs-studio/global.ini`.
          Files use {option}`home.file.<name>.mutable`: activation replaces
          application edits and removes files that are no longer declared,
          including when OBS is disabled. Existing unmanaged files require
          a Home Manager backup or an explicit `xdg.configFile.<name>.force`.
          Stop OBS before switching generations. Values enter the Nix store;
          do not include secrets such as stream keys or access tokens.
        '';
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
      description = ''
        Profiles installed below {file}`$XDG_CONFIG_HOME/obs-studio/basic/profiles`.
        The attribute name selects the directory; settings are passed through
        without supplying OBS defaults. Files follow the mutable ownership
        contract described in {option}`programs.obs-studio.settings.global`.
      '';
    };

    sceneCollections = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = { };
      example = literalExpression ''
        { Streaming = builtins.fromJSON (builtins.readFile ./Streaming.json); }
      '';
      description = ''
        Scene collection JSON written unchanged to
        {file}`$XDG_CONFIG_HOME/obs-studio/basic/scenes/<name>.json`.
        Files follow the mutable ownership contract described in
        {option}`programs.obs-studio.settings.global`.
      '';
    };

    extraConfigFiles = mkOption {
      type = types.attrsOf fileType;
      default = { };
      description = ''
        Additional writable files installed relative to
        {file}`$XDG_CONFIG_HOME/obs-studio/plugin_config`.
        Files follow the mutable ownership contract described in
        {option}`programs.obs-studio.settings.global`.
      '';
    };
  };

  config = mkIf cfg.enable {
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
          profile:
          lib.intersectLists (lib.attrNames profile.extraFiles) (profileGeneratedPaths profile) == [ ]
        ) (lib.attrValues cfg.profiles);
        message = "programs.obs-studio.profiles.*.extraFiles must not override generated OBS profile files.";
      }
      {
        assertion = lib.all (integration: !integration.enable || integration.package != null) (
          lib.attrValues cfg.integrations
        );
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
        assertion = lib.intersectLists (lib.attrNames cfg.extraConfigFiles) integrationConfigPaths == [ ];
        message = "programs.obs-studio.extraConfigFiles must not override generated integration config files.";
      }
    ];

    home.packages = [ cfg.finalPackage ];
    programs.obs-studio.finalPackage = pkgs.wrapOBS.override { obs-studio = cfg.package; } {
      plugins = lib.unique (cfg.plugins ++ enabledIntegrationPackages);
    };
    xdg.configFile = lib.mapAttrs' (
      path: source:
      lib.nameValuePair "obs-studio/${path}" {
        inherit source;
        mutable = true;
      }
    ) (lib.filterAttrs (path: _: safeRelativePath path) generatedFiles);
  };
}
