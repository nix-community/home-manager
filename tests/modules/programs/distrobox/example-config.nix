{
  programs.distrobox = {
    enable = true;

    containers = {
      python-project = {
        image = "debian:latest";
        nvidia = true;
        root = true;
        additional_packages = "git python3";
      };

      office = {
        image = "fedora:40";
        additional_packages = "libreoffice onlyoffice";
        pull = true;
        init = true;
      };

      testing = {
        image = "archlinux:latest";
        home = "/tmp/tmp-home";
        replace = true;
        pull = true;
        volume = "/tmp/test1:/mnt/test1 /tmp/test2:/mnt/test2";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/distrobox/containers.ini
    assertFileContent home-files/.config/distrobox/containers.ini \
      ${./example-config.ini}
  '';
}
