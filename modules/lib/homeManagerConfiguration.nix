lib: args:
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
    'modules'. See the 22.11 release notes for more: https://nix-community.github.io/home-manager/release-notes.html#sec-release-22.11-highlights
  '';
  used = builtins.filter (n: (args.${n} or null) != null) [
    "configuration"
    "username"
    "homeDirectory"
    "stateVersion"
    "extraModules"
    "system"
  ];
  msg = msgForRemovedArg + ''
    Deprecated args passed:
  '' + builtins.concatStringsSep " " used;

  throwForRemovedArgs = v: lib.throwIf (used != [ ]) msg (v args);
in throwForRemovedArgs ({ modules ? [ ], nixpkgs ? null, extraSpecialArgs ? { }
  , check ? true,
  # Deprecated:
  pkgs ? null, ... }:
  let
    pkgsPath = if nixpkgs != null then
      (if (nixpkgs._type or "") == "flake" then
        nixpkgs.outPath
      else
        toString nixpkgs)
    else if (pkgs != null) then
      lib.warn ''
        Passing pkgs to lib.homeManagerConfiguration is deprecated
        instead pass nixpkgs directly and ensure nixpkgs.system is set
      '' pkgs.path
    else
      throw ''
        Neither nixpkgs or pkgs is passed to lib.homeManagerConfiguration!
      '';
  in import ../. {

    inherit extraSpecialArgs check pkgsPath;
    modules = modules ++

      lib.optional (pkgs != null && nixpkgs == null) {

        nixpkgs = {
          system = lib.mkDefault pkgs.hostPlatform;
          config = lib.mkDefault pkgs.config;
          inherit (pkgs) overlays;
        };
      };
  })
