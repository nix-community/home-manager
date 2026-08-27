{ lib, ... }:

let
  eval = lib.evalModules {
    modules = [
      {
        options.demo = lib.mkOption {
          type = lib.types.lazyAttrsOf lib.types.str;
          default = { };
        };
      }
      (lib.setDefaultModuleLocation "/fake/plain.nix" { demo.PLAIN = "plain"; })
      (lib.setDefaultModuleLocation "/fake/merge.nix" {
        demo = lib.mkMerge [ { MERGED = "merged"; } ];
      })
      (lib.setDefaultModuleLocation "/fake/conditional.nix" {
        demo = lib.mkIf true { CONDITIONAL = "conditional"; };
      })
      (lib.setDefaultModuleLocation "/fake/disabled.nix" {
        demo = {
          CONDITIONAL = lib.mkIf false "disabled";
          DISABLED = lib.mkIf false "disabled";
        };
      })
      (lib.setDefaultModuleLocation "/fake/order.nix" {
        demo.ORDERED = lib.mkBefore "order";
      })
      (lib.setDefaultModuleLocation "/fake/default.nix" {
        demo = {
          FORCED = lib.mkDefault "default";
          PRIORITY = lib.mkDefault "default";
        };
      })
      (lib.setDefaultModuleLocation "/fake/user.nix" {
        demo.PRIORITY = "user";
      })
      (lib.setDefaultModuleLocation "/fake/force.nix" {
        demo.FORCED = lib.mkForce "force";
      })
      (lib.setDefaultModuleLocation "/fake/outer.nix" {
        demo.LOCATED = lib.mkDefinition {
          file = "/fake/inner.nix";
          value = "located";
        };
      })
    ];
  };

  files = lib.hm.options.attrDefinitionFiles eval.options.demo;
in
{
  assertions = [
    {
      assertion = files "PLAIN" == [ "/fake/plain.nix" ];
      message = "plain attribute definition was not attributed";
    }
    {
      assertion = files "MERGED" == [ "/fake/merge.nix" ];
      message = "mkMerge attribute definition was not attributed";
    }
    {
      assertion = files "CONDITIONAL" == [ "/fake/conditional.nix" ];
      message = "mkIf attribute definition was attributed incorrectly";
    }
    {
      assertion = files "PRIORITY" == [ "/fake/user.nix" ];
      message = "losing mkDefault attribute definition was attributed";
    }
    {
      assertion = files "ORDERED" == [ "/fake/order.nix" ];
      message = "mkOrder attribute definition was not attributed";
    }
    {
      assertion = files "FORCED" == [ "/fake/force.nix" ];
      message = "losing nested definition was attributed";
    }
    {
      assertion = files "DISABLED" == [ ];
      message = "false nested mkIf attribute definition was attributed";
    }
    {
      assertion = files "LOCATED" == [ "/fake/inner.nix" ];
      message = "mkDefinition location was not preserved";
    }
  ];

  nmt.script = ''
    echo "attribute definition locations checked" >/dev/null
  '';
}
