{ config, lib, pkgs, ... }:
let
  cfg = config.services.git-workspace;
  tomlFormat = pkgs.formats.toml { };
  workspaceType = types.submodule {
    freeformType = tomlFormat.type;

    options.provider = mkOption {
      type = types.listOf (types.submodule {
        freeformType = tomlFormat.type;
        options = {
          provider = mkOption {
            type = types.str;
            example = "github";
          };

          name = mkOption {
            type = types.str;
            example = "torvalds";
          };

          path = mkOption {
            type = types.path;
            example =
              literalExpression ''"''${config.home.homeDirectory}/projects"'';
          };
        };
      });
    };
  };
  inherit (lib)
    mkOption mkEnableOption mkPackageOption types literalExpression mkIf
    mapAttrs';
in {
  meta.maintainers = [ lib.maintainers.aciceri ];

  options.services.git-workspace = {
    enable = mkEnableOption "git-workspace systemd timer";

    package = mkOption {
      type = types.package;
      default = if config.programs.git-workspace.enable then
        config.programs.git-workspace.package
      else
        pkgs.git-workspace;
      defaultText = literalExpression ''
        if config.programs.git-workspace.enable then
          config.programs.git-workspace.package
        else
          pkgs.git-workspace;
      '';
      description = "The git-workspace package to use";
    };

    frequency = mkOption {
      type = types.str;
      example = "daily";
      default = "daily";
      description = ''
        The refresh frequency. Check <literal>man systemd.time</literal> for
        more information on the syntax.
      '';
    };

    environmentFile = mkOption {
      type = types.path;
      description = ''
        Path to the systemd <literal>EnvironmentFile</literal> to keep tokens,
        do not put a derivation output here since it would expose secrets in
        the world readable Nix store.
            </para><para>
        It contains lines like
        <literal>
        GITHUB_TOKEN=ghp_...
        </literal>
            </para><para>
        If you want to use Nix to manage these tokens use a tool like sops-nix
        or agenix. This file must be readable by the home-manager user.
      '';
      example = "/var/lib/git-workspace-tokens";
    };

    workspaces = mkOption {
      type = types.attrsOf workspaceType;
      default = { };
      description = ''
        1:1 representation of a single <literal>workspace.toml</literal> consumed
        by git-workspace.
      '';
      example = literalExpression ''
        {
          personal.provider = [
            {
              provider = "github"
              name = "github_username"
              path = "''${config.home.homeDirectory}/personal_projects"
              skip_forks = false;
            }
            {
              provider = "gitlab"
              name = "gitlab_username"
              # it's possible to use the same path as previous provider
              # if there are not name clashes
              path = "''${config.home.homeDirectory}/personal_projects"
            }
          ];
          work.provider = [
            {
              provider = "github"
              name = "github_org"
              path = "''${config.home.homeDirectory}/work"
            }
          ];
        };
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.git-workspace" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = mapAttrs' (workspaceName: workspace: {
      name = "git-workspace/${workspaceName}/workspace.toml";
      value.source = (tomlFormat.generate "${workspaceName}-workspace.toml"
        workspace).outPath;
    }) cfg.workspaces;

    systemd.user.services = mapAttrs' (workspaceName: workspace: rec {
      name = "git-workspace-${workspaceName}-update";
      value = {
        Unit.Description = "Runs `git-workspace update` for ${workspaceName}";
        Service = {
          EnvironmentFile = cfg.environmentFile;
          ExecStart = let
            script = pkgs.writeShellApplication {
              name = "${name}-launcher";
              text = ''
                ${cfg.package}/bin/git-workspace \
                  --workspace ${config.xdg.configHome}/git-workspace/${workspaceName} \
                  update
              '';
              runtimeInputs = with pkgs; [ busybox openssh git ];
            };
          in "${script}/bin/${name}-launcher";
        };
      };
    }) cfg.workspaces;

    systemd.user.timers = mapAttrs' (workspaceName: workspace: {
      name = "git-workspace-${workspaceName}-update";
      value = {
        Unit = {
          Description =
            "Automatically runs `git-workspace update` for ${workspaceName}";
        };
        Timer = {
          Unit = "git-workspace-${workspaceName}-update.unit";
          OnCalendar = cfg.frequency;
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    }) cfg.workspaces;
  };
}
