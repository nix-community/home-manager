{
  zsh-abbr = ./zsh-abbr.nix;
  zsh-aliases = ./aliases.nix;
  zsh-dotdir-absolute = import ./dotdir.nix "absolute";
  zsh-dotdir-default = import ./dotdir.nix "default";
  zsh-dotdir-relative = import ./dotdir.nix "relative";
  zsh-dotdir-shell-variable = import ./dotdir.nix "shell-variable";
  zsh-history-ignore-pattern = ./history-ignore-pattern.nix;
  zsh-history-path-absolute = import ./history-path.nix "absolute";
  zsh-history-path-default = import ./history-path.nix "default";
  zsh-history-path-relative = import ./history-path.nix "relative";
  zsh-history-path-xdg-variable = import ./history-path.nix "xdg-variable";
  zsh-history-path-zdotdir-variable = import ./history-path.nix "zdotdir-variable";
  zsh-history-substring-search = ./history-substring-search.nix;
  zsh-plugins = ./plugins.nix;
  zsh-prezto = ./prezto.nix;
  zsh-session-variables = ./session-variables.nix;
  zsh-syntax-highlighting = ./syntax-highlighting.nix;
  zsh-zprof = ./zprof.nix;
  zshrc-contents-priorities = ./zshrc-content-priorities.nix;
}
