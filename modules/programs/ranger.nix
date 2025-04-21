{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) literalExpression mkOption types;

  cfg = config.programs.ranger;
in
{
  options.programs.ranger = {
    enable = lib.mkEnableOption "ranger file manager";

    package = lib.mkPackageOption pkgs "ranger" { nullable = true; };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra packages added to ranger.";
    };

    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      visible = false;
      description = "Resulting ranger package.";
    };

    settings = mkOption {
      type = types.attrsOf (
        types.oneOf [
          types.bool
          types.float
          types.int
          types.str
        ]
      );
      default = { };
      description = ''
        Settings written to {file}`$XDG_CONFIG_HOME/ranger/rc.conf`.
      '';
      example = {
        column_ratios = "1,3,3";
        confirm_on_delete = "never";
        unicode_ellipsis = true;
        scroll_offset = 8;
      };
    };

    aliases = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Aliases written to {file}`$XDG_CONFIG_HOME/ranger/rc.conf`.
      '';
      example = {
        e = "edit";
        setl = "setlocal";
        filter = "scout -prts";
      };
    };

    mappings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Mappings written to {file}`$XDG_CONFIG_HOME/ranger/rc.conf`.
      '';
      example = {
        Q = "quitall";
        q = "quit";
      };
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to
        {file}`$XDG_CONFIG_HOME/ranger/rc.conf`.
      '';
    };

    plugins = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = ''
                Name of the plugin linked to
                {file}`$XDG_CONFIG_HOME/ranger/plugins/`. In the case of a
                single-file plugin, it must also have `.py` suffix.
              '';
            };
            src = mkOption {
              type = types.path;
              description = ''
                The plugin file or directory.
              '';
            };
          };
        }
      );
      default = [ ];
      description = ''
        List of files to be added to {file}`$XDG_CONFIG_HOME/ranger/plugins/`.
      '';
      example = literalExpression ''
        [
          {
            name = "zoxide";
            src = builtins.fetchGit {
              url = "https://github.com/jchook/ranger-zoxide.git";
              rev = "363df97af34c96ea873c5b13b035413f56b12ead";
            };
          }
        ]
      '';
    };

    rifle = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            condition = mkOption {
              type = types.str;
              description = ''
                A condition to match a file.
              '';
              example = "mime ^text, label editor";
            };
            command = mkOption {
              type = types.str;
              description = ''
                A command to run for the matching file.
              '';
              example = literalExpression ''"${pkgs.vim}/bin/vim -- \"$@\""'';
            };
          };
        }
      );
      default = [ ];
      description = ''
        Settings written to {file}`$XDG_CONFIG_HOME/ranger/rifle.conf`.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.extraPackages != [ ] -> cfg.package != null;
            message = "programs.ranger.extraPackages requires non-null programs.ranger.package";
          }
        ];

        programs.ranger.finalPackage = lib.mkIf (cfg.package != null) (
          cfg.package.overrideAttrs (oldAttrs: {
            propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or [ ]) ++ cfg.extraPackages;
          })
        );

        home.packages = lib.mkIf (cfg.package != null) [ cfg.finalPackage ];

        xdg.configFile."ranger/rc.conf".text =
          let
            mkString = lib.generators.mkValueStringDefault { };
            mkConfig =
              cmd:
              lib.generators.toKeyValue {
                mkKeyValue = k: v: "${cmd} ${k} ${mkString v}";
              };
          in
          ''
            ${mkConfig "set" cfg.settings}
            ${mkConfig "alias" cfg.aliases}
            ${mkConfig "map" cfg.mappings}
            ${cfg.extraConfig}
          '';
      }

      (lib.mkIf (cfg.plugins != [ ]) {
        xdg.configFile =
          let
            toAttrs = i: {
              name = "ranger/plugins/${i.name}";
              value.source = i.src;
            };
          in
          lib.listToAttrs (map toAttrs cfg.plugins);
      })

      (lib.mkIf (cfg.rifle != [ ]) {
        xdg.configFile."ranger/rifle.conf".text =
          let
            lines = map (i: "${i.condition} = ${i.command}") cfg.rifle;
          in
          lib.concatLines lines;
      })
    ]
  );

  meta.maintainers = [ lib.hm.maintainers.fpob ];
}
