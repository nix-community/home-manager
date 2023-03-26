{ config, lib, pkgs, ... }:
let
  cfg = config.services.git-workspace;
  tomlFormat = pkgs.formats.toml { };
  workspaceType = lib.types.submodule {
    freeformType = tomlFormat.type;
    options.provider = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        freeformType = tomlFormat.type;
        options = {
          provider = lib.mkOption {
            type = lib.types.str;
            example = "github";
          };
          name = lib.mkOption {
            type = lib.types.str;
            example = "aciceri";
          };
          path = lib.mkOption {
            type = lib.types.path;
            example = ''"${config.home.homeDirectory}/projects"'';
          };
        };
      });
    };
  };
in {
  meta.maintainers = [ lib.maintainers.aciceri ];
  options.services.git-workspace = {
    enable = lib.mkEnableOption "git-workspace systemd timer";
    package = lib.mkOption {
      type = lib.types.package;
      default = if config.programs.git-workspace.enable then
        config.programs.git-workspace.package
      else
        pkgs.git-workspace;
      description = "The git-workspace to use";
    };
    frequency = lib.mkOption {
      type = lib.types.str;
      example = "daily";
      default = "daily";
      description = ''
        The refresh frequency. Check <literal>man systemd.time</literal> for
        more information on the syntax.
      '';
    };
    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the systemd <literal>EnvironmentFile</literal> to keep tokens,
        do not put a derivation output here since it would expose secrets in
        the world readable Nix store.
        File content example:
        <literal>
        GITHUB_TOKEN=ghp_...
        </literal>
        If you want to use Nix to manage these tokens use a tool like sops-nix
        or agenix. This file must be readable by the
        <literal>home-manager</literal> user.
      '';
      example = "/run/git-workspace-tokens";
    };
    workspaces = lib.mkOption {
      type = lib.types.attrsOf workspaceType;
      default = { };
      description =
        "1:1 representation of a single `workspace.toml` consumed by `git-workspace`";
      example = lib.literalExpression ''
        {
          personal.provider = [
            {
              provider = "github"
              name = "github_username"
              path = "${config.home.homeDirectory}/personal_projects"
              skip_forks = false;
            }
            {
              provider = "gitlab"
              name = "gitlab_username"
              # it's possible to use the same path as previous provider
              # if there are not name clashes
              path = "${config.home.homeDirectory}/personal_projects"
            }
          ];
          work.provider = [
            {
              provider = "github"
              name = "github_org"
              path = "${config.home.homeDirectory}/work"
            }
          ];
        };
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.git-workspace" pkgs
        lib.platforms.linux)
    ];
    xdg.configFile = lib.mapAttrs' (workspaceName: workspace: {
      name = "git-workspace/${workspaceName}/workspace.toml";
      value.source = (tomlFormat.generate "${workspaceName}-workspace.toml"
        workspace).outPath;
    }) cfg.workspaces;
    systemd.user.services = lib.mapAttrs' (workspaceName: workspace: rec {
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
    systemd.user.timers = lib.mapAttrs' (workspaceName: workspace: {
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
