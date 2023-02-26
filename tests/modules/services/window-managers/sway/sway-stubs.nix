{
  # Avoid unnecessary downloads in CI jobs and/or make out paths constant, i.e.,
  # not containing hashes, version numbers etc.
  test.stubs = {
    dmenu = { };
    foot = { };
    i3status = { };
    sway = { };
    sway-unwrapped = { version = "1"; };
    swaybg = { };
    xwayland = { };
  };
}
