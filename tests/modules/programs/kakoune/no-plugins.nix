{
  imports = [ ./stubs.nix ];

  programs.kakoune = { enable = true; };

  nmt.script = ''
    assertPathNotExists home-path/share/kak/autoload/plugins
  '';
}
