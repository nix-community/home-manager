{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    programs.man = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable manual pages and the <command>man</command>
          command. This also includes "man" outputs of all
          <literal>home.packages</literal>.
        '';
      };

      generateCaches = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to generate the manual page index caches using
          <citerefentry>
            <refentrytitle>mandb</refentrytitle>
            <manvolnum>8</manvolnum>
          </citerefentry>. This allows searching for a page or
          keyword using utilities like <citerefentry>
            <refentrytitle>apropos</refentrytitle>
            <manvolnum>1</manvolnum>
          </citerefentry>.
          </para><para>
          This feature is disabled by default because it slows down
          building. If you don't mind waiting a few more seconds when
          Home Manager builds a new generation, you may safely enable
          this option.
        '';
      };
    };
  };

  config = mkIf config.programs.man.enable {
    home.packages = [ pkgs.man ];
    home.extraOutputsToInstall = [ "man" ];

    # This is mostly copy/pasted/adapted from NixOS' documentation.nix.
    home.file = mkIf config.programs.man.generateCaches {
      ".manpath".text = let
        # Generate a directory containing installed packages' manpages.
        manualPages = pkgs.buildEnv {
          name = "man-paths";
          paths = config.home.packages;
          pathsToLink = [ "/share/man" ];
          extraOutputsToInstall = [ "man" ];
          ignoreCollisions = true;
        };

        # Generate a database of all manpages in ${manualPages}.
        manualCache = pkgs.runCommandLocal "man-cache" { } ''
          # Generate a temporary man.conf so mandb knows where to
          # write cache files.
          echo "MANDB_MAP ${manualPages}/share/man $out" > man.conf

          # Run mandb to generate cache files:
          ${pkgs.man-db}/bin/mandb -C man.conf --no-straycats --create \
            ${manualPages}/share/man
        '';
      in ''
        MANDB_MAP ${config.home.profileDirectory}/share/man ${manualCache}
      '';
    };
  };
}
