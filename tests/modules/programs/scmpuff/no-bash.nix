{
  programs = {
    scmpuff = {
      enable = true;
      enableBashIntegration = false;
    };
    bash.enable = true;
  };

  nmt.script = ''
    assertFileNotRegex home-files/.bashrc '@scmpuff@'
  '';
}
