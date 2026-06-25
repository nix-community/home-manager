{ lib, realPkgs, ... }:

{
  manual = {
    html.enable = true;
    manpages.enable = true;
    json.enable = true;
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script = ''
    assertFileExists home-path/share/doc/home-manager/index.xhtml
    assertFileExists home-path/share/doc/home-manager/options.json
    assertFileExists home-path/share/doc/home-manager/options.xhtml
    assertFileExists home-path/share/doc/home-manager/nixos-options.xhtml
    assertFileExists home-path/share/doc/home-manager/nix-darwin-options.xhtml
    assertFileExists home-path/share/doc/home-manager/release-notes.xhtml
    assertFileContains home-path/share/doc/home-manager/index.xhtml \
      '<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">'
    assertFileContains home-path/share/doc/home-manager/index.xhtml \
      '<meta charset="utf-8" />'
    assertFileContains home-path/share/doc/home-manager/index.xhtml \
      '"ch-contributing":"contributing.html"'
    assertFileContains home-path/share/doc/home-manager/index.xhtml \
      '"sec-news":"contributing/news.html"'
    assertFileContains home-path/share/doc/home-manager/index.xhtml \
      'location.replace(n);'
    assertFileContains home-path/share/doc/home-manager/options.xhtml \
      '"opt-":"options/home-manager"'
    assertFileContains home-path/share/doc/home-manager/index.html \
      '"sec-news":"contributing/news.html"'
    assertFileExists home-path/share/man/man1/home-manager.1
    assertFileExists home-path/share/man/man5/home-configuration.nix.5
  '';
}
