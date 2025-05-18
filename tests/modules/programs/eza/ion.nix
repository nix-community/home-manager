{
  programs = {
    ion.enable = true;

    eza = {
      enable = true;
      enableIonIntegration = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
      icons = "auto";
      git = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/ion/initrc
    assertFileContains \
      home-files/.config/ion/initrc \
      "alias eza = 'eza --icons auto --git --group-directories-first --header'"
    assertFileContains \
      home-files/.config/ion/initrc \
      "alias ls = eza"
    assertFileContains \
      home-files/.config/ion/initrc \
      "alias ll = 'eza -l'"
    assertFileContains \
      home-files/.config/ion/initrc \
      "alias la = 'eza -a'"
    assertFileContains \
      home-files/.config/ion/initrc \
      "alias lt = 'eza --tree'"
    assertFileContains \
      home-files/.config/ion/initrc \
      "alias lla = 'eza -la'"
  '';
}
