{ lib, ... }:
{
  config = {
    programs.fish = {
      enable = true;

      binds = {
        "ctrl-d".command = "exit";

        "ctrl-c" = {
          mode = "insert";
          command = [
            "kill-whole-line"
            "repaint"
          ];
        };

        "ctrl-g" = {
          command = [
            "git diff"
            "repaint"
          ];
        };

        "alt-s".erase = true;
        "alt-s".operate = "preset";
        "alt-s".command = "fish_commandline_prepend sudo";
      };
    };

    # Needed to avoid error with dummy fish package.
    xdg.dataFile."fish/home-manager_generated_completions".source = lib.mkForce (
      builtins.toFile "empty" ""
    );

    nmt = {
      description = "if fish.binds is set, check function exists and contains valid binds";
      script = ''
        assertFileExists home-files/.config/fish/functions/fish_user_key_bindings.fish

        assertFileContains home-files/.config/fish/functions/fish_user_key_bindings.fish \
          "bind ctrl-d exit"
        assertFileContains home-files/.config/fish/functions/fish_user_key_bindings.fish \
          "bind --mode insert ctrl-c kill-whole-line repaint"
        assertFileContains home-files/.config/fish/functions/fish_user_key_bindings.fish \
          "bind ctrl-g 'git diff' repaint"
        assertFileContains home-files/.config/fish/functions/fish_user_key_bindings.fish \
          "bind -e --preset alt-s"
        assertFileContains home-files/.config/fish/functions/fish_user_key_bindings.fish \
          "bind --preset alt-s 'fish_commandline_prepend sudo"
      '';
    };
  };
}
