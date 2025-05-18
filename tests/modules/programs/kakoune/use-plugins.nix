{ pkgs, ... }:

{
  imports = [ ./stubs.nix ];

  programs.kakoune = {
    enable = true;
    plugins = [ pkgs.kakoune-test-plugin ];
  };

  nmt.script = ''
    assertDirectoryNotEmpty home-path/share/kak/autoload/plugins
  '';
}
