# Pegasus resolves non-URI file entries against the directory of the metadata
# file they are defined in. Generated metadata lives in /nix/store, so relative
# entries would never resolve.
{
  lib,
  pkgs,
  ...
}:
let
  homeManagerModules = import ../../../../modules/modules.nix {
    inherit lib pkgs;
  };

  evalFileEntries =
    collections: games:
    builtins.tryEval (
      let
        evaluated = lib.evalModules {
          specialArgs = { inherit pkgs; };

          modules = homeManagerModules ++ [
            {
              home = {
                username = "hm-user";
                homeDirectory = "/home/hm-user";
                stateVersion = "26.05";
              };
            }
            {
              config = {
                programs.pegasus-frontend = {
                  enable = true;
                  inherit collections games;
                };
              };
            }
          ];
        };
      in
      evaluated.config.xdg.configFile."pegasus-frontend/game_dirs.txt".text != ""
    );

in
{
  nmt.script = ''
    # game file entries
    test "${
      builtins.toJSON
        (evalFileEntries { } [
          {
            title = "g";
            collections = [ "coll" ];
            files = [ "relative.bin" ];
          }
        ]).success
    }" = 'false'
    test "${
      builtins.toJSON
        (evalFileEntries { } [
          {
            title = "g";
            collections = [ "coll" ];
            files = [ "./relative.bin" ];
          }
        ]).success
    }" = 'false'
    # asset entries are checked the same way
    test "${
      builtins.toJSON
        (evalFileEntries { } [
          {
            title = "g";
            collections = [ "coll" ];
            files = [ "/a.bin" ];
            assets = {
              logo = "relative.png";
              logo2 = [
                "/ok.png"
                "./invalid.png"
              ];
            };
          }
        ]).success
    }" = 'false'
    # collection file entries
    test "${
      builtins.toJSON
        (evalFileEntries {
          coll = {
            files = [ "relative.bin" ];
          };
        } [ ]).success
    }" = 'false'
    # absolute entries pass, both as strings and as nix store paths
    test "${
      builtins.toJSON
        (evalFileEntries { } [
          {
            title = "g";
            files = [ "/absolute.bin" ];
          }
        ]).success
    }" = 'true'
    test "${
      builtins.toJSON
        (evalFileEntries { } [
          {
            title = "g";
            files = [ ./fake-image.txt ];
          }
        ]).success
    }" = 'true'
    test "${
      builtins.toJSON
        (evalFileEntries { } [
          {
            title = "g";
            files = [ ./fake-image.txt ];
            assets = {
              logo = [ ./fake-image.txt ];
              tile = ./fake-image.txt;
            };
          }
        ]).success
    }" = 'true'
  '';
}
