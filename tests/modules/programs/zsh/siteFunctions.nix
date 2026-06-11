let
  mkcd-body = ''
    mkdir --parents "$1" && cd "$1"
  '';
  hidden-body = ''
    echo "doing some hidden magic"
  '';
in
{
  programs.zsh = {
    enable = true;
    siteFunctions.mkcd = mkcd-body;
    siteFunctions."-hidden-function" = hidden-body;
  };

  nmt.script = ''
    assertFileExists home-path/share/zsh/site-functions/mkcd
    assertFileExists home-path/share/zsh/site-functions/-hidden-function
    assertFileContent home-path/share/zsh/site-functions/mkcd ${builtins.toFile "mkcd" mkcd-body}
    assertFileContent home-path/share/zsh/site-functions/-hidden-function ${builtins.toFile "-hidden-function" hidden-body}
    assertFileContains home-files/.zshrc "autoload -Uz -- -hidden-function mkcd"
  '';
}
