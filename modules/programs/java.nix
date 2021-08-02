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
          Install the Java development kit and set the <envar>JAVA_HOME</envar>
          variable.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.jdk;
        defaultText = "pkgs.jdk";
        description = ''
          Java package to install. Typical values are
          <literal>pkgs.jdk</literal> or <literal>pkgs.jre</literal>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.sessionVariables = {
      JAVA_HOME = fileContents (pkgs.runCommandLocal "java-home" { } ''
        source "${cfg.package}/nix-support/setup-hook"
        echo "$JAVA_HOME" > $out
      '');
    };
  };
}
