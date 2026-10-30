{
  programs.tuicr = {
    enable = true;
    package = null;
    settings = {
      theme = "catppuccin-mocha";
      diff_view = "unified";
      scroll_offset = 5;
      leader = ";";
      comment_vim = false;
      q_quits = true;

      comment_types = [
        {
          id = "note";
          label = "question";
          definition = "ask for clarification";
          color = "yellow";
        }
        {
          id = "nit";
          label = "nitpick";
          definition = "small optional tweaks";
          color = "#d19a66";
        }
      ];

      forge.comment_type_prefix = false;
      export = {
        intro = "Please address these comments.";
        scope_line = false;
      };
    };
  };

  test.stubs.tuicr = {
    name = "tuicr";
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/tuicr
    '';
  };

  nmt.script = ''
    assertFileExists "home-files/.config/tuicr/config.toml"
    assertFileContent "home-files/.config/tuicr/config.toml" ${./expected.toml}
    assertPathNotExists "home-path/bin/tuicr"
  '';
}
