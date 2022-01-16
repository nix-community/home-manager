{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.broot = {
      enable = true;
      config.modal = true;
    };

    nmt.script = ''
      assertFileExists home-files/.config/broot/conf.toml
      assertFileContent home-files/.config/broot/conf.toml ${
        pkgs.writeText "broot.expected" ''
          modal = true
          show_selection_mark = true

          [[verbs]]
          execution = "$EDITOR +{line} {file}"
          invocation = "edit"
          leave_broot = false
          shortcut = "e"

          [[verbs]]
          execution = "$EDITOR {directory}/{subpath}"
          invocation = "create {subpath}"
          leave_broot = false

          [[verbs]]
          execution = "git difftool -y {file}"
          invocation = "git_diff"
          leave_broot = false
          shortcut = "gd"

          [[verbs]]
          auto_exec = false
          execution = "cp -r {file} {parent}/{file-stem}-{version}{file-dot-extension}"
          invocation = "backup {version}"
          key = "ctrl-b"
          leave_broot = false

          [[verbs]]
          execution = "$SHELL"
          invocation = "terminal"
          key = "ctrl-t"
          leave_broot = false
          set_working_dir = true

          [skin]
        ''
      }
    '';
  };
}
