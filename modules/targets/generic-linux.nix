{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.targets.genericLinux;

  inherit (config.home) profileDirectory;

  nixPkg = if config.nix.package == null then pkgs.nix else config.nix.package;

  nixPackagePname = nixPkg.pname or (lib.getName nixPkg);
  nixPackageVersion = nixPkg.version or null;
  supportsNixStateHome =
    nixPackagePname == "nix"
    && nixPackageVersion != null
    && lib.versionAtLeast nixPackageVersion "2.25";

  nixEnvironmentPackage =
    let
      posixScript = pkgs.writeText "hm-nix-environment.sh" ''
        # shellcheck shell=sh
        # Keep this resolver in sync with the standard Nix profile script.
        if [ -n "''${HOME-}" ]; then
          __hm_nix_prepend() {
            __hm_nix_name=$1
            __hm_nix_entry=$2
            eval "__hm_nix_value=\''${$__hm_nix_name-}"
            case ":$__hm_nix_value:" in
              *":$__hm_nix_entry:"*) return ;;
            esac
            __hm_nix_value="$__hm_nix_entry''${__hm_nix_value:+:}$__hm_nix_value"
            eval "$__hm_nix_name=\$__hm_nix_value"
            export "$__hm_nix_name"
          }

          __hm_nix_append() {
            __hm_nix_name=$1
            __hm_nix_entry=$2
            eval "__hm_nix_value=\''${$__hm_nix_name-}"
            case ":$__hm_nix_value:" in
              *":$__hm_nix_entry:"*) return ;;
            esac
            __hm_nix_value="$__hm_nix_value''${__hm_nix_value:+:}$__hm_nix_entry"
            eval "$__hm_nix_name=\$__hm_nix_value"
            export "$__hm_nix_name"
          }

          __hm_nix_hm_profile=${lib.escapeShellArg (toString profileDirectory)}
          ${
            if supportsNixStateHome then
              ''
                if [ -n "''${NIX_STATE_HOME-}" ]; then
                  __hm_nix_profile="$NIX_STATE_HOME/profile"
                else
                  __hm_nix_profile="$HOME/.nix-profile"
                  if [ -n "''${XDG_STATE_HOME-}" ]; then
                    __hm_nix_xdg_profile="$XDG_STATE_HOME/nix/profile"
                  else
                    __hm_nix_xdg_profile="$HOME/.local/state/nix/profile"
                  fi
                  if [ -e "$__hm_nix_xdg_profile" ]; then
                    __hm_nix_profile="$__hm_nix_xdg_profile"
                  fi
                fi
              ''
            else
              ''
                __hm_nix_profile="$HOME/.nix-profile"
                if [ -n "''${XDG_STATE_HOME-}" ]; then
                  __hm_nix_xdg_profile="$XDG_STATE_HOME/nix/profile"
                else
                  __hm_nix_xdg_profile="$HOME/.local/state/nix/profile"
                fi
                if [ -e "$__hm_nix_xdg_profile" ]; then
                  __hm_nix_profile="$__hm_nix_xdg_profile"
                fi
              ''
          }

          # Match the existing Generic Linux command precedence on a cold start:
          # Nix adds its active profile, then Home Manager adds its own profile.
          __hm_nix_prepend PATH "$__hm_nix_profile/bin"
          __hm_nix_prepend PATH "$__hm_nix_hm_profile/bin"

          if [ -z "''${XDG_DATA_DIRS-}" ]; then
            XDG_DATA_DIRS=/usr/local/share:/usr/share
            export XDG_DATA_DIRS
          fi
          __hm_nix_prepend XDG_DATA_DIRS "$__hm_nix_hm_profile/share"
          __hm_nix_prepend XDG_DATA_DIRS "''${NIX_STATE_DIR:-/nix/var/nix}/profiles/default/share"
          __hm_nix_append XDG_DATA_DIRS "$__hm_nix_profile/share"

          if [ -n "''${MANPATH-}" ]; then
            __hm_nix_prepend MANPATH "$__hm_nix_profile/share/man"
          fi

          if [ -z "''${NIX_PROFILES+x}" ]; then
            NIX_PROFILES="/nix/var/nix/profiles/default $__hm_nix_profile"
            export NIX_PROFILES
          fi

          if [ -z "''${NIX_SSL_CERT_FILE+x}" ]; then
            for __hm_nix_cert in \
              /etc/ssl/certs/ca-certificates.crt \
              /etc/ssl/ca-bundle.pem \
              /etc/ssl/certs/ca-bundle.crt \
              /etc/pki/tls/certs/ca-bundle.crt \
              "$__hm_nix_profile/etc/ssl/certs/ca-bundle.crt" \
              "$__hm_nix_profile/etc/ca-bundle.crt"
            do
              if [ -e "$__hm_nix_cert" ]; then
                NIX_SSL_CERT_FILE=$__hm_nix_cert
                export NIX_SSL_CERT_FILE
                break
              fi
            done
          fi

          unset -f __hm_nix_prepend __hm_nix_append
          unset __hm_nix_name __hm_nix_entry __hm_nix_value
          unset __hm_nix_hm_profile __hm_nix_profile __hm_nix_xdg_profile __hm_nix_cert
        fi
      '';

      fishScript = pkgs.writeText "hm-nix-environment.fish" ''
        function __hm_nix_prepend_path --argument-names name entry
            contains -- $entry $$name; and return
            set -gx $name $entry $$name
        end

        function __hm_nix_prepend_xdg --argument-names entry
            contains -- $entry (string split : -- "$XDG_DATA_DIRS"); and return
            set -gx XDG_DATA_DIRS "$entry"(test -n "$XDG_DATA_DIRS"; and printf :%s "$XDG_DATA_DIRS")
        end

        function __hm_nix_append_xdg --argument-names entry
            contains -- $entry (string split : -- "$XDG_DATA_DIRS"); and return
            set -gx XDG_DATA_DIRS "$XDG_DATA_DIRS"(test -n "$XDG_DATA_DIRS"; and printf :)"$entry"
        end

        if test -n "$HOME"
            set -l __hm_nix_hm_profile ${lib.escapeShellArg (toString profileDirectory)}
            set -l __hm_nix_profile "$HOME/.nix-profile"
            set -l __hm_nix_xdg_profile
            set -l __hm_nix_state_dir /nix/var/nix
            ${
              if supportsNixStateHome then
                ''
                  if test -n "$NIX_STATE_HOME"
                      set __hm_nix_profile "$NIX_STATE_HOME/profile"
                  else
                      if test -n "$XDG_STATE_HOME"
                          set __hm_nix_xdg_profile "$XDG_STATE_HOME/nix/profile"
                      else
                          set __hm_nix_xdg_profile "$HOME/.local/state/nix/profile"
                      end
                      if test -e "$__hm_nix_xdg_profile"
                          set __hm_nix_profile "$__hm_nix_xdg_profile"
                      end
                  end
                ''
              else
                ''
                  if test -n "$XDG_STATE_HOME"
                      set __hm_nix_xdg_profile "$XDG_STATE_HOME/nix/profile"
                  else
                      set __hm_nix_xdg_profile "$HOME/.local/state/nix/profile"
                  end
                  if test -e "$__hm_nix_xdg_profile"
                      set __hm_nix_profile "$__hm_nix_xdg_profile"
                  end
                ''
            }

            __hm_nix_prepend_path PATH "$__hm_nix_profile/bin"
            __hm_nix_prepend_path PATH "$__hm_nix_hm_profile/bin"

            if test -z "$XDG_DATA_DIRS"
                set -gx XDG_DATA_DIRS /usr/local/share:/usr/share
            end
            if test -n "$NIX_STATE_DIR"
                set __hm_nix_state_dir "$NIX_STATE_DIR"
            end
            __hm_nix_prepend_xdg "$__hm_nix_hm_profile/share"
            __hm_nix_prepend_xdg "$__hm_nix_state_dir/profiles/default/share"
            __hm_nix_append_xdg "$__hm_nix_profile/share"

            if test -n "$MANPATH"
                __hm_nix_prepend_path MANPATH "$__hm_nix_profile/share/man"
            end

            if not set -q NIX_PROFILES
                set -gx NIX_PROFILES "/nix/var/nix/profiles/default $__hm_nix_profile"
            end

            if not set -q NIX_SSL_CERT_FILE
                for __hm_nix_cert in \
                    /etc/ssl/certs/ca-certificates.crt \
                    /etc/ssl/ca-bundle.pem \
                    /etc/ssl/certs/ca-bundle.crt \
                    /etc/pki/tls/certs/ca-bundle.crt \
                    "$__hm_nix_profile/etc/ssl/certs/ca-bundle.crt" \
                    "$__hm_nix_profile/etc/ca-bundle.crt"
                    if test -e "$__hm_nix_cert"
                        set -gx NIX_SSL_CERT_FILE "$__hm_nix_cert"
                        break
                    end
                end
            end
        end

        functions -e __hm_nix_prepend_path __hm_nix_prepend_xdg __hm_nix_append_xdg
      '';
    in
    pkgs.runCommandLocal "hm-generic-linux-nix-environment" { } ''
      install -Dm644 ${posixScript} $out/etc/profile.d/hm-nix-env.sh
      install -Dm644 ${fishScript} $out/etc/profile.d/hm-nix-env.fish
    '';

in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "targets" "genericLinux" "extraXdgDataDirs" ]
      [
        "xdg"
        "systemDirs"
        "data"
      ]
    )
    (lib.mkRenamedOptionModule [ "nixGL" ] [ "targets" "genericLinux" "nixGL" ])
    ./generic-linux/nixgl.nix
    ./generic-linux/gpu
  ];

  options.targets.genericLinux = {
    enable = lib.mkEnableOption "" // {
      description = ''
        Whether to enable settings that make Home Manager work better on
        GNU/Linux distributions other than NixOS.
      '';
    };

    nixEnvironmentPackage = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "targets.genericLinux" pkgs lib.platforms.linux)
    ];

    xdg.systemDirs.data = [
      # Nix profiles
      "\${NIX_STATE_DIR:-/nix/var/nix}/profiles/default/share"
      "${profileDirectory}/share"

      # Distribution-specific
      "/usr/share/ubuntu"
      "/usr/local/share"
      "/usr/share"
      "/var/lib/snapd/desktop"
    ];

    # We need to append system-wide FHS directories due to the default prefix
    # resolving to the Nix store.
    # https://github.com/nix-community/home-manager/pull/2891#issuecomment-1101064521
    home.sessionSearchVariables = {
      XCURSOR_PATH = [
        "${config.home.profileDirectory}/share/icons"
        "/usr/share/icons"
        "/usr/share/pixmaps"
      ];
    };

    targets.genericLinux.nixEnvironmentPackage = nixEnvironmentPackage;

    home.sessionVariablesExtra = ''
      # reset TERM with new TERMINFO available (if any)
      export TERM="$TERM"
    '';

    programs.zsh.envExtra = ''
      # Make system functions available to zsh
      () {
        setopt LOCAL_OPTIONS CASE_GLOB EXTENDED_GLOB

        local system_fpaths=(
            # Package default
            /usr/share/zsh/site-functions(/-N)

            # Debian
            /usr/share/zsh/functions/**/*(/-N)
            /usr/share/zsh/vendor-completions/(/-N)
            /usr/share/zsh/vendor-functions/(/-N)
        )
        fpath=(''${fpath} ''${system_fpaths})
      }
    '';

    systemd.user.sessionVariables =
      let
        # https://github.com/archlinux/svntogit-packages/blob/packages/ncurses/trunk/PKGBUILD
        # https://salsa.debian.org/debian/ncurses/-/blob/master/debian/rules
        # https://src.fedoraproject.org/rpms/ncurses/blob/main/f/ncurses.spec
        # https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-libs/ncurses/ncurses-6.2-r1.ebuild
        distroTerminfoDirs = lib.concatStringsSep ":" [
          "/etc/terminfo" # debian, fedora, gentoo
          "/lib/terminfo" # debian
          "/usr/share/terminfo" # package default, all distros
        ];
      in
      {
        NIX_PATH =
          if config.nix.useXdg then
            "${config.xdg.stateHome}/nix/defexpr/channels\${NIX_PATH:+:}$NIX_PATH"
          else
            "$HOME/.nix-defexpr/channels\${NIX_PATH:+:}$NIX_PATH";
        TERMINFO_DIRS = "${profileDirectory}/share/terminfo:$TERMINFO_DIRS\${TERMINFO_DIRS:+:}${distroTerminfoDirs}";
      };
  };
}
