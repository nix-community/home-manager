{ config, lib, pkgs, ... }:

with lib;

let expectedContent = "something important";
in {
  config = {
    programs.bash.enable = true;
    programs.direnv.enable = true;
    programs.direnv.stdlib = expectedContent;

    nmt.script = ''
      assertFileExists home-files/.bashrc
      assertFileRegex \
        home-files/.config/direnv/direnvrc \
        '${expectedContent}'
    '';
  };
}
