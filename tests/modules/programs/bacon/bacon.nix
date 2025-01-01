{ pkgs, ... }:
let
  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support/org.dystroy.bacon"
  else
    ".config/bacon";
in {
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
    assertFileExists 'home-files/${configDir}/prefs.toml'
    assertFileContent 'home-files/${configDir}/prefs.toml' ${./expected.toml}
  '';
}
