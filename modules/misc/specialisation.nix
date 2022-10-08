{ config, name, extendModules, lib, ... }:

with lib;

let cfg = config.specialisation;
in {
  imports =
    [ (mkRenamedOptionModule [ "specialization" ] [ "specialisation" ]) ];

  options.specialisation = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        configuration = mkOption {
          type = let
            extended = extendModules {
              modules = [{
                # Prevent infinite recursion
                specialisation = mkOverride 0 { };

                # If used inside the NixOS/nix-darwin module, we get conflicting definitions
                # of `name` inside the specialisation: one is the user name coming from the
                # NixOS module definition and the other is `configuration`, the name of this
                # option. Thus we need to explicitly wire the former into the module arguments.
                # See discussion at https://github.com/nix-community/home-manager/issues/3716
                _module.args.name = mkForce name;
              }];
            };
          in extended.type;
          default = { };
          visible = "shallow";
          description = ''
            Arbitrary Home Manager configuration settings.
          '';
        };
        default = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether this specialisation is activated by default.
            Note that setting this option will override the default activation
            script, making it impossible to activate the default
            configuration.
          '';
        };
      };
    });
    default = { };
    description = ''
      A set of named specialised configurations. These can be used to extend
      your base configuration with additional settings. For example, you can
      have specialisations named "light" and "dark"
      that apply light and dark color theme configurations.

      ::: {.note}
      This is an experimental option for now and you therefore have to
      activate the specialisation by looking up and running the activation
      script yourself. Running the activation script will create a new
      Home Manager generation.
      :::

      For example, to activate the "dark" specialisation, you can
      first look up your current Home Manager generation by running

      ```console
      $ home-manager generations | head -1
      2022-05-02 22:49 : id 1758 -> /nix/store/jy…ac-home-manager-generation
      ```

      then run

      ```console
      $ /nix/store/jy…ac-home-manager-generation/specialisation/dark/activate
      Starting Home Manager activation
      …
      ```

      ::: {.warning}
      Since this option is experimental, the activation process may
      change in backwards incompatible ways.
      :::
    '';
  };

  config = mkIf (cfg != { }) {
    assertions = [{
      assertion = count (s: s.default) (attrValues cfg) <= 1;
      message = "There can only be one default specialisation";
    }];

    home.extraBuilderCommands = let
      link = n: v:
        let pkg = v.configuration.home.activationPackage;
        in "ln -s ${pkg} $out/specialisation/${n}";
    in ''
      mkdir $out/specialisation
      ${concatStringsSep "\n" (mapAttrsToList link cfg)}
    '';

    home.activation = let
      defaultSpecialisation = findFirst (s: s.default) null (attrValues cfg);
    in mkIf (defaultSpecialisation != null) (mkForce {
      activateSpecialisation = ''
        ${defaultSpecialisation.configuration.home.activationPackage}/activate
      '';
    });
  };
}
