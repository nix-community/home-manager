{ config, lib, ... }:

{
  services.shpool = {
    enable = true;
    systemd = false;
    settings.motd = "never";
  };

  test.stubs.shpool = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/systemd/user/shpool.service
    assertPathNotExists home-files/.config/systemd/user/shpool.socket
    assertFileRegex home-files/.config/shpool/config.toml '^motd = "never"$'
    if [[ ${lib.boolToString (lib.elem config.services.shpool.package config.home.packages)} != true ]]; then
      fail "Expected shpool to be installed"
    fi
  '';
}
