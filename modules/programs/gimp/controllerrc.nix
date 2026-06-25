{ lib }:

# Structure: (gimp-controllers (ControllerType (enabled yes/no) (events event...)))
# Each event is a two-element record: ((stroke "name") (action "path")).
# An empty event list serializes as (), GIMP's nil sentinel.

let
  spaces = n: lib.fixedWidthString n " ";

  renderBoolean = booleanValue: if booleanValue then "yes" else "no";

  renderEvent =
    event: "((stroke \"${event.stroke}\")\n" + spaces 13 + "(action \"${event.action}\"))";

  renderController =
    controllerName: controller:
    let
      eventsContent =
        if controller.events == [ ] then
          spaces 12 + "()"
        else
          lib.concatMapStringsSep "\n" (event: spaces 12 + renderEvent event) controller.events;
    in
    spaces 4
    + "(${controllerName}\n"
    + spaces 8
    + "(enabled ${renderBoolean controller.enabled})\n"
    + spaces 8
    + "(events\n${eventsContent})";
in
{
  toControllerConfiguration =
    controllers:
    let
      controllerBlocks = lib.mapAttrsToList renderController controllers;
      documentLines = [
        "(gimp-controllers"
      ]
      ++ controllerBlocks
      ++ [
        ")"
        ""
      ];
    in
    lib.concatStringsSep "\n" documentLines;
}
