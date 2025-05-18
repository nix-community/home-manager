{
  programs = {
    bash.enable = true;

    eza = {
      enable = true;
      enableBashIntegration = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
      icons = "auto";
      git = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      "alias eza='eza --icons auto --git --group-directories-first --header'"
    assertFileContains \
      home-files/.bashrc \
      "alias ls=eza"
    assertFileContains \
      home-files/.bashrc \
      "alias ll='eza -l'"
    assertFileContains \
      home-files/.bashrc \
      "alias la='eza -a'"
    assertFileContains \
      home-files/.bashrc \
      "alias lt='eza --tree'"
    assertFileContains \
      home-files/.bashrc \
      "alias lla='eza -la'"
  '';
}
