{ ... }: {
  programs.bacon = {
    enable = true;
    settings = {
      jobs = {
        ta = {
          command = [ "cargo" "test" "--all-features" "--color" "always" ];
          need_stdout = true;
        };
      };
      export = {
        enabled = true;
        path = ".bacon-locations";
        line_format = "{kind} {path}:{line}:{column} {message}";
      };
    };
  };
  test.stubs.bacon = { };
  nmt.script = ''
    assertFileExists home-files/.config/bacon/prefs.toml
    assertFileContent home-files/.config/bacon/prefs.toml ${./expected.toml}
  '';
}
