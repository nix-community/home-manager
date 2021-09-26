{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.fish = {
      enable = true;

      functions = { };
    };

    # Needed to avoid error with dummy fish package.
    xdg.dataFile."fish/home-manager_generated_completions".source =
      lib.mkForce (builtins.toFile "empty" "");

    test.stubs.fish = { };

    nmt = {
      description =
        "if fish.functions is blank, the functions folder should not exist.";
      script = ''
        assertPathNotExists home-files/.config/fish/functions
      '';

    };
  };
}
