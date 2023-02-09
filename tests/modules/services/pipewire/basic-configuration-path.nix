{ config, lib, pkgs, ... }:

{
  home.stateVersion = "23.05";

  services.pipewire = {
    enable = true;
    instances.bar.config = ./basic-configuration-path.conf;
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/pipewire-instance-bar.service)
    assertFileContent "$serviceFile" ${./basic-configuration-path.service}

    confFile=$(grep -o \
        '/nix/store/.*-basic-configuration-path.conf' \
        $TESTED/home-files/.config/systemd/user/pipewire-instance-bar.service | cut -d' ' -f3)
    assertFileContent "$confFile" ${./basic-configuration-path.conf}
  '';
}
