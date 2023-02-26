{ pkgs, ... }:

{
  programs.pistol = {
    enable = true;
    associations = [
      {
        mime = "application/json";
        command = "bat %pistol-filename%";
      }
      {
        mime = "application/*";
        command = "hexyl %pistol-filename%";
      }
      {
        fpath = ".*.md$";
        command =
          "sh: bat --paging=never --color=always %pistol-filename% | head -8";
      }
    ];
  };

  test.stubs.pistol = { };

  nmt.script = let
    expected = builtins.toFile "config-expected" ''
      application/json bat %pistol-filename%
      application/* hexyl %pistol-filename%
      fpath .*.md$ sh: bat --paging=never --color=always %pistol-filename% | head -8'';
    path = if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/Application Support/pistol/pistol.conf"
    else
      "home-files/.config/pistol/pistol.conf";
  in ''
    assertFileExists '${path}'
    assertFileContent '${path}' '${expected}'
  '';
}
