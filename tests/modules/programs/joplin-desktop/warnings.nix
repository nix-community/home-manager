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
    new = [
      "programs"
      "joplin-desktop"
      "settings"
    ];
  in
  "The option `${lib.showOption old}' defined in ${lib.showFiles (lib.getAttrFromPath old options).files} has been changed to `${lib.showOption new}' that has a different type. Please read `${lib.showOption new}' documentation and update your configuration accordingly."
) (lib.reverseList paths)
