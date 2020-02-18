{ home-manager, runCommand }:

runCommand "home-manager-install" {
  propagatedBuildInputs = [ home-manager ];
  preferLocalBuild = true;
  allowSubstitutes = false;
  shellHookOnly = true;
  shellHook = ''
    confFile="''${XDG_CONFIG_HOME:-$HOME/.config}/nixpkgs/home.nix"

    if [[ ! -e $confFile ]]; then
      echo
      echo "Creating initial Home Manager configuration..."

      mkdir -p "$(dirname "$confFile")"
      cat > $confFile <<EOF
    { config, pkgs, ... }:

    {
      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      home.stateVersion = "19.09";
    }
    EOF
    fi

    echo
    echo "Creating initial Home Manager generation..."
    echo

    if home-manager switch; then
      cat <<EOF

    All done! The home-manager tool should now be installed and you
    can edit

        $confFile

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
} ''
  echo This derivation is not buildable, instead run it using nix-shell.
  exit 1
''
