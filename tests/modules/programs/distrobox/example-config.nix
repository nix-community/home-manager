{
  programs.distrobox = {
    enable = true;
    containers = {

      python-project = {
        image = "fedora:40";
        additional_packages = "python3 git";
        init_hooks = "pip3 install numpy pandas torch torchvision";
      };

      common-debian = {
        image = "debian:13";
        entry = true;
        additional_packages = "git";
        init_hooks = [
          "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker"
          "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker-compose"
        ];
      };

      office = {
        clone = "common-debian";
        additional_packages = "libreoffice onlyoffice";
        entry = true;
      };

      random-things = {
        clone = "common-debian";
        entry = false;
      };

    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/distrobox/containers.ini
    assertFileContent home-files/.config/distrobox/containers.ini \
      ${./example-config.ini}
  '';
}
