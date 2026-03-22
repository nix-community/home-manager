{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.worktrunk;
  package = pkgs.worktrunk;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.wcarlsen ];

  options.programs.worktrunk = {
    enable = lib.mkEnableOption "worktrunk";

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          skip-shell-integration-prompt = true;
          post-start = {
            copy = "wt step copy-ignored";
          };
        };
      '';
      description = ''
        Configuration written to `$XDG_CONFIG_HOME/worktrunk/config.toml`.
      '';
    };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];

    xdg.configFile."worktrunk/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      eval "$(${package}/bin/wt config shell init zsh)"
    '';
  };
}
