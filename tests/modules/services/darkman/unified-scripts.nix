{ config, pkgs, ... }:

{
  services.darkman = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "darkman";
      outPath = "@darkman@";
    };

    scripts.color-scheme = ''
      if [ "$1" = "dark" ]; then
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
      else
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
      fi
    '';
  };

  nmt.script = ''
    scriptFile=$(normalizeStorePaths home-files/.local/share/darkman/color-scheme)

    assertFileExists $scriptFile
    assertFileContent $scriptFile ${builtins.toFile "expected" ''
      #!/nix/store/00000000000000000000000000000000-bash/bin/bash
      if [ "$1" = "dark" ]; then
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
      else
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
      fi

    ''}
  '';
}
