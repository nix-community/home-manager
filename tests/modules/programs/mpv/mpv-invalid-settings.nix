{
  pkgs,
  ...
}:

{
  imports = [ ./stubs.nix ];

  programs.mpv = {
    enable = true;
    package = pkgs.emptyDirectory;
    scripts = [ pkgs.mpvScript ];
    includes = [ "safe\ninjected.conf" ];
    settings."safe\ninjected" = true;
  };

  test.asserts.assertions.expected = [
    ''The programs.mpv "package" option is mutually exclusive with "scripts", "extraMakeWrapperArgs" options.''
    "The programs.mpv configuration names must not contain literal line breaks."
    "The programs.mpv raw-line configuration values must not contain literal line breaks."
  ];
}
