{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.omniwm;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [ davsanchez ];

  options.programs.omniwm = {
    enable = lib.mkEnableOption "OmniWM window manager";

    package = lib.mkPackageOption pkgs "omniwm" { };

    launchd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to manage OmniWM with a launchd agent.";
      };

      keepAlive = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the launchd agent should be kept alive.";
      };
    };

    settings = lib.mkOption {
      type = with lib.types; either path tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        # Attrset (serialized to TOML)
        {
          general = {
            updateChecksEnabled = false;
          };
        }

        # Or a path to an existing TOML file
        ./omniwm-settings.toml
      '';
      description = ''
        OmniWM settings written to
        {file}`$XDG_CONFIG_HOME/omniwm/settings.toml`.

        Either a path to a TOML file or an attrset that will be
        serialized to TOML. The path form is useful when the file is
        managed as a template (e.g. in a dotfiles repository), since
        OmniWM rewrites this file from its GUI and replaces symlinks
        with regular files.

        See <https://github.com/BarutSRB/OmniWM> for configuration
        details.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.omniwm" pkgs lib.platforms.darwin)
    ];

    home.packages = [ cfg.package ];

    launchd.agents.omniwm = {
      inherit (cfg.launchd) enable;
      config = {
        Program = "${cfg.package}/Applications/OmniWM.app/Contents/MacOS/OmniWM";
        KeepAlive = cfg.launchd.keepAlive;
        RunAtLoad = true;
        StandardOutPath = "/tmp/omniwm.log";
        StandardErrorPath = "/tmp/omniwm.err.log";
      };
    };

    # OmniWM rewrites `settings.toml` from the GUI, replacing this
    # symlink with a regular file. `force = true` makes the next switch
    # re-link the declarative template (from the Nix store) over that
    # file instead of failing with a clobber error. The template is the
    # source of truth: any GUI change you want to keep must be mirrored
    # into it.
    xdg.configFile."omniwm/settings.toml" = lib.mkIf (cfg.settings != { }) {
      source =
        if lib.hm.strings.isPathLike cfg.settings then
          cfg.settings
        else
          tomlFormat.generate "omniwm-settings.toml" cfg.settings;
      force = true;
    };
  };
}
