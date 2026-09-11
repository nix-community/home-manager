{
  pkgs,
  ...
}:

{
  imports = [ ./stubs.nix ];

  programs.mpv = {
    enable = true;
    package = null;

    scripts = [ pkgs.mpvScript ];
  };

  test.asserts.assertions.expected = [
    ''The programs.mpv "package" option is mutually exclusive with "scripts", "extraMakeWrapperArgs" options.''
    ''The programs.mpv "package" option set to null is mutually exclusive with "scripts", "extraMakeWrapperArgs" options.''
  ];
}
