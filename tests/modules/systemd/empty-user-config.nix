{ lib, ... }:

{
  systemd.user.settings = lib.mkForce { };

  nmt.script = ''
    userConf=home-files/.config/systemd/user.conf
    assertPathNotExists $userConf
  '';
}
