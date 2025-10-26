{ pkgs, ... }:

{
  programs.glab = {
    enable = true;
    aliases.co = "mr checkout";
  };

  nmt.script = ''
    aliasesFile=home-files/.config/glab-cli/aliases.yml
    assertFileExists $aliasesFile
    assertFileContent $aliasesFile ${pkgs.writeText "glab-aliases.expected" ''
      co: mr checkout
    ''}
  '';
}
