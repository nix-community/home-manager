{ lib, realPkgs, ... }:
let
  crossPkgs =
    if realPkgs.stdenv.hostPlatform.isAarch64 then
      realPkgs.pkgsCross.gnu64
    else
      realPkgs.pkgsCross.aarch64-multiplatform;
  crossConfig =
    (import ../../../../modules {
      pkgs = crossPkgs;
      configuration = {
        _module.args.pkgs = lib.mkForce crossPkgs;
        home = {
          username = "hm-user";
          homeDirectory = "/home/hm-user";
          stateVersion = "25.11";
        };
        programs = {
          bash.enable = true;
          zsh.enable = true;
          fish.enable = true;
          nushell.enable = true;
          vivid = {
            enable = true;
            activeTheme = "molokai";
          };
        };
      };
    }).config;
  command = builtins.unsafeDiscardStringContext "${lib.getExe crossPkgs.vivid} generate molokai";
in
{
  assertions =
    lib.mapAttrsToList
      (shell: script: {
        assertion = lib.hasInfix command script;
        message = "Vivid must generate colors at runtime when cross-compiling for ${shell}.";
      })
      {
        bash = crossConfig.programs.bash.initExtra;
        zsh = crossConfig.programs.zsh.initContent;
        fish = crossConfig.programs.fish.interactiveShellInit;
        nushell = crossConfig.programs.nushell.extraEnv;
      };
}
