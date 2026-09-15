{ pkgs, ... }:

{
  config = {
    home.enableNixpkgsReleaseCheck = false;

    programs.wrtag = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-wrtag" "";
      settings = {
        addon = [
          "replaygain"
          "lyrics lrclib genius"
        ];
        log-level = "info";
        mb-rate-limit = "2s";
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
            ${./addons.conf}
      '';
  };
}
