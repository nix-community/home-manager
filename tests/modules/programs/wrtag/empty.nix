{ pkgs, ... }:

{
  config = {
    home.enableNixpkgsReleaseCheck = false;

    programs.wrtag = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-wrtag" "";
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
        assertPathNotExists "${configFile}"
      '';
  };
}
