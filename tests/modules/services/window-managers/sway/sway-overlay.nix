self: super:
# Avoid unnecessary downloads in CI jobs.
let dummy-package = super.runCommandLocal "dummy-package" { } "mkdir $out";
in {
  dmenu = dummy-package // { outPath = "@dmenu@"; };
  rxvt-unicode-unwrapped = dummy-package // {
    outPath = "@rxvt-unicode-unwrapped@";
  };
  i3status = dummy-package // { outPath = "@i3status@"; };
  sway = dummy-package // { outPath = "@sway@"; };
  sway-unwrapped = dummy-package // {
    outPath = "@sway-unwrapped@";
    version = "1";
  };
  swaybg = dummy-package // { outPath = "@swaybg@"; };
  xwayland = dummy-package // { outPath = "@xwayland@"; };
}
