{ lib }:
# Structure: (gimp-controllers (ControllerType (enabled yes/no) (events event…)))
# Each event is a two-element record: ((stroke "name") (action "path")).
# An empty event list serialises as (), GIMP's nil sentinel.
let
  renderBool = b: if b then "yes" else "no";

  renderEvent = e: "((stroke \"${e.stroke}\")\n             (action \"${e.action}\"))";

  renderController =
    name: ctrl:
    let
      eventsContent =
        if ctrl.events == [ ] then
          "            ()"
        else
          lib.concatMapStringsSep "\n" (e: "            ${renderEvent e}") ctrl.events;
    in
    "    (${name}\n        (enabled ${renderBool ctrl.enabled})\n        (events\n${eventsContent}))";
in
{
  toControllerrc =
    controllers:
    "(gimp-controllers\n"
    + lib.concatMapStringsSep "\n" (name: renderController name controllers.${name}) (
      lib.attrNames controllers
    )
    + ")\n";
}
