{
  pkgs ? import <nixpkgs> { },
  enableBig ? true,
  enableLegacyIfd ? false,
}:

let

  lib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  nmtSrc = fetchTarball {
    url = "https://git.sr.ht/~rycee/nmt/archive/v0.5.1.tar.gz";
    sha256 = "0qhn7nnwdwzh910ss78ga2d00v42b0lspfd7ybl61mpfgz3lmdcj";
  };

  # Recursively replace each derivation in the given attribute set with the same
  # derivation but with the `outPath` attribute set to the string
  # `"@package-name@"`. This allows the tests to refer to derivations through
  # their values without establishing an actual dependency on the derivation
  # output.
  scrubDerivation =
    name: value:
    let
      scrubbedValue = scrubDerivations value;

      newDrvAttrs = {
        buildScript = abort "no build allowed";

        outPath = builtins.traceVerbose "${name} - got out path" "@${lib.getName value}@";

        # Prevent getOutput from descending into outputs
        outputSpecified = true;

        # Allow the original package to be used in derivation inputs
        __spliced = {
          buildHost = value;
          hostTarget = value;
        };
      };
    in
    if lib.isAttrs value then
      if lib.isDerivation value then scrubbedValue // newDrvAttrs else scrubbedValue
    else
      value;
  scrubDerivations = lib.mapAttrs scrubDerivation;

  # Globally unscrub a few selected packages that are used by a wide selection of tests.
  whitelist =
    let
      inner = self: super: {
        inherit (pkgs)
          coreutils
          crudini
          jq
          desktop-file-utils
          diffutils
          findutils
          glibcLocales
          gettext
          gnugrep
          gnused
          shared-mime-info
          emptyDirectory
          # Needed by pretty much all tests that have anything to do with fish.
          babelfish
          fish
          ;

        xorg = super.xorg.overrideScope (self: super: { inherit (pkgs.xorg) lndir; });
      };

      outer =
        self: super:
        inner self super
        // {
          buildPackages = super.buildPackages.extend inner;
        };
    in
    outer;

  # TODO: figure out stdenv stubbing so we don't have to do this
  darwinScrublist = import ./darwinScrublist.nix { inherit lib scrubDerivation; };

  scrubbedPkgs =
    # TODO: fix darwin stdenv stubbing
    if isDarwin then
      let
        rawPkgs = lib.makeExtensible (final: pkgs);
      in
      builtins.traceVerbose "eval scrubbed darwin nixpkgs" (rawPkgs.extend darwinScrublist)
    else
      let
        rawScrubbedPkgs = lib.makeExtensible (final: scrubDerivations pkgs);
      in
      builtins.traceVerbose "eval scrubbed nixpkgs" (rawScrubbedPkgs.extend whitelist);

  modules =
    import ../modules/modules.nix {
      inherit lib pkgs;
      check = false;
    }
    ++ [
      (
        { config, ... }:
        {
          _module.args = {
            # Prevent the nixpkgs module from working. We want to minimize the number
            # of evaluations of Nixpkgs.
            pkgsPath = abort "pkgs path is unavailable in tests";
            realPkgs = pkgs;
            pkgs =
              let
                overlays =
                  config.test.stubOverlays ++ lib.optionals (config.nixpkgs.overlays != null) config.nixpkgs.overlays;
                stubbedPkgs =
                  if overlays == [ ] then
                    scrubbedPkgs
                  else
                    builtins.traceVerbose "eval overlayed nixpkgs" (lib.foldr (o: p: p.extend o) scrubbedPkgs overlays);
              in
              lib.mkImageMediaOverride stubbedPkgs;
          };

          # Fix impurities. Without these some of the user's environment
          # will leak into the tests through `builtins.getEnv`.
          xdg.enable = lib.mkDefault true;
          home = {
            username = "hm-user";
            homeDirectory = "/home/hm-user";
            stateVersion = lib.mkDefault "18.09";
          };

          # Avoid including documentation since this will cause
          # unnecessary rebuilds of the tests.
          manual.manpages.enable = lib.mkDefault false;

          imports = [
            ./asserts.nix
            ./big-test.nix
            ./stubs.nix
          ];

          test.enableBig = enableBig;
          test.enableLegacyIfd = enableLegacyIfd;
        }
      )
    ];

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
import nmtSrc {
  inherit lib pkgs modules;
  testedAttrPath = [
    "home"
    "activationPackage"
  ];
  tests =
    builtins.foldl'
      (
        a: b:
        a
        // (
          let
            imported = import b;
          in
          if lib.isFunction imported then imported { inherit lib pkgs; } else imported
        )
      )
      { }
      (
        [
          # keep-sorted start case=no numeric=yes
          ./lib/generators
          ./lib/types
          ./modules/files
          ./modules/home-environment
          ./modules/misc/fontconfig
          ./modules/misc/manual
          ./modules/misc/news
          ./modules/misc/nix
          ./modules/misc/nix-remote-build
          ./modules/misc/specialisation
          ./modules/misc/xdg
          ./modules/xresources
          # keep-sorted end
        ]
        ++ lib.optionals isDarwin [
          # keep-sorted start case=no numeric=yes
          ./modules/launchd
          ./modules/targets-darwin
          # keep-sorted end
        ]
        ++ lib.optionals isLinux [
          # keep-sorted start case=no numeric=yes
          ./modules/config/home-cursor
          ./modules/config/i18n
          ./modules/dbus
          ./modules/i18n/input-method
          ./modules/misc/debug
          ./modules/misc/editorconfig
          ./modules/misc/gtk
          ./modules/misc/numlock
          ./modules/misc/pam
          ./modules/misc/qt
          ./modules/misc/xdg/linux.nix
          ./modules/misc/xsession
          ./modules/systemd
          ./modules/targets-linux
          # keep-sorted end
        ]
        ++ (lib.concatMap
          (
            dir:
            lib.pipe dir [
              builtins.readDir
              (lib.filterAttrs (_path: kind: kind == "directory"))
              (lib.mapAttrsToList (path: _kind: lib.path.append dir path))
            ]
          )
          [
            ./modules/services
            ./modules/programs
          ]
        )
      );
}
