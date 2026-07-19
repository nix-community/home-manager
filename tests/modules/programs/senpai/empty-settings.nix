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
      };
    };

    nmt.script = ''
      assertFileContent \
        "${targetPath}" \
        ${./empty-settings-expected.conf}
    '';
  };
}
