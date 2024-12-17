{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.man;
in {
  options.programs.man.mandoc.enable = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Whether to enable mandoc as the man page viewer.
    '';
  };

  config = mkIf cfg.mandoc.enable (mkMerge [
    { programs.man.package = mkDefault pkgs.mandoc; }
    (mkIf cfg.generateCaches {
      home.activation.generateMandocDB = hm.dag.entryAfter [ "writeBoundary" ]
        (let
          makewhatis = "${getBin cfg.package}/bin/makewhatis";

          manualPages = pkgs.buildEnv {
            name = "man-paths";
            paths = config.home.packages;
            pathsToLink = [ "/share/man" ];
            extraOutputsToInstall = [ "man" ];
            ignoreCollisions = true;
          };
        in ''
          ${makewhatis} ''${DRY_RUN:+-n} ''${VERBOSE:+-Dp} -T utf8 ${manualPages} 2>&1
        '');
    })
  ]);
}
