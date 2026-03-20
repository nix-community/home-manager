{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.targets.darwin.copyApps;
in
{
  options.targets.darwin.copyApps = {
    enable =
      lib.mkEnableOption "copying macOS applications to the user environment (works with Spotlight)"
      // {
        default =
          pkgs.stdenv.hostPlatform.isDarwin && (lib.versionAtLeast config.home.stateVersion "25.11");
        defaultText = lib.literalExpression ''pkgs.stdenv.hostPlatform.isDarwin && (lib.versionAtLeast config.home.stateVersion "25.11")'';
      };

    enableChecks = lib.mkEnableOption "enable App Management checks" // {
      default = true;
    };

    directory = lib.mkOption {
      type = lib.types.str;
      default = "Applications/Home Manager Apps";
      description = "Path to link apps relative to the home directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.targets.darwin.linkApps.enable;
        message = "`targets.darwin.copyApps.enable` conflicts with `targets.darwin.linkApps.enable`. Please disable one of them.";
      }
      (lib.hm.assertions.assertPlatform "targets.darwin.copyApps" pkgs lib.platforms.darwin)
    ];

    home.activation = {
      checkAppManagementPermission = lib.mkIf cfg.enableChecks (
        lib.hm.dag.entryBefore [ "copyApps" ]
          # bash
          ''
            ensureAppManagement() {
              for appBundle in '${cfg.directory}/'*.app; do
                if [[ -d "$appBundle" ]]; then
                  if ! run /usr/bin/touch "$appBundle/.DS_Store" &> /dev/null; then
                    return 1
                  fi
                fi
              done

              return 0
            }

            if ! ensureAppManagement; then
              if [[ "$(/bin/launchctl managername)" != Aqua ]]; then
                # It is possible to grant the App Management permission to `sshd-keygen-wrapper`, however
                # there are many pitfalls like requiring the primary user to grant the permission and to
                # be logged in when home-manager is run over SSH and it will still fail sometimes...
                printf >&2 '\e[1;31merror: permission denied when trying to update apps over SSH, aborting activation\e[0m\n'
                printf >&2 'Apps could not be updated as home-manager requires Full Disk Access to work over SSH.\n'
                printf >&2 'You can either:\n'
                printf >&2 '\n'
                printf >&2 '  grant Full Disk Access to all programs run over SSH\n'
                printf >&2 '\n'
                printf >&2 'or\n'
                printf >&2 '\n'
                printf >&2 '  run home-manager in a graphical session.\n'
                printf >&2 '\n'
                printf >&2 'The option "Allow full disk access for remote users" can be found by\n'
                printf >&2 'navigating to System Settings > General > Sharing > Remote Login\n'
                printf >&2 'and then pressing on the i icon next to the switch.\n'
                exit 1
              else
                # The TCC service required to modify notarised app bundles is `kTCCServiceSystemPolicyAppBundles`
                # and we can reset it to ensure the user gets another prompt
                run /usr/bin/tccutil reset SystemPolicyAppBundles > /dev/null

                if ! ensureAppManagement; then
                  printf >&2 '\e[1;31merror: permission denied when trying to update apps, aborting activation\e[0m\n'
                  printf >&2 'home-manager requires permission to update your apps, please accept the notification\n'
                  printf >&2 'and grant the permission for your terminal emulator in System Settings.\n'
                  printf >&2 '\n'
                  printf >&2 'If you did not get a notification, you can navigate to System Settings > Privacy & Security > App Management.\n'
                  exit 1
                fi
              fi
            fi
          ''
      );

      copyApps = lib.hm.dag.entryAfter [ "installPackages" ] (
        let
          applications = pkgs.buildEnv {
            name = "home-manager-applications";
            paths = config.home.packages;
            pathsToLink = [ "/Applications" ];
          };
        in
        # bash
        ''
          targetFolder='${cfg.directory}'

          echo "setting up ~/$targetFolder..." >&2

          ourLink () {
            local link
            link=$(readlink "$1")
            [ -L "$1" ] && [ "''${link#*-}" = 'home-manager-applications/Applications' ]
          }

          if [ -e "$targetFolder" ] && ourLink "$targetFolder"; then
            run rm "$targetFolder"
          fi

          run mkdir -p "$targetFolder"

          rsyncFlags=(
            # mtime is standardized in the nix store, which would leave only file size to distinguish files.
            # Thus we need checksums, despite the speed penalty.
            --checksum
            # Converts all symlinks pointing outside of the copied tree (thus unsafe) into real files and directories.
            # This neatly converts all the symlinks pointing to application bundles in the nix store into
            # real directories, without breaking any relative symlinks inside of application bundles.
            # This is good enough, because the make-symlinks-relative.sh setup hook converts all $out internal
            # symlinks to relative ones.
            --copy-unsafe-links
            --archive
            --delete
            --chmod=+w
            --no-group
            --no-owner
          )

          run ${lib.getExe pkgs.rsync} "''${rsyncFlags[@]}" ${applications}/Applications/ "$targetFolder"
        ''
      );
    };
  };
}
