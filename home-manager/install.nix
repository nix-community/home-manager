{ home-manager, pkgs }:

pkgs.runCommand
  "home-manager-install"
  {
    propagatedBuildInputs = [ home-manager ];
    shellHook = ''
      echo
      echo "Creating initial Home Manager generation..."
      echo

      if home-manager switch; then
        cat <<EOF

      All done! The home-manager tool should now be installed and you
      can edit

          ''${XDG_CONFIG_HOME:-~/.config}/nixpkgs/home.nix

      to configure Home Manager. Run 'man home-configuration.nix' to
      see all available options.
      EOF
        exit 0
      else
        cat <<EOF

      Uh oh, the installation failed! Please create an issue at

          https://github.com/rycee/home-manager/issues

      if the error seems to be the fault of Home Manager.
      EOF
        exit 1
      fi
    '';
  }
  ""
