{
  config = {
    programs.kitty = {
      enable = true;

      diffConfig = {
        settings.diff_cmd = "auto";
        keybindings = {
          "j" = "scroll_by 1";
        };
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/kitty/diff.conf
      assertFileContent \
        home-files/.config/kitty/diff.conf \
        ${./example-diffConfig-expected.conf}
    '';
  };
}
