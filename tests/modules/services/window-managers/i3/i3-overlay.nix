self: super:
# Avoid unnecessary downloads in CI jobs and/or make out paths
# constant, i.e., not containing hashes, version numbers etc.
{
  dmenu = super.dmenu // { outPath = "@dmenu@"; };

  i3 = super.writeScriptBin "i3" "" // { outPath = "@i3@"; };

  i3-gaps = super.writeScriptBin "i3" "" // { outPath = "@i3-gaps@"; };

  i3status = super.i3status // { outPath = "@i3status@"; };
}
