{ config, extendModules, lib, ... }:

with lib;

{
  options.specialization = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        configuration = mkOption {
          type = let
            stopRecursion = { specialization = mkOverride 0 { }; };
            extended = extendModules { modules = [ stopRecursion ]; };
          in extended.type;
          default = { };
          visible = "shallow";
          description = ''
            Arbitrary Home Manager configuration settings.
          '';
        };
      };
    });
    default = { };
    description = ''
      A set of named specialized configurations. These can be used to extend
      your base configuration with additional settings. For example, you can
      have specializations named <quote>light</quote> and <quote>dark</quote>
      that applies light and dark color theme configurations.

      </para><para>

      Note, this is an experimental option for now and you therefore have to
      activate the specialization by looking up and running the activation
      script yourself. Note, running the activation script will create a new
      Home Manager generation.

      </para><para>

      For example, to activate the <quote>dark</quote> specialization. You can
      first look up your current Home Manager generation by running

      <programlisting language="console">
        $ home-manager generations | head -1
        2022-05-02 22:49 : id 1758 -> /nix/store/jy…ac-home-manager-generation
      </programlisting>

      then run

      <programlisting language="console">
        $ /nix/store/jy…ac-home-manager-generation/specialization/dark/activate
        Starting Home Manager activation
        …
      </programlisting>

      </para><para>

      WARNING! Since this option is experimental, the activation process may
      change in backwards incompatible ways.
    '';
  };

  config = mkIf (config.specialization != { }) {
    home.extraBuilderCommands = let
      link = n: v:
        let pkg = v.configuration.home.activationPackage;
        in "ln -s ${pkg} $out/specialization/${n}";
    in ''
      mkdir $out/specialization
      ${concatStringsSep "\n" (mapAttrsToList link config.specialization)}
    '';
  };
}
