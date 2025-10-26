{ config, ... }:
{
  home.stateVersion = "22.11";

  programs.wleave = {
    package = config.lib.test.mkStubPackage { outPath = "@wleave@"; };
    enable = true;
    style = ''
      * {
          border: none;
          border-radius: 0;
          font-family: Source Code Pro;
          font-weight: bold;
          color: #abb2bf;
          font-size: 18px;
          min-height: 0px;
      }
      window {
          background: #16191C;
          color: #aab2bf;
      }
      #window {
          padding: 0 0px;
      }
    '';
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/wleave/layout.json
    assertFileContent \
      home-files/.config/wleave/style.css \
      ${./styling-expected.css}
  '';
}
