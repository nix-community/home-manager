{
  programs.grype = {
    enable = true;
    settings = {
      search = {
        scope = "squashed";
      };
      match = {
        java = {
          using-cpes = false;
        };
      };
      check-for-app-update = false;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/grype/config.yaml
    assertFileContent home-files/.config/grype/config.yaml ${./basic-configuration.yaml}
  '';
}
