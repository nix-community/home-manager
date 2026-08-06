{ lib }:

let
  gimprc = import ./gimprc.nix { inherit lib; };
  inherit (gimprc) spaces renderBoolean;

  renderMap =
    event: "${spaces 8}(map ${gimprc.renderScalar event.stroke} ${gimprc.renderScalar event.action})";

  renderController =
    controllerName: controller:
    let
      mappingBlock =
        if controller.events == [ ] then
          "(mapping)"
        else
          "(mapping\n" + lib.concatMapStringsSep "\n" renderMap controller.events + ")";
    in
    "(GimpControllerInfo ${gimprc.renderScalar controllerName}\n"
    + spaces 4
    + "(enabled ${renderBoolean controller.enabled})\n"
    + spaces 4
    + "(debug-events no)\n"
    + spaces 4
    + "(controller ${gimprc.renderScalar controllerName})\n"
    + spaces 4
    + mappingBlock
    + ")";

in
{
  toControllerConfiguration =
    controllers:
    let
      controllerBlocks = lib.mapAttrsToList renderController controllers;
      documentLines = [
        "# GIMP controllerrc"
        ""
      ]
      ++ controllerBlocks
      ++ [
        ""
        "# end of controllerrc"
      ];
    in
    lib.concatStringsSep "\n" documentLines + "\n";
}
