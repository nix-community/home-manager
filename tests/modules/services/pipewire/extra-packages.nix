{ config, lib, pkgs, ... }:

{
  home.stateVersion = "23.05";

  services.pipewire = {
    enable = true;
    instances.baz = {
      config = ''
        this is a foobar config
      '';
      extraPackages = [ pkgs.calf ];
    };
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/pipewire-instance-baz.service)
    assertFileContent "$serviceFile" ${./extra-packages.service}

    confFile=$(grep -o \
        '/nix/store/.*-pipewire-instance-baz.conf' \
        $TESTED/home-files/.config/systemd/user/pipewire-instance-baz.service | cut -d' ' -f3)
    assertFileContent "$confFile" ${./extra-packages.conf}
  '';
}
