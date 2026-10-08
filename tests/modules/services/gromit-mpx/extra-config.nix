{ lib, ... }:

{
  imports = [
    {
      services.gromit-mpx.extraConfig = lib.mkBefore ''
        "native Line" = LINE (color = "green");
      '';
    }
    {
      services.gromit-mpx.extraConfig = lib.mkAfter ''
        "default" = "inherited Line";
      '';
    }
  ];

  services.gromit-mpx = {
    enable = true;
    tools = [
      {
        device = "generated";
        color = "green";
      }
    ];
    extraConfig = ''
      "inherited Line" = "native Line";
      "generated Child" = "tool-1";
    '';
  };

  nmt.script = ''
    assertFileContent home-files/.config/gromit-mpx.cfg ${builtins.toFile "gromit-mpx.cfg" ''
      "tool-1" = PEN (size=5 color="green");
      "generated" = "tool-1";

      "native Line" = LINE (color = "green");

      "inherited Line" = "native Line";
      "generated Child" = "tool-1";

      "default" = "inherited Line";
    ''}
  '';
}
