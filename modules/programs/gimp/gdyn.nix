{ lib }:
let
  gimprc = import ./gimprc.nix { inherit lib; };

  toDynamicsSettings = dynamics: dynamics.settings or { };
in
{
  toDynamicsFile =
    dynamics:
    let
      settingsBlock = toDynamicsSettings dynamics;
    in
    "# GIMP dynamics file\n\n"
    + "(name ${gimprc.renderScalar dynamics.name})\n"
    + lib.optionalString (settingsBlock != { }) ("\n" + gimprc.toGimpConfiguration settingsBlock)
    + "\n# end of GIMP dynamics file\n";
}
