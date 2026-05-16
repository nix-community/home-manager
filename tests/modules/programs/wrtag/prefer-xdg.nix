{ pkgs, ... }:

{
  config = {
    home.enableNixpkgsReleaseCheck = false;
    home.preferXdgDirectories = true;

    programs.wrtag = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-wrtag" "";
      settings = {
        path-format = "/music/library";
        log-level = "debug";
      };
    };

    nmt.script = ''
      assertFileExists "home-files/.config/wrtag/config"
      assertPathNotExists "home-files/Library/Application Support/wrtag/config"
    '';
  };
}
