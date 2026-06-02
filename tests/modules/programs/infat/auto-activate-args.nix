{
  programs.infat = {
    enable = true;
    autoActivate.extraArgs = [ "--quiet" ];
    settings = {
      extensions = {
        md = "TextEdit";
      };
    };
  };

  test.stubs.infat = { };

  nmt.script = ''
    assertFileContains activate ' --config'
    assertFileContains activate ' --quiet'
    assertFileNotRegex activate '.*--robust'
  '';
}
