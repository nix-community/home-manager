{
  zsh-dotdir-absolute = import ./dotdir.nix "absolute";
  zsh-dotdir-default = import ./dotdir.nix "default";
  zsh-dotdir-relative = import ./dotdir.nix "relative";
  zsh-session-variables = ./session-variables.nix;
  zsh-history-path-new-default = ./history-path-new-default.nix;
  zsh-history-path-new-custom = ./history-path-new-custom.nix;
  zsh-history-path-old-default = ./history-path-old-default.nix;
  zsh-history-path-old-custom = ./history-path-old-custom.nix;
  zsh-history-ignore-pattern = ./history-ignore-pattern.nix;
  zsh-history-substring-search = ./history-substring-search.nix;
  zsh-prezto = ./prezto.nix;
  zsh-syntax-highlighting = ./syntax-highlighting.nix;
  zsh-abbr = ./zsh-abbr.nix;
}
