_: {
  programs.pistol = {
    enable = true;
    associations = [
      {
        mime = "application/json";
        command = "bat %pistol-filename%";
      }
    ];
  };

  xdg.enable = true;

  nmt.script =
    let
      expected = builtins.toFile "config-expected" "application/json bat %pistol-filename%";
      path = "home-files/.config/pistol/pistol.conf";
    in
    ''
      assertFileExists '${path}'
      assertFileContent '${path}' '${expected}'
    '';
}
