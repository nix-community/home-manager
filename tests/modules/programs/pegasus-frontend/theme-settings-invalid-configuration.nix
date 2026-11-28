# Pegasus requires theme settings to be a toplevel JSON object
{
  lib,
  pkgs,
  ...
}:
let
  homeManagerModules = import ../../../../modules/modules.nix {
    inherit lib pkgs;
  };

  evalSettings =
    settingsValue:
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
                  package = pkgs.hello;
                  theme = {
                    package = pkgs.hello;
                    settings = settingsValue;
                  };
                };
              };
            }
          ];
        };
      in
      evaluated.config.programs.pegasus-frontend.theme.settings != null
    );
in
{
  nmt.script = ''
    test "${builtins.toJSON (evalSettings [ 1 ]).success}" = 'false'
    test "${builtins.toJSON (evalSettings 1).success}" = 'false'
    test "${builtins.toJSON (evalSettings { settings = 1; }).success}" = 'true'
  '';
}
