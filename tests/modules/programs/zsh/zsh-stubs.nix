{ ... }:

{
  test.stubs = {
    hello = { };
    nix-zsh-completions = { };
    zsh = { };
    zsh-abbr = { };
    zsh-history-substring-search = { };
    zsh-prezto = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/share/zsh-prezto/runcoms
        echo '# zprofile' > $out/share/zsh-prezto/runcoms/zprofile
        echo '# zlogin' > $out/share/zsh-prezto/runcoms/zlogin
        echo '# zlogout' > $out/share/zsh-prezto/runcoms/zlogout
        echo '# zshenv' > $out/share/zsh-prezto/runcoms/zshenv
      '';
    };
    zsh-syntax-highlighting = { };
  };
}
