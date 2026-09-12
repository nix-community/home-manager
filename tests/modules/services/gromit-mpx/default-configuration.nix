{
  services.gromit-mpx = {
    enable = true;
  };

  nmt.script = (import ./nmt-script.nix ./default-configuration.cfg) + ''
    assertFileContent home-files/.config/gromit-mpx.ini ${builtins.toFile "expected.ini" ''
      [Drawing]
      Opacity=0.750000

      [General]
      ShowIntroOnStartup=false
    ''}
  '';
}
