{ pkgs, ... }:

{
  config = {
    programs.wrtag = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-wrtag" "";
      settings = {
        cover-upgrade = true;
        log-level = "debug";
        path-format = "/music/library";
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/wrtag/config
      assertFileContent home-files/.config/wrtag/config \
          ${./settings.conf}
    '';
  };
}
