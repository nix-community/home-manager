{ config, lib, ... }:

{
  home.file."result.txt".text = lib.hm.generators.toKDL { } {
    default_mode = "locked";
    keybinds = {

      # will be sorted
      locked = {
        "bind 'Alt h'" = { MoveFocusOrTab = "Left"; };
        "bind 'Alt l'" = { MoveFocusOrTab = "Right"; };
        "bind \"Alt j\"" = { MoveFocus = "Down"; };
        "bind \"Alt k\"" = { MoveFocus = "Up"; };
      };

      # will not be sorted
      normal = [
        { "bind 'Alt h'" = { MoveFocusOrTab = "Left"; }; }
        { "bind \"Alt j\"" = { MoveFocus = "Down"; }; }
        { "bind \"Alt k\"" = { MoveFocus = "Up"; }; }
        { "bind 'Alt l'" = { MoveFocusOrTab = "Right"; }; }
      ];

      pane = {
        "bind \"t\"" = {
          CloseTab = [ ];
          CloseFocus = [ ];
        };
      };
    };
    layouts = [
      {
        "pane size=1 borderless=true" = {
          plugin = ''location="zellij:tab-bar"'';
        };
      }
      "pane"
      {
        "pane size=2 borderless=true" =
          [ ''plugin location="zellij:status-bar"'' ];
      }
    ];
  };

  nmt.script = ''
    assertFileContent \
      home-files/result.txt \
      ${./result-tokdl-zellij.txt}
  '';
}
