{ ... }: {
  programs.lazydocker = {
    enable = true;
    settings = {
      commandTemplates.dockerCompose = "docker compose";
      gui.theme = {
        activeBorderColor = [ "red" "bold" ];
        inactiveBorderColor = [ "blue" ];
      };
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/lazydocker/config.yml
    assertFileContent home-files/.config/lazydocker/config.yml \
      ${./custom-settings.yml}
  '';
}
