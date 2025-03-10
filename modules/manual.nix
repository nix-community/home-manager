{ config, lib, pkgs, ... }:

let

  cfg = config.manual;

  docs = import ../docs {
    inherit pkgs lib;
    inherit (config.home.version) release isReleaseBranch;
  };

in {
  options = {
    manual.html.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to install the HTML manual. This also installs the
        {command}`home-manager-help` tool, which opens a local
        copy of the Home Manager manual in the system web browser.
      '';
    };

    manual.manpages.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Whether to install the configuration manual page. The manual can
        be reached by {command}`man home-configuration.nix`.

        When looking at the manual page pretend that all references to
        NixOS stuff are actually references to Home Manager stuff.
        Thanks!
      '';
    };

    manual.json.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        Whether to install a JSON formatted list of all Home Manager
        options. This can be located at
        {file}`<profile directory>/share/doc/home-manager/options.json`,
        and may be used for navigating definitions, auto-completing,
        and other miscellaneous tasks.
      '';
    };
  };

  config = {
    home.packages = lib.mkMerge [
      (lib.mkIf cfg.html.enable [ docs.manual.html docs.manual.htmlOpenTool ])
      (lib.mkIf cfg.manpages.enable [ docs.manPages ])
      (lib.mkIf cfg.json.enable [ docs.options.json ])
    ];
  };

}
