{ ... }:

{
  programs.tig = {
    enable = true;
    sources = [
      "~/.tigrc.d/colors.tigrc"
      "~/.tigrc.d/bindings.tigrc"
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/tig/config
    assertFileContent home-files/.config/tig/config \
      ${./sources-expected.conf}
  '';
}
