{ pkgs, ... }:

let

  expected = builtins.toFile "settings-expected" ''
    application/json bat --paging=never --color=always --style=auto --wrap=character --terminal-width=%pistol-extra0% --line-range=1:%pistol-extra1% %pistol-filename%
    text/* bat --paging=never --color=always --style=auto --wrap=character --terminal-width=%pistol-extra0% --line-range=1:%pistol-extra1% %pistol-filename%'';

in {
  programs.pistol = {
    enable = true;
    config = {
      "text/*" =
        "bat --paging=never --color=always --style=auto --wrap=character --terminal-width=%pistol-extra0% --line-range=1:%pistol-extra1% %pistol-filename%";
      "application/json" =
        "bat --paging=never --color=always --style=auto --wrap=character --terminal-width=%pistol-extra0% --line-range=1:%pistol-extra1% %pistol-filename%";
    };
  };

  test.stubs.pistol = { };

  nmt.script = let
    path = if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/Application Support/pistol/pistol.conf"
    else
      "home-files/.config/pistol/pistol.conf";
  in ''
    assertFileExists '${path}'
    assertFileContent '${path}' '${expected}'
  '';
}
