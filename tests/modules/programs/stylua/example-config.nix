{ realPkgs, ... }: {
  programs.stylua = {
    enable = true;
    settings = {
      call_parentheses = "Always";
      collapse_simple_statement = "Always";
      column_width = 85;
      indent_type = "Spaces";
      indent_width = 2;
      line_endings = "Unix";
      quote_style = "AutoPreferSingle";
    };
  };
  test.unstubs = [ (_self: _super: { inherit (realPkgs) stylua; }) ];

  nmt.script = ''
    assertFileContent "home-files/.config/stylua/stylua.toml" ${./expected-config.toml}
    assertFileRegex "home-path/bin/stylua" "search-parent-directories"
  '';
}
