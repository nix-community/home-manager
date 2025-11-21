{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.hstr;
in
{
  meta.maintainers = [ lib.hm.maintainers.Dines97 ];

  options.programs.hstr = {
    enable = lib.mkEnableOption ''
      Bash And Zsh shell history suggest box - easily view, navigate, search and
      manage your command history'';

    package = lib.mkPackageOption pkgs "hstr" { };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
      eval "$(${cfg.package}/bin/hstr --show-configuration)"
    '';

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/hstr --show-zsh-configuration)"
    '';
  };
}
