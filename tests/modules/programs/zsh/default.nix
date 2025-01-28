{
  zsh-dotdir-absolute = import ./dotdir.nix "absolute";
  zsh-dotdir-default = import ./dotdir.nix "default";
  zsh-dotdir-relative = import ./dotdir.nix "relative";
  zsh-history-ignore-pattern = ./history-ignore-pattern.nix;
  zsh-history-path-absolute = import ./history-path.nix "absolute";
  zsh-history-path-default = import ./history-path.nix "default";
  zsh-history-path-relative = import ./history-path.nix "relative";
  zsh-history-substring-search = ./history-substring-search.nix;
  zsh-session-variables = ./session-variables.nix;
  zsh-prezto = ./prezto.nix;
  zsh-syntax-highlighting = ./syntax-highlighting.nix;
  zsh-abbr = ./zsh-abbr.nix;
}
