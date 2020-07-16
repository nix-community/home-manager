{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.fzf.enable = true;

    programs.vim = {
      enable = true;

      plugins = [ pkgs.vimPlugins.ack-vim ];
      optionalPlugins = [ pkgs.vimPlugins.fzf-vim ];
    };

    nmt.script = ''
      # need to verify absolute locations
      function assertAbsoluteDirExists() {
        if [[ ! -d "$1" ]]; then
          fail "Expected $1 to exist but it was not found."
        fi
      }

      # load the rc file from the nix shim and fetch the runtimepath value
      rc_file=$(tail -n1 "$TESTED/home-path/bin/vim" | cut -d " " -f 4)
      pack_path=$(grep runtimepath "$rc_file" | cut -d = -f 2)/pack/home-manager

      # start packages
      assertAbsoluteDirExists "$pack_path/start/ack-vim"
      assertAbsoluteDirExists "$pack_path/start/fzf"
      assertAbsoluteDirExists "$pack_path/start/vim-sensible"

      # optional packages
      assertAbsoluteDirExists "$pack_path/opt/fzf-vim"
    '';
  };
}
