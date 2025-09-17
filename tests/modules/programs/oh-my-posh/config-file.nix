{
  programs = {
    bash.enable = true;

    oh-my-posh = {
      enable = true;
      configFile = "/etc/oh-my-posh/custom.json";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      '/bin/oh-my-posh init bash --config /etc/oh-my-posh/custom.json'
  '';
}
