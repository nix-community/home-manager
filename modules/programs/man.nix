{ config, lib, ... }:

with lib;

let cfg = config.programs.man;
in {
  imports = [ ./man/man-db.nix ./man/mandoc.nix ];

  options = {
    programs.man = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable manual pages and the {command}`man`
          command. This also includes "man" outputs of all
          `home.packages`.
        '';
      };

      package = mkOption {
        type = types.package;
        description = "The man package to use.";
      };

      generateCaches = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to generate the manual page index caches using
          {manpage}`mandb(8)`. This allows searching for a page or
          keyword using utilities like {manpage}`apropos(1)`.

          This feature is disabled by default because it slows down
          building. If you don't mind waiting a few more seconds when
          Home Manager builds a new generation, you may safely enable
          this option.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = !(cfg.mandoc.enable && cfg.man-db.enable);
      message = ''
        man-db and mandoc can't be used as the man page viewer at the same time!
      '';
    }];

    home.packages = [ cfg.package ];
    home.extraOutputsToInstall = [ "man" ];
  };
}
