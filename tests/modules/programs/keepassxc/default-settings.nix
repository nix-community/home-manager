{ pkgs, ... }:

let
  configFile =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/Application Support/KeePassXC/keepassxc.ini"
    else
      "home-files/.config/keepassxc/keepassxc.ini";
in
{
  programs.keepassxc = {
    enable = true;
  };

  test.stubs.keepassxc = { };

  nmt.script = ''
    assertPathNotExists "${configFile}"
  '';
}
