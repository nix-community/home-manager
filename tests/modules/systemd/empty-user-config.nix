{ pkgs, ... }:

{
  nmt.script = ''
    userConf=home-files/.config/systemd/user.conf
    assertPathNotExists $userConf
  '';
}
