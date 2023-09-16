{ lib, ... }:

let
  testInput = ''
    keybinds {
        // keybinds are divided into modes
        normal {
            // bind instructions can include one or more keys (both keys will be bound separately)
            // bind keys can include one or more actions (all actions will be performed with no sequential guarantees)
            bind "Ctrl g" { SwitchToMode "locked"; }
            bind "Ctrl p" { SwitchToMode "pane"; }
            bind "Alt n" { NewPane; }
            bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
        }
        pane {
            bind "h" "Left" { MoveFocus "Left"; }
            bind "l" "Right" { MoveFocus "Right"; }
            bind "j" "Down" { MoveFocus "Down"; }
            bind "k" "Up" { MoveFocus "Up"; }
            bind "p" { SwitchFocus; }
        }
        locked {
            bind "Ctrl g" { SwitchToMode "normal"; }
        }
    }
  '';
in {
  programs = {
    zellij = {
      enable = true;
      extraConfig = testInput;
    };
  };

  test.stubs = {
    zellij = { };
  };

  nmt.script = ''
    assertFileExists home-files/.config/zellij/config.kdl
    assertFileContains \
      home-files/.config/zellij/config.kdl \
      "${testInput}"
  '';
}
