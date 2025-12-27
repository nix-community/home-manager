{ lib }:

{
  assertPlatform =
    module: config: pkgs: platforms:
    let
      modulePath = lib.splitString "." module;
      isEmpty = x: x == false || x == null || x == { } || x == [ ] || x == "";
    in
    {
      assertion =
        (isEmpty (lib.attrByPath modulePath null config))
        || (lib.elem pkgs.stdenv.hostPlatform.system platforms);
      message =
        let
          platformsStr = lib.concatStringsSep "\n" (map (p: "  - ${p}") (lib.sort (a: b: a < b) platforms));
        in
        ''
          The module ${module} does not support your platform. It only supports

          ${platformsStr}'';
    };
}
