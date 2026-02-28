{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.prek;
  exe = lib.getExe cfg.package;
in
{
  meta.maintainers = with lib.maintainers; [ ilkecan ];

  options.programs.prek = {
    enable = lib.mkEnableOption "prek, a pre-commit alternative re-engineered in Rust";

    package = lib.mkPackageOption pkgs "prek" { };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
      eval "$(COMPLETE=bash ${exe})"
    '';

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      eval "$(COMPLETE=zsh ${exe})"
    '';

    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
      COMPLETE=fish ${exe} | source
    '';
  };
}
