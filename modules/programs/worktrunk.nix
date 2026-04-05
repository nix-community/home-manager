{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.worktrunk;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.wcarlsen ];

  options.programs.worktrunk = {
    enable = lib.mkEnableOption "worktrunk";

    package = lib.mkPackageOption pkgs "worktrunk" { nullable = true; };

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

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."worktrunk/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
      eval "$(${lib.getExe cfg.package} config shell init bash)"
    '';

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      eval "$(${lib.getExe cfg.package} config shell init zsh)"
    '';

    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
      ${lib.getExe cfg.package} config shell init fish | source
    '';
  };
}
