{ pkgs, ... }:

{
  programs.amber = {
    enable = true;
    ambsSettings = {
      column = true;
      binary = true;
      skipped = true;
      recursive = false;
    };
    ambrSettings = {
      regex = true;
      row = true;
      statistics = true;
      interactive = false;
    };
  };

  nmt.script =
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Preferences/com.github.dalance.amber"
        else
          ".config/amber";
    in
    ''
      assertFileExists "home-files/${configDir}/ambs.toml"
      assertFileContent "home-files/${configDir}/ambs.toml" \
        ${./ambs.toml}

      assertFileExists "home-files/${configDir}/ambr.toml"
      assertFileContent "home-files/${configDir}/ambr.toml" \
        ${./ambr.toml}
    '';
}
