{ lib, pkgs, ... }:
let
  nixosLib = import /${pkgs.path}/nixos/lib { inherit lib; };
  getUseXdg =
    osNix: userNix:
    (nixosLib.evalTest {
      hostPkgs = pkgs;
      nodes.machine.imports = [
        ../../../../nixos
        {
          nix = osNix;
          home-manager.users.user = {
            home.stateVersion = "26.05";
            nix = userNix;
          };
        }
      ];
    }).config.nodes.machine.home-manager.users.user.nix.useXdg;
in
{
  nmt.script =
    # Defaults to false
    assert !getUseXdg { } { };

    # Test OS config
    assert !getUseXdg { enable = true; } { };
    assert
      !getUseXdg {
        enable = false;
        settings.use-xdg-base-directories = true;
      } { };
    assert getUseXdg {
      enable = true;
      settings.use-xdg-base-directories = true;
    } { };

    # Test user config
    assert !getUseXdg { } { enable = true; };
    assert
      !getUseXdg { } {
        enable = false;
        settings.use-xdg-base-directories = true;
      };
    assert getUseXdg { } {
      enable = true;
      settings.use-xdg-base-directories = true;
    };

    # Fallback to OS config if user config is unset
    assert getUseXdg
      {
        enable = true;
        settings.use-xdg-base-directories = true;
      }
      {
        enable = true;
      };

    # But user config takes precedence
    assert
      !getUseXdg
        {
          enable = true;
          settings.use-xdg-base-directories = true;
        }
        {
          enable = true;
          settings.use-xdg-base-directories = false;
        };
    assert getUseXdg
      {
        enable = true;
        settings.use-xdg-base-directories = false;
      }
      {
        enable = true;
        settings.use-xdg-base-directories = true;
      };

    # assumeXdg also takes precedence
    assert getUseXdg { } { assumeXdg = true; };
    assert getUseXdg
      {
        enable = true;
        settings.use-xdg-base-directories = false;
      }
      {
        enable = false;
        assumeXdg = true;
      };
    "";
}
