{
  programs.grype = {
    enable = true;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/grype/config.yaml
  '';
}
