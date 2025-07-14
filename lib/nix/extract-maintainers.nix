{
  lib ? import ../../modules/lib/stdlib-extended.nix (import <nixpkgs> { }).lib,
  changedFilesJson ? throw "provide either changedFiles or changedFilesJson",
  changedFiles ? builtins.fromJSON changedFilesJson,
}:
let
  config = { };
  releaseInfo = lib.importJSON ../../release.json;

  extractMaintainersFromFile =
    file:
    let
      isNixFile = lib.hasSuffix ".nix" file;
      filePath = ../../. + "/${file}";
      fileExists = builtins.pathExists filePath;

      moduleResult =
        if isNixFile && fileExists then
          let
            result = builtins.tryEval (
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
            );
          in
          if result.success then result.value else [ ]
        else
          [ ];
    in
    moduleResult;
in
lib.pipe changedFiles [
  (map extractMaintainersFromFile)
  lib.concatLists
  lib.unique
  (map (maintainer: maintainer.github))
]
