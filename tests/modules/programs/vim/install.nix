{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.vim = {
      enable = true;

      settings = { background = "dark"; };
    };

    nmt.script = ''
      # files aren't created in the $TESTED dir
      function assertAbsoluteFileExists() {
        if [[ ! -f "$1" ]]; then
          fail "Expected $1 to exist but it was not found."
        fi
      }

      function assertAbsoluteFileContains() {
        if ! grep -qF "$2" "$1"; then
          fail "Expected $1 to contain $2 but it did not."
        fi
      }

      assertFileExists home-path/bin/vim
      assertFileIsExecutable home-path/bin/vim

      # load the rc file from the nix shim
      rc_file=$(tail -n1 "$TESTED/home-path/bin/vim" | cut -d " " -f 4)
      assertAbsoluteFileExists "$rc_file"
      assertAbsoluteFileContains "$rc_file" "set background=dark"
    '';
  };
}

