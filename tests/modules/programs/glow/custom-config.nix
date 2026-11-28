{ pkgs, ... }:

{
  config = {
    programs.glow = {
      enable = true;
      settings = {
        style = "auto";
        mouse = false;
        width = 80;
      };
    };

    nmt.script =
      let
        inherit (pkgs.stdenv.hostPlatform) isDarwin;
        configPath =
          if isDarwin then
            "home-files/Library/Preferences/glow/glow.yml"
          else
            "home-files/.config/glow/glow.yml";
      in
      ''
        assertFileExists ${configPath}
        assertFileContent ${configPath} ${./expected-config.yml}
      '';
  };
}
