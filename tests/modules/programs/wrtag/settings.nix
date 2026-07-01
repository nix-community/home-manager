{ pkgs, ... }:

{
  config = {
    home.enableNixpkgsReleaseCheck = false;

    programs.wrtag = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-wrtag" "";
      settings = {
        cover-upgrade = true;
        log-level = "debug";
        path-format = "/music/library";
      };
    };

    nmt.script =
      let
        configFile =
          if pkgs.stdenv.hostPlatform.isDarwin then
            "home-files/Library/Application Support/wrtag/config"
          else
            "home-files/.config/wrtag/config";
      in
      ''
        assertFileExists "${configFile}"
        assertFileContent "${configFile}" \
            ${./settings.conf}
      '';
  };
}
