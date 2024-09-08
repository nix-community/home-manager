{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs = {
      fish.enable = true;

      pls = {
        enable = true;
        enableAliases = true;
        package = config.lib.test.mkStubPackage { outPath = "@pls@"; };
      };
    };

    # Needed to avoid error with dummy fish package.
    xdg.dataFile."fish/home-manager_generated_completions".source =
      mkForce (builtins.toFile "empty" "");

    test.stubs.pls = { };

    nmt.script = ''
      assertFileExists home-files/.config/fish/config.fish
      assertFileContains \
        home-files/.config/fish/config.fish \
        "alias ls @pls@/bin/pls"
      assertFileContains \
        home-files/.config/fish/config.fish \
        "alias ll '@pls@/bin/pls -d perms -d user -d group -d size -d mtime -d git'"
    '';
  };
}
