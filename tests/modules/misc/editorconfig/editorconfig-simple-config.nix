{ ... }:

{
  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        trim_trailing_whitespace = true;
        insert_final_newline = true;
        max_line_width = 78;
        indent_style = "space";
      };
      "*.md" = {
        indent_size = "unset";
        trim_trailing_whitespace = false;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.editorconfig
    assertFileContent home-files/.editorconfig ${
      ./editorconfig-simple-config-expected
    }
  '';
}
