{
  config,
  lib,
  options,
  ...
}:

{
  programs = {
    atuin = {
      enable = true;
      enableZshIntegration = true;
      package = config.lib.test.mkStubPackage { name = "atuin"; };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      package = config.lib.test.mkStubPackage {
        name = "fzf";
        version = "0.73.0";
      };
    };

    zsh.enable = true;
  };

  test.asserts.warnings.expected = [
    ''
      programs.fzf and a history manager both configure Ctrl-R for zsh.

      Definitions:
        zsh:
          `programs.fzf.enable` defined in ${lib.showFiles options.programs.fzf.enable.files}
          `programs.atuin.enable` defined in ${lib.showFiles options.programs.atuin.enable.files}

      The history manager integration is sourced after fzf and owns Ctrl-R.
      Choose which integration should own Ctrl-R.
      To keep the history manager on Ctrl-R, disable fzf's binding:
        programs.fzf.historyWidget.command = "";
      or disable it for one shell:
        programs.fzf.historyWidget.zsh.command = "";
      To keep fzf on Ctrl-R with Atuin, disable Atuin's Ctrl-R binding:
        programs.atuin.flags = [ "--disable-ctrl-r" ];
      McFly has no Ctrl-R-only option in Home Manager. Disable McFly's
      shell integration for that shell if fzf should own Ctrl-R.
      To use another key, disable one default Ctrl-R binding and add a
      shell-specific key binding in your shell configuration.
    ''
  ];

  nmt.script = ''
    assertFileExists home-files/.zshrc
  '';
}
