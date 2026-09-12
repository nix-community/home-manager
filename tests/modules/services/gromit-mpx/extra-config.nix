{
  config,
  lib,
  options,
  ...
}:

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
    opacity = lib.mkDefault 0.25;
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

  assertions = [
    {
      assertion = config.services.gromit-mpx.opacity == 0.25;
      message = "Legacy opacity must read back the canonical value.";
    }
  ];

  test.asserts.warnings.expected = [
    "The option `services.gromit-mpx.opacity' defined in ${lib.showFiles options.services.gromit-mpx.opacity.files} has been renamed to `services.gromit-mpx.iniSettings.Drawing.Opacity'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/gromit-mpx.ini ${builtins.toFile "expected.ini" ''
      [Drawing]
      Opacity=0.250000

      [General]
      ShowIntroOnStartup=false
    ''}
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
