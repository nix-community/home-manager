{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.tealdeer;

  tomlFormat = pkgs.formats.toml { };

  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support"
  else
    config.xdg.configHome;

in {
  meta.maintainers = [ ];

  options.programs.tealdeer = {
    enable = mkEnableOption "Tealdeer";

    updateOnActivation = mkOption {
      type = with types; bool;
      default = true;
      description = ''
        Whether to update tealdeer's cache on activation.
      '';
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      defaultText = literalExpression "{ }";
      example = literalExpression ''
        {
          display = {
            compact = false;
            use_pager = true;
          };
          updates = {
            auto_update = false;
          };
        };
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/tealdeer/config.toml` on Linux or
        {file}`$HOME/Library/Application Support/tealdeer/config.toml`
        on Darwin. See
        <https://dbrgn.github.io/tealdeer/config.html>
        for more information.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.tealdeer ];

    home.file."${configDir}/tealdeer/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "tealdeer-config" cfg.settings;
    };

    home.activation = mkIf cfg.updateOnActivation {
      tealdeerCache = hm.dag.entryAfter [ "linkGeneration" ] ''
        $VERBOSE_ECHO "Rebuilding tealdeer cache"
        $DRY_RUN_CMD ${getExe pkgs.tealdeer} --update
      '';
    };
  };
}
