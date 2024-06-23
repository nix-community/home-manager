{ config, ... }: {
  config = {
    programs.fish = {
      enable = true;

      shellBinds = {
        "\\cd" = "exit";
        "." = "rationalise-dot";
        "\\cg" = "git diff; commandline -f repaint";
        "\\cz" = "foo && bar";
      };
    };

    nmt = {
      description =
        "if fish.shellBinds is set, check fish.config contains bindings";
      script = ''
        assertFileContains home-files/.config/fish/config.fish \
          "bind \cd exit"
        assertFileContains home-files/.config/fish/config.fish \
          "bind . rationalise-dot"
        assertFileContains home-files/.config/fish/config.fish \
          "bind \cg 'git diff; commandline -f repaint'"
        assertFileContains home-files/.config/fish/config.fish \
          "bind \cz 'foo && bar'"
      '';
    };
  };
}
