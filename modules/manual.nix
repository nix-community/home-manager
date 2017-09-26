{ config, lib, pkgs, baseModules, ... }:

with lib;

let

  /* For the purpose of generating docs, evaluate options with each derivation
    in `pkgs` (recursively) replaced by a fake with path "\${pkgs.attribute.path}".
    It isn't perfect, but it seems to cover a vast majority of use cases.
    Caveat: even if the package is reached by a different means,
    the path above will be shown and not e.g. `${config.services.foo.package}`. */
  nixosManual = import <nixpkgs/nixos/doc/manual> {
    inherit pkgs config;
    version = "0.1";
    revision = "release-0.1";
    options =
      let
        scrubbedEval = evalModules {
          modules = [ { nixpkgs.system = pkgs.stdenv.system; } ] ++ baseModules;
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

  homeEnvironmentManPages = pkgs.runCommand "home-environment-manpages" {
      allowedReferences = [ "out" ];
    } ''
      install -v -D -m444 \
        ${nixosManual.manpages}/share/man/man5/configuration.nix.5 \
        $out/share/man/man5/home-configuration.nix.5
    '';

in

{
  options = {
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
  };

  config = mkIf config.manual.manpages.enable {
    home.packages = [ homeEnvironmentManPages ];
  };

  # To fix error during manpage build.
  meta = {
    maintainers = [ maintainers.rycee ];
    doc = builtins.toFile "nothingness" ''
      <chapter xmlns="http://docbook.org/ns/docbook"
               xmlns:xlink="http://www.w3.org/1999/xlink"
               xmlns:xi="http://www.w3.org/2001/XInclude"
               version="5.0"
               xml:id="sec-nothing">
        <title>this is just to make the docs compile</title>
        <para xml:id="sec-grsecurity"></para>
        <para xml:id="sec-emacs-docbook-xml"></para>
      </chapter>
    '';
  };
}
