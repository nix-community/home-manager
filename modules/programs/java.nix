# This module provides JAVA_HOME, with a different way to install java locally.
# This module is modified from the NixOS module `programs.java`

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.java;

in {
  meta.maintainers = with maintainers; [ ShamrockLee ];

  options = {
    programs.java = {
      enable = mkEnableOption "" // {
        description = ''
          Install the Java development kit and set the
          {env}`JAVA_HOME` variable.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.jdk;
        defaultText = "pkgs.jdk";
        description = ''
          Java package to install. Typical values are
          `pkgs.jdk` or `pkgs.jre`.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # some instances of `jdk-linux-base.nix` pass through `result` without turning it onto a path-string.
    # while I suspect this is incorrect, the documentation is unclear.
    home.sessionVariables.JAVA_HOME = "${cfg.package.home}";
  };
}
