{ pkgs, ... }:

{
  config = {
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

    nmt.script = ''
      assertFileExists home-files/.config/wrtag/config
      assertFileContent home-files/.config/wrtag/config \
          ${./addons.conf}
    '';
  };
}
