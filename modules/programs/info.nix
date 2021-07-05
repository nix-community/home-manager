# info.nix -- install texinfo and create `dir` file

# This is a helper for the GNU info documentation system. By default,
# the `info` command (and the Info subsystem within Emacs) gives easy
# access to the info files stored system-wide, but not info files in
# your ~/.nix-profile.

# Specifically, although info can then find files when you explicitly
# ask for them, it doesn't show them to you in the table of contents
# on startup. To do that requires a `dir` file. NixOS keeps the
# system-wide `dir` file up to date, but ignores files installed in
# user profiles.

# This module contains extra profile commands that generate the `dir`
# for your home profile. Then when you start info (and both `dir`
# files are in your $INFOPATH), it will *merge* the contents of the
# two files, showing you a unified table of contents for all packages.
# This is really nice.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.info;

  # Installs this package -- the interactive just means that it
  # includes the curses `info` program. We also use `install-info`
  # from this package in the activation script.
  infoPkg = pkgs.texinfoInteractive;

in {
  imports = [
    (mkRemovedOptionModule [ "programs" "info" "homeInfoDirLocation" ] ''
      The `dir` file is now generated as part of the Home Manager profile and
      will no longer be placed in your home directory.
    '')
  ];

  options.programs.info.enable = mkEnableOption "GNU Info";

  config = mkIf cfg.enable {
    home.packages = [
      infoPkg

      # Make sure the target directory is a real directory.
      (pkgs.runCommandLocal "dummy-info-dir1" { } "mkdir -p $out/share/info")
      (pkgs.runCommandLocal "dummy-info-dir2" { } "mkdir -p $out/share/info")
    ];

    home.extraOutputsToInstall = [ "info" ];

    home.extraProfileCommands = let infoPath = "$out/share/info";
    in ''
      if [[ -w "${infoPath}" && ! -e "${infoPath}/dir" ]]; then
        PATH="${lib.makeBinPath [ pkgs.gzip infoPkg ]}''${PATH:+:}$PATH" \
        find -L "${infoPath}" \( -name '*.info' -o -name '*.info.gz' \) \
          -exec install-info '{}' "${infoPath}/dir" ';'
      fi
    '';
  };
}
