{ lib }:

{
  assertPlatform = module: pkgs: platforms: {
    assertion = lib.elem pkgs.stdenv.hostPlatform.system platforms;
    message = let
      platformsStr = lib.concatStringsSep "\n"
        (map (p: "  - ${p}") (lib.sort (a: b: a < b) platforms));
    in ''
      The module ${module} does not support your platform. It only supports

      ${platformsStr}'';
  };
}
