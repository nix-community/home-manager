# info.nix -- install texinfo, set INFOPATH, create `dir` file

# This is a helper for the GNU info documentation system. By default,
# the `info` command (and the Info subsystem within Emacs) gives easy
# access to the info files stored system-wide, but not info files in
# your ~/.nix-profile.

# We set $INFOPATH to include `/run/current-system/sw/share/info` and
# `~/.nix-profile/share/info` but it's not enough. Although info can
# then find files when you explicitly ask for them, it doesn't show
# them to you in the table of contents on startup. To do that requires
# a `dir` file. NixOS keeps the system-wide `dir` file up to date, but
# ignores home-installed packages.

# So this module contains an activation script that generates the
# `dir` for your home profile. Then when you start info (and both
# `dir` files are in your $INFOPATH), it will *merge* the contents of
# the two files, showing you a unified table of contents for all
# packages. This is really nice.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.info;

  # Indexes info files found in this location
  homeInfoPath = "${config.home.profileDirectory}/share/info";

  # Installs this package -- the interactive just means that it
  # includes the curses `info` program. We also use `install-info`
  # from this package in the activation script.
  infoPkg = pkgs.texinfoInteractive;

in

{
  options = {
    programs.info = {
      enable = mkEnableOption "GNU Info";

      homeInfoDirLocation = mkOption {
        default = "\${XDG_CACHE_HOME:-$HOME/.cache}/info";
        description = ''
          Directory in which to store the info <filename>dir</filename>
          file within your home.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.sessionVariables.INFOPATH =
      "${cfg.homeInfoDirLocation}\${INFOPATH:+:}\${INFOPATH}";

    home.activation.createHomeInfoDir = hm.dag.entryAfter ["installPackages"] ''
      oPATH=$PATH
      export PATH="${lib.makeBinPath [ pkgs.gzip ]}''${PATH:+:}$PATH"
      $DRY_RUN_CMD mkdir -p "${cfg.homeInfoDirLocation}"
      $DRY_RUN_CMD rm -f "${cfg.homeInfoDirLocation}/dir"
      if [[ -d "${homeInfoPath}" ]]; then
        find -L "${homeInfoPath}" \( -name '*.info' -o -name '*.info.gz' \) \
          -exec $DRY_RUN_CMD ${infoPkg}/bin/install-info '{}' \
          "${cfg.homeInfoDirLocation}/dir" \;
      fi
      export PATH="$oPATH"
      unset oPATH
    '';

    home.packages = [ infoPkg ];

    home.extraOutputsToInstall = [ "info" ];
  };
}
