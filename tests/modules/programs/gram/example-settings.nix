{ config, pkgs, ... }:

let
  inherit (pkgs) formats;

  jsonFormat = formats.json { };

  cfg = config.programs.gram;

  expectedSettings = jsonFormat.generate "settings.jsonc" cfg.settings;
  expectedDebugger = jsonFormat.generate "debug.jsonc" cfg.debugger;
  expectedKeymaps = jsonFormat.generate "keymap.jsonc" cfg.keymaps;
  expectedTasks = jsonFormat.generate "tasks.jsonc" cfg.tasks;
in

{
  programs.gram = {
    enable = true;

    settings = {
      buffer_font_family = "JetBrains Mono";
      buffer_font_weight = 400;
      buffer_font_size = 14;
    };

    debugger = [
      {
        label = "Example Start debugger config";
        adapter = "Example adapter name";
        request = "launch";
        program = "path_to_program";
        cwd = "$GRAM_WORKTREE_ROOT";
      }
    ];

    keymaps = [
      {
        bindings = {
          ctrl-right = "editor::SelectLargerSyntaxNode";
          ctrl-left = "editor::SelectSmallerSyntaxNode";
        };
      }
      {
        context = "ProjectPanel && not_editing";
        bindings.o = "project_panel::Open";
      }
    ];

    tasks = [
      {
        label = "Example task";
        command = ''for i in {1..5}; do echo "Hello $i/5"; sleep 1; done'';
        env.foo = "bar";
        use_new_terminal = false;
        allow_concurrent_runs = false;
        reveal = "always";
        hide = "never";
        shell = "system";
        show_summary = true;
        show_command = true;
        save = "none";
      }
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/gram/settings.jsonc
    assertFileContent home-files/.config/gram/settings.jsonc ${expectedSettings}

    assertFileExists home-files/.config/gram/debug.jsonc
    assertFileContent home-files/.config/gram/debug.jsonc ${expectedDebugger}

    assertFileExists home-files/.config/gram/keymap.jsonc
    assertFileContent home-files/.config/gram/keymap.jsonc ${expectedKeymaps}

    assertFileExists home-files/.config/gram/tasks.jsonc
    assertFileContent home-files/.config/gram/tasks.jsonc ${expectedTasks}
  '';
}
