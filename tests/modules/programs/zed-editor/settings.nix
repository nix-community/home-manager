# Test custom keymap functionality
{ pkgs, ...}:

let
  binds = {
    theme = "XY-Zed";
    features = {
      copilot = false;
    };
    vim_mode = false;
    ui_font_size = 16;
    buffer_font_size = 16;
  };

  expectedContent = pkgs.writeText "expected.json" ''
    {
      "theme": "XY-Zed",
      "features": {
        "copilot": false
      },
      "vim_mode": false,
      "ui_font_size": 16,
      "buffer_font_size": 16
    }
  '';

  settingsPath = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/zed/settings.json"
  else
    ".config/zed/settings.json";
in
{
  programs.zed-editor = {
    enable = true;
    userKeymaps = binds;
    package = pkgs.writeScriptBin "zed" "" // { pname = "zed-editor"; };
  };

  nmt.script = ''
    assertFileExists "home-files/${settingsPath}"
    assertFileContent "home-files/${settingsPath}" "${expectedContent}"
  '';
}