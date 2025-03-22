{ config, lib, ... }:

{
  programs.git.enable = true;
  programs.mergiraf.enable = true;

  # Needed to avoid error with dummy mergiraf package.
  xdg.configFile."git/attributes".source =
    lib.mkForce (builtins.toFile "empty" "");

  nmt.script = ''
    assertFileContent "home-files/.config/git/config" ${./mergiraf-git.conf}
  '';
}
