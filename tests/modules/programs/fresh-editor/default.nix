{
  fresh-editor = ./fresh-editor-settings.nix;
  fresh-editor-mutable = import ./mutable-settings.nix "mutable";
  fresh-editor-mutable-custom-xdg = import ./mutable-settings.nix "custom-xdg";
  fresh-editor-mutable-disabled = import ./mutable-settings.nix "disabled";
  fresh-editor-mutable-empty = import ./mutable-settings.nix "empty";
  fresh-editor-immutable-empty = import ./mutable-settings.nix "immutable-empty";
}
