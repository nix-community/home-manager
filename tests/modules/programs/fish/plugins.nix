{ lib, pkgs, ... }:
let
  testPlugin = pkgs.runCommandLocal "fish-test-plugin" { } ''
    mkdir -p $out/{functions,completions,conf.d}
    touch $out/{functions/test.fish,completions/test.fish,conf.d/test.fish}
  '';
in
{
  config = {
    programs.fish = {
      enable = true;

      plugins = [ testPlugin ];
    };

    # Needed to avoid error with dummy fish package.
    xdg.dataFile."fish/home-manager_generated_completions".source = lib.mkForce (
      builtins.toFile "empty" ""
    );

    nmt = {
      description = "if fish.plugins set, check conf.d file exists and contents match";
      script = ''
        assertFileExists home-files/.config/fish/functions/test.fish
        assertFileExists home-files/.config/fish/completions/test.fish
        assertFileExists home-files/.config/fish/conf.d/test.fish
      '';
    };
  };
}
