{ config, lib, ... }:

with lib;

{
  config = {
    programs.fish = {
      enable = true;

      functions = { };
    };

    nmt = {
      description =
        "if fish.functions is blank, the functions folder should not exist.";
      script = ''
        assertPathNotExists $home_files/.config/fish/functions
      '';

    };
  };
}
