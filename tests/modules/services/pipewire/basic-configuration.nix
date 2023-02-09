{ config, lib, pkgs, ... }:

{
  home.stateVersion = "23.05";

  services.pipewire = {
    enable = true;
    instances.foo.config = ''
      this is a dummy config
    '';
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/pipewire-instance-foo.service)
    assertFileContent "$serviceFile" ${./basic-configuration.service}

    confFile=$(grep -o \
        '/nix/store/.*-pipewire-instance-foo.conf' \
        $TESTED/home-files/.config/systemd/user/pipewire-instance-foo.service | cut -d' ' -f3)
    assertFileContent "$confFile" ${./basic-configuration.conf}
  '';
}
