{ lib }: {
  hm = (import ../modules/lib/stdlib-extended.nix lib).hm;
  homeManagerConfiguration = { modules ? [ ], pkgs, lib ? pkgs.lib
    , extraSpecialArgs ? { }, check ? true
      # Deprecated:
    , configuration ? null, extraModules ? null, stateVersion ? null
    , username ? null, homeDirectory ? null, system ? null }@args:
    let
      msgForRemovedArg = ''
        The 'homeManagerConfiguration' arguments

          - 'configuration',
          - 'username',
          - 'homeDirectory'
          - 'stateVersion',
          - 'extraModules', and
          - 'system'

        have been removed. Instead use the arguments 'pkgs' and
        'modules'. See the 22.11 release notes for more: https://nix-community.github.io/home-manager/release-notes.xhtml#sec-release-22.11-highlights
      '';

      throwForRemovedArgs = v:
        let
          used = builtins.filter (n: (args.${n} or null) != null) [
            "configuration"
            "username"
            "homeDirectory"
            "stateVersion"
            "extraModules"
            "system"
          ];
          msg = msgForRemovedArg + ''


            Deprecated args passed: '' + builtins.concatStringsSep " " used;
        in lib.throwIf (used != [ ]) msg v;

    in throwForRemovedArgs (import ../modules {
      inherit pkgs lib check extraSpecialArgs;
      configuration = { ... }: {
        imports = modules ++ [{ programs.home-manager.path = "${../.}"; }];
        nixpkgs = {
          config = lib.mkDefault pkgs.config;
          inherit (pkgs) overlays;
        };
      };
    });
}
