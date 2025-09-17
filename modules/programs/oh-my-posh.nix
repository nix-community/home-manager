{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.oh-my-posh;

  jsonFormat = pkgs.formats.json { };

  configArgument =
    if cfg.settings != { } then
      "--config ${config.xdg.configHome}/oh-my-posh/config.json"
    else if cfg.useTheme != null then
      "--config ${cfg.package}/share/oh-my-posh/themes/${cfg.useTheme}.omp.json"
    else if cfg.configFile != null then
      "--config ${cfg.configFile}"
    else
      "";

in
{
  meta.maintainers = [ lib.maintainers.arjan-s ];

  options.programs.oh-my-posh = {
    enable = lib.mkEnableOption "oh-my-posh, a prompt theme engine for any shell";

    package = lib.mkPackageOption pkgs "oh-my-posh" { };

    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      example = lib.literalExpression ''builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile "''${pkgs.oh-my-posh}/share/oh-my-posh/themes/space.omp.json"))'';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/oh-my-posh/config.json`. See
        <https://ohmyposh.dev/docs/configuration/overview>
        for details. The `useTheme` option is ignored when this
        option is used.
      '';
    };

    useTheme = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Use one of the official themes. This should be a name from this list:
        <https://ohmyposh.dev/docs/themes>. Because a theme
        is essentially a configuration file, this option is not used when a
        `configFile` is set.
      '';
    };

    configFile = lib.mkOption {
      type = with lib.types; nullOr (either str path);
      default = null;
      description = ''
        Path to a custom configuration path, can be json, yaml or toml.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          lib.count (x: x) [
            (cfg.settings != { })
            (cfg.useTheme != null)
            (cfg.configFile != null)
          ] <= 1;
        message = "oh-my-posh: Only one of 'settings', 'useTheme', or 'configFile' can be configured at a time.";
      }
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."oh-my-posh/config.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "oh-my-posh-settings" cfg.settings;
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${lib.getExe cfg.package} init bash ${configArgument})"
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(${lib.getExe cfg.package} init zsh ${configArgument})"
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      ${lib.getExe cfg.package} init fish ${configArgument} | source
    '';

    programs.nushell = mkIf cfg.enableNushellIntegration {
      extraConfig = ''
        ${
          if lib.versionAtLeast (lib.versions.major cfg.package.version) "26" then
            "${lib.getExe cfg.package} init nu ${configArgument}"
          else
            ''source ${
              pkgs.runCommand "oh-my-posh-nushell-config.nu" { } ''
                ${lib.getExe cfg.package} init nu ${configArgument} --print >> "$out"
              ''
            }''
        }
      '';
    };

    # Clear oh-my-posh cache when the oh-my-posh package derivation changes
    home.activation.ohMyPoshClearCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      nixver="${config.programs.oh-my-posh.package}"
      cache="${config.xdg.cacheHome}/oh-my-posh"
      state="$cache/pkg-path"

      if [ ! -f "$state" ] || [ "$(cat "$state")" != "$nixver" ]; then
        rm -rf "$cache"
      fi

      mkdir -p "$cache"
      printf '%s' "$nixver" > "$state"
    '';

  };
}
