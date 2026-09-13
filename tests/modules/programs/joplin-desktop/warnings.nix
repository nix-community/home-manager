{ lib, options }:
paths:
map (
  path:
  let
    old = [
      "programs"
      "joplin-desktop"
    ]
    ++ path;
    key = if builtins.head path == "general" then "editor" else "sync.${builtins.elemAt path 1}";
    new = [
      "programs"
      "joplin-desktop"
      "settings"
    ]
    ++ lib.optional (builtins.head path == "general") key;
  in
  if builtins.head path == "general" then
    "The option `${lib.showOption old}' defined in ${lib.showFiles (lib.getAttrFromPath old options).files} has been renamed to `${lib.showOption new}'."
  else
    "The option `${lib.showOption old}' defined in ${lib.showFiles (lib.getAttrFromPath old options).files} has been changed to `${lib.showOption new}' that has a different type. Please read `${lib.showOption new}' documentation and update your configuration accordingly."
) (lib.reverseList paths)
