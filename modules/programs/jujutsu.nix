{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.jujutsu;
  tomlFormat = pkgs.formats.toml { };
  minimumMutableVersion = if pkgs.stdenv.hostPlatform.isDarwin then "0.29.0" else "0.28.0";
  packageVersion = if cfg.package != null then lib.getVersion cfg.package else "0.29.0";

  # jj v0.29+ deprecated support for "~/Library/Application Support" on Darwin.
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin && !(lib.versionAtLeast packageVersion "0.29.0") then
      "Library/Application Support"
    else
      config.xdg.configHome;
  userConfigDir =
    if lib.hasPrefix "/" configDir then configDir else "${config.home.homeDirectory}/${configDir}";
in
{
  meta.maintainers = [ lib.maintainers.shikanime ];

  imports =
    let
      mkRemovedShellIntegration =
        name:
        lib.mkRemovedOptionModule [
          "programs"
          "jujutsu"
          "enable${name}Integration"
        ] "This option is no longer necessary.";
    in
    map mkRemovedShellIntegration [
      "Bash"
      "Fish"
      "Zsh"
    ];

  options.programs.jujutsu = {
    enable = lib.mkEnableOption "a Git-compatible DVCS that is both simple and powerful";

    package = lib.mkPackageOption pkgs "jujutsu" { nullable = true; };

    mutableSettings = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        Whether to put declarative settings in {file}`jj/conf.d/home-manager.toml`,
        leaving {file}`jj/config.toml` writable by Jujutsu. The fragment overrides
        the user file. Requires Jujutsu 0.28 or later (0.29 or later on Darwin).
        When {option}`programs.jujutsu.package` is null, the externally installed
        Jujutsu is assumed to meet this requirement.

        An empty user file is created if absent so that {command}`jj config set --user`
        does not select the read-only fragment. An existing {file}`~/.jjconfig.toml`
        remains the first user file; {env}`JJ_CONFIG` overrides default discovery.

        Before disabling this option while {option}`programs.jujutsu.settings`
        is non-empty, remove or back up the mutable {file}`jj/config.toml`.
        Home Manager otherwise treats it as a file collision.
      '';
    };

    ediff = mkOption {
      type = types.bool;
      default = config.programs.emacs.enable;
      defaultText = lib.literalExpression "config.programs.emacs.enable";
      description = ''
        Enable ediff as a merge tool
      '';
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        user = {
          name = "John Doe";
          email = "jdoe@example.org";
        };
      };
      description = ''
        Options to add to the {file}`config.toml` file. See
        <https://github.com/martinvonz/jj/blob/main/docs/config.md>
        for options.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          !cfg.mutableSettings
          || cfg.package == null
          || lib.versionAtLeast packageVersion minimumMutableVersion;
        message = "programs.jujutsu.mutableSettings requires programs.jujutsu.package version ${minimumMutableVersion} or later.";
      }
    ];

    home = {
      packages = mkIf (cfg.package != null) [ cfg.package ];

      activation.jujutsu-user-config = mkIf (cfg.mutableSettings && cfg.settings != { }) (
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          if [[ ! -e ${lib.escapeShellArg "${userConfigDir}/jj/config.toml"} && ! -L ${lib.escapeShellArg "${userConfigDir}/jj/config.toml"} ]]; then
            run mkdir -p ${lib.escapeShellArg "${userConfigDir}/jj"}
            run touch ${lib.escapeShellArg "${userConfigDir}/jj/config.toml"}
          fi
        ''
      );

      file."${configDir}/jj/${
        if cfg.mutableSettings then "conf.d/home-manager.toml" else "config.toml"
      }" =
        mkIf (cfg.settings != { }) {
          source = tomlFormat.generate "jujutsu-config" cfg.settings;
        };
    };

    programs.jujutsu.settings = lib.mkMerge [
      (lib.mkIf cfg.ediff {
        merge-tools.ediff =
          let
            emacsDiffScript = pkgs.writeShellScriptBin "emacs-ediff" ''
              set -euxo pipefail
              ${config.programs.emacs.package}/bin/emacsclient -c --eval "(ediff-merge-files-with-ancestor \"$1\" \"$2\" \"$3\" nil \"$4\")"
            '';
          in
          {
            program = lib.getExe emacsDiffScript;
            merge-args = [
              "$left"
              "$right"
              "$base"
              "$output"
            ];
          };
      })
    ];

  };
}
