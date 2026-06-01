_:

{
  programs.infat = {
    enable = true;
    autoActivate = false;
    settings = {
      extensions = {
        md = "TextEdit";
      };
    };
  };

  test = {
    asserts.warnings.expected = [
      ''
        Using `programs.infat.autoActivate` as a Boolean is deprecated and will be
        removed in a future release. Please use `programs.infat.autoActivate.enable` instead.
      ''
    ];

    stubs.infat = { };
  };

  nmt.script = ''
    assertFileNotRegex activate '.*@infat@/bin/infat'
  '';
}
