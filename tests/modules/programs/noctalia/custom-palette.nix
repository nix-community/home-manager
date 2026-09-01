{
  programs.noctalia = {
    enable = true;
    checkConfig = false;
    customPalettes.example_gruvbox = {
      dark = {
        mError = "#ea6962";
        mHover = "#89b482";
        mOnError = "#141617";
        mOnHover = "#141617";
        mOnPrimary = "#141617";
        mOnSecondary = "#141617";
        mOnSurface = "#ddc7a1";
        mOnSurfaceVariant = "#bdae93";
        mOnTertiary = "#141617";
        mOutline = "#5a524c";
        mPrimary = "#d3869b";
        mSecondary = "#7daea3";
        mShadow = "#141617";
        mSurface = "#141617";
        mSurfaceVariant = "#1d2021";
        mTertiary = "#89b482";
        terminal = {
          background = "#141617";
          bright = {
            black = "#5a524c";
            blue = "#7daea3";
            cyan = "#89b482";
            green = "#a9b665";
            magenta = "#d3869b";
            red = "#ea6962";
            white = "#ebdbb2";
            yellow = "#d8a657";
          };
          cursor = "#ddc7a1";
          cursorText = "#141617";
          foreground = "#ddc7a1";
          normal = {
            black = "#1d2021";
            blue = "#7daea3";
            cyan = "#89b482";
            green = "#a9b665";
            magenta = "#d3869b";
            red = "#ea6962";
            white = "#ddc7a1";
            yellow = "#d8a657";
          };
          selectionBg = "#5a524c";
          selectionFg = "#ddc7a1";
        };
      };
      light = {
        mError = "#cc241d";
        mHover = "#427b58";
        mOnError = "#fbf1c7";
        mOnHover = "#fbf1c7";
        mOnPrimary = "#fbf1c7";
        mOnSecondary = "#fbf1c7";
        mOnSurface = "#3c3836";
        mOnSurfaceVariant = "#7c6f64";
        mOnTertiary = "#fbf1c7";
        mOutline = "#bdae93";
        mPrimary = "#b16286";
        mSecondary = "#458588";
        mShadow = "#d5c4a1";
        mSurface = "#fbf1c7";
        mSurfaceVariant = "#f2e5bc";
        mTertiary = "#427b58";
        terminal = {
          background = "#fbf1c7";
          bright = {
            black = "#928374";
            blue = "#076678";
            cyan = "#427b58";
            green = "#79740e";
            magenta = "#8f3f71";
            red = "#9d0006";
            white = "#3c3836";
            yellow = "#b57614";
          };
          cursor = "#3c3836";
          cursorText = "#fbf1c7";
          foreground = "#3c3836";
          normal = {
            black = "#fbf1c7";
            blue = "#458588";
            cyan = "#689d6a";
            green = "#98971a";
            magenta = "#b16286";
            red = "#cc241d";
            white = "#7c6f64";
            yellow = "#d79921";
          };
          selectionBg = "#3c3836";
          selectionFg = "#fbf1c7";
        };
      };
    };
  };

  nmt.script = ''
    local customPalette="home-files/.config/noctalia/palettes/example_gruvbox.json"
    assertFileExists $customPalette
    assertFileContent $customPalette "${./expected-custom-palette.json}"
  '';
}
