{ config, pkgs, ... }:
let
  targetPath =
    if pkgs.stdenv.isDarwin then
      "home-files/Library/Application Support/senpai/senpai.scfg"
    else
      "home-files/.config/senpai/senpai.scfg";
in
{
  config = {
    programs.senpai = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      config = {
        address = "irc.libera.chat";
        nickname = "Guest123456";
        password-cmd = [
          "gopass"
          "show"
          "irc/guest"
        ];
        username = "senpai";
        realname = "Guest von Lenon";
        channel = [ "#rahxephon" ];
        highlight = [
          "guest"
          "senpai"
          "lenon"
        ];
        pane-widths = {
          nicknames = 16;
        };
        colors = {
          prompt = 2;
        };
      };
    };

    nmt.script = ''
      assertFileContent \
        "${targetPath}" \
        ${./example-settings-expected.conf}
    '';
  };
}
