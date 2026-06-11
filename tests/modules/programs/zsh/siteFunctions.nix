let
  mkcd-body = ''
    mkdir --parents "$1" && cd "$1"
  '';
  hidden-body = ''
    echo "doing some hidden magic"
  '';
  bad-idea-body = ''
    echo "zsh can have function names with spaces! you shouldn't use it though..."
  '';
in
{
  programs.zsh = {
    enable = true;
    # normal function name
    siteFunctions.mkcd = mkcd-body;
    # function name starting with a dash: it should not be treated as an option
    siteFunctions."-hidden-function" = hidden-body;
    # function name that contains a space: it should not be word-split (avoid loading 'bad' and 'idea' separately)
    siteFunctions."bad idea" = bad-idea-body;
  };

  nmt.script = ''
    assertFileExists home-path/share/zsh/site-functions/mkcd
    assertFileExists home-path/share/zsh/site-functions/-hidden-function
    assertFileExists "home-path/share/zsh/site-functions/bad idea"
    assertFileContent home-path/share/zsh/site-functions/mkcd ${builtins.toFile "mkcd" mkcd-body}
    assertFileContent home-path/share/zsh/site-functions/-hidden-function ${builtins.toFile "-hidden-function" hidden-body}
    assertFileContent "home-path/share/zsh/site-functions/bad idea" ${builtins.toFile "bad-idea" bad-idea-body}
    assertFileContains home-files/.zshrc "autoload -Uz -- -hidden-function 'bad idea' mkcd"
  '';
}
