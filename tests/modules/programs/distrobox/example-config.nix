{
  programs.distrobox = {
    enable = true;
    settings = {
      container_always_pull = "1";
      container_generate_entry = 0;
      container_manager = "docker";
      container_image_default = "registry.opensuse.org/opensuse/toolbox:latest";
      container_name_default = "test-name-1";
      container_user_custom_home = "$HOME/.local/share/container-home-test";
      container_init_hook = "~/.local/distrobox/a_custom_default_init_hook.sh";
      container_pre_init_hook = "~/a_custom_default_pre_init_hook.sh";
      container_manager_additional_flags = "--env-file /path/to/file --custom-flag";
      container_additional_volumes = "/example:/example1 /example2:/example3:ro";
      non_interactive = "1";
      skip_workdir = "0";
    };

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
    assertFileExists home-files/.config/distrobox/distrobox.conf
    assertFileContent home-files/.config/distrobox/distrobox.conf \
    ${./distrobox.conf}

    assertFileExists home-files/.config/distrobox/containers.ini
    assertFileContent home-files/.config/distrobox/containers.ini \
      ${./containers.ini}
  '';
}
