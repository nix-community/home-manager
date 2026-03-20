let
  body = ''
    mkdir --parents "$1" && cd "$1"
  '';
in
{
  programs.zsh = {
    enable = true;
    siteFunctions.mkcd = body;
  };

  nmt.script = ''
    assertFileExists home-path/share/zsh/site-functions/mkcd
    assertFileContent home-path/share/zsh/site-functions/mkcd ${builtins.toFile "mkcd" body}
    assertFileContains home-files/.zshrc "autoload -Uz mkcd"
  '';
}
