{ lib }:
{
  toMenurc =
    shortcuts:
    lib.concatMapStringsSep "\n" (
      path:
      let
        s = shortcuts.${path};
        accel = lib.concatMapStrings (m: "<${m}>") s.modifiers + s.key;
      in
      "(gtk_accel_path \"${path}\" \"${accel}\")"
    ) (lib.attrNames shortcuts)
    + "\n";
}
