# This module provides JAVA_HOME, with a different way to install java locally.
# This module is modified from the NixOS module `programs.java`
{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.programs.java;

in
{
  meta.maintainers = with lib.maintainers; [ ShamrockLee ];

  options = {
    programs.java = {
      enable = lib.mkEnableOption "" // {
        description = ''
          Install the Java development kit and set the
          {env}`JAVA_HOME` variable.
        '';
      };

      package = lib.mkPackageOption pkgs "java" {
        default = "jdk";
        example = "pkgs.jre";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # some instances of `jdk-linux-base.nix` pass through `result` without turning it onto a path-string.
    # while I suspect this is incorrect, the documentation is unclear.
    home.sessionVariables.JAVA_HOME = "${cfg.package.home}";
  };
}
