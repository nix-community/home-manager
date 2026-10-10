{ lib }:
{
  toVbrFile =
    brush:
    lib.concatStringsSep "\n" (
      [
        "GIMP-VBR"
        (if brush.shape == null then "1.0" else "1.5")
        brush.name
      ]
      ++ lib.optional (brush.shape != null) brush.shape
      ++ [
        (toString brush.spacing)
        (toString brush.radius)
      ]
      ++ lib.optional (brush.shape != null) (toString (if brush.spikes == null then 2 else brush.spikes))
      ++ [
        (toString brush.hardness)
        (toString brush.aspectRatio)
        (toString brush.angle)
        ""
      ]
    );
}
