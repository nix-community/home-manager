{ config, lib, options, ... }: {
  programs.k9s = {
    enable = true;
    skin = {
      k9s = {
        body = {
          fgColor = "dodgerblue";
          bgColor = "#ffffff";
          logoColor = "#0000ff";
        };
        info = {
          fgColor = "lightskyblue";
          sectionColor = "steelblue";
        };
      };
    };
  };

  test.stubs.k9s = { };

  test.asserts.warnings.enable = true;
  test.asserts.warnings.expected = [
    "The option `programs.k9s.skin' defined in ${
      lib.showFiles options.programs.k9s.skin.files
    } has been renamed to `programs.k9s.skins.skin'."
  ];
  nmt.script = ''
    assertFileExists home-files/.config/k9s/skins/skin.yaml
    assertFileContent \
      home-files/.config/k9s/skins/skin.yaml \
      ${./example-skin-expected.yaml}
  '';
}
