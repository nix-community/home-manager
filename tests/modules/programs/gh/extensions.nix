{ pkgs, ... }:

{
  programs.gh = {
    enable = true;
    extensions = [ pkgs.gh-eco ];
  };

  test.stubs = {
    gh-eco = {
      name = "gh-eco";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/gh-eco
        chmod +x $out/bin/gh-eco
      '';
      outPath = null;
    };
  };

  nmt.script = ''
    gh_eco=home-files/.local/share/gh/extensions/gh-eco/gh-eco
    assertFileExists "$gh_eco"
    assertFileIsExecutable "$gh_eco"
  '';
}
