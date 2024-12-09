{ config, lib, pkgs, ... }:

with lib;

let expectedContent = "something important";
in {
  config = {
    programs.bash.enable = true;
    programs.direnv.enable = true;
    programs.direnv.stdlib = expectedContent;

    nmt.script = ''
      assertPathNotExists home-files/.config/direnv/lib/hm-nix-direnv.sh
      assertFileExists home-files/.bashrc
      assertFileRegex \
        home-files/.config/direnv/direnvrc \
        '${expectedContent}'
    '';
  };
}
