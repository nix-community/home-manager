{
  lib ? import ../../modules/lib/stdlib-extended.nix (import <nixpkgs> { }).lib,
  file ? throw "provide file argument",
}:
let
  config = { };
  releaseInfo = lib.importJSON ../../release.json;

  isNixFile = lib.hasSuffix ".nix" file;
  filePath = ../../. + "/${file}";
  fileExists = builtins.pathExists filePath;

  maintainers =
    if isNixFile && fileExists then
      let
        fileContent = import filePath;

        module =
          if lib.isFunction fileContent then
            # TODO: Find a better way of handling this...
            if lib.hasPrefix "docs/" file then
              if lib.hasSuffix "home-manager-manual.nix" file then
                fileContent {
                  stdenv = {
                    mkDerivation = x: x;
                  };
                  inherit lib;
                  documentation-highlighter = { };
                  revision = "unknown";
                  home-manager-options = {
                    home-manager = { };
                    nixos = { };
                    nix-darwin = { };
                  };
                  nixos-render-docs = { };
                }
              else
                fileContent {
                  inherit lib;
                  pkgs = null;
                  inherit (releaseInfo) release isReleaseBranch;
                }
            else if lib.hasPrefix "lib/" file then
              fileContent { inherit lib; }
            else
              fileContent {
                inherit lib config;
                pkgs = null;
              }
          else
            fileContent;
      in
      module.meta.maintainers or [ ]
    else
      [ ];

in
map (maintainer: maintainer.github) maintainers
