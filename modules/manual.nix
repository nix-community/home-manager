{ config, lib, pkgs, baseModules, ... }:

with lib;

let

  cfg = config.manual;

  /* For the purpose of generating docs, evaluate options with each derivation
    in `pkgs` (recursively) replaced by a fake with path "\${pkgs.attribute.path}".
    It isn't perfect, but it seems to cover a vast majority of use cases.
    Caveat: even if the package is reached by a different means,
    the path above will be shown and not e.g. `${config.services.foo.package}`. */
  homeManagerManual = import ../doc {
    inherit pkgs config;
    version = "0.1";
    revision = "master";
    options =
      let
        scrubbedEval = evalModules {
          modules = [ { nixpkgs.localSystem = config.nixpkgs.localSystem; } ] ++ baseModules;
          args = (config._module.args) // { modules = [ ]; };
          specialArgs = { pkgs = scrubDerivations "pkgs" pkgs; };
        };
        scrubDerivations = namePrefix: pkgSet: mapAttrs
          (name: value:
            let wholeName = "${namePrefix}.${name}"; in
            if isAttrs value then
              scrubDerivations wholeName value
              // (optionalAttrs (isDerivation value) { outPath = "\${${wholeName}}"; })
            else value
          )
          pkgSet;
      in scrubbedEval.options;
  };

  manualHtmlRoot = "${homeManagerManual.manual}/share/doc/home-manager/index.html";

  helpScript = pkgs.writeShellScriptBin "home-manager-help" ''
    #!${pkgs.bash}/bin/bash -e

    if [ -z "$BROWSER" ]; then
      for candidate in xdg-open open w3m; do
        BROWSER="$(type -P $candidate || true)"
        if [ -x "$BROWSER" ]; then
          break;
        fi
      done
    fi

    if [ -z "$BROWSER" ]; then
      echo "$0: unable to start a web browser; please set \$BROWSER"
      exit 1
    fi

    exec "$BROWSER" ${manualHtmlRoot}
  '';

in

{
  options = {
    manual.html.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to install the HTML manual. This also installs the
        <command>home-manager-help</command> tool, which opens a local
        copy of the Home Manager manual in the system web browser.
      '';
    };

    manual.manpages.enable = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether to install the configuration manual page. The manual can
        be reached by <command>man home-configuration.nix</command>.
        </para><para>
        When looking at the manual page pretend that all references to
        NixOS stuff are actually references to Home Manager stuff.
        Thanks!
      '';
    };

    manual.json.enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to install a JSON formatted list of all Home Manager
        options. This can be located at
        <filename>&lt;profile directory&gt;/share/doc/home-manager/options.json</filename>,
        and may be used for navigating definitions, auto-completing,
        and other miscellaneous tasks.
      '';
    };
  };

  config = {
    home.packages = mkMerge [
      (mkIf cfg.html.enable [ helpScript homeManagerManual.manual  ])
      (mkIf cfg.manpages.enable [ homeManagerManual.manpages ])
      (mkIf cfg.json.enable [ homeManagerManual.optionsJSON ])
    ];
  };

  # To fix error during manpage build.
  meta = {
    maintainers = [ maintainers.rycee ];
    doc = builtins.toFile "nothingness" "";
  };
}
