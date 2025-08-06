{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.goto;
in
{
  meta.maintainers = [ lib.maintainers.bmrips ];

  options.programs.goto = {
    enable = lib.mkEnableOption "{command}`goto`.";
    package = lib.mkPackageOption pkgs "goto" { };
    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };
    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    programs =
      let
        init = "source ${cfg.package}/share/goto.sh";
      in
      {
        bash.initExtra = lib.mkIf cfg.enableBashIntegration init;
        zsh.initContent = lib.mkIf cfg.enableZshIntegration init;
      };
  };
}
