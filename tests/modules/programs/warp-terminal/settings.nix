{
  config,
  pkgs,
  realPkgs,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  configDir = if isDarwin then "home-files/.warp" else "home-files/.config/warp-terminal";
  dataDir = if isDarwin then "home-files/.warp" else "home-files/.local/share/warp-terminal";
in
{
  programs.warp-terminal = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "warp-terminal";
      buildScript = ''
        for dir in opt/warpdotdev/warp-terminal/resources Applications/Warp.app/Contents/Resources; do
          mkdir -p $out/$dir
          cp ${./settings-schema.json} $out/$dir/settings_schema.json
        done
      '';
    };

    settings = {
      appearance.text = {
        font_name = "JetBrains Mono";
        font_size = 14.0;
      };
      text_editing.vim_mode_enabled = true;
    };

    keybindings."workspace:toggle_warp_drive" = "ctrl-shift-D";

    themes = {
      solarized_nix = {
        name = "Solarized Nix";
        accent = "#268bd2";
        background = "#002b36";
        foreground = "#839496";
        details = "darker";
        terminal_colors =
          let
            colors = {
              black = "#073642";
              red = "#dc322f";
              green = "#859900";
              yellow = "#b58900";
              blue = "#268bd2";
              magenta = "#d33682";
              cyan = "#2aa198";
              white = "#eee8d5";
            };
          in
          {
            normal = colors;
            bright = colors;
          };
      };
      from_file = ./theme.yaml;
    };

    tabConfigs.dev_server = {
      name = "Dev Server";
      panes = [
        {
          id = "main";
          type = "terminal";
          directory = "~/code/my-app";
          commands = [ "npm run dev" ];
        }
      ];
    };

    defaultTabConfigs.worktree = ./worktree.toml;

    workflows.git_undo = {
      name = "Undo the last commit";
      command = "git reset --soft HEAD~1";
      tags = [ "git" ];
    };

    launchConfigurations.home = {
      name = "Home";
      windows = [ { tabs = [ { layout.cwd = "/home/hm-user"; } ]; } ];
    };

    customModelRouters.cost_saver = {
      name = "Cost saver";
      type = "complexity";
      default = "glm-5.3-fireworks";
      routing.hard = "deepseek-v4.1-flash-fireworks";
    };

    skills = {
      git-workflow = ''
        ---
        name: git-workflow
        description: Create atomic commits.
        ---

        Commit each logical change separately.
      '';
      code-review = ./skills/code-review;
    };
  };

  test.unstubs = [ (_self: _super: { inherit (realPkgs) check-jsonschema; }) ];

  nmt.script = ''
    assertFileContent ${configDir}/settings.toml ${./settings.toml}
    assertFileContent ${configDir}/keybindings.yaml ${./keybindings.yaml}
    assertFileContent ${dataDir}/themes/solarized_nix.yaml ${./solarized_nix.yaml}
    assertFileContent ${dataDir}/themes/from_file.yaml ${./theme.yaml}
    assertFileContent ${dataDir}/tab_configs/dev_server.toml ${./dev_server.toml}
    assertFileContent ${dataDir}/default_tab_configs/worktree.toml ${./worktree.toml}
    assertFileContent ${dataDir}/workflows/git_undo.yaml ${./git_undo.yaml}
    assertFileContent ${dataDir}/launch_configurations/home.yaml ${./home.yaml}
    assertFileContent ${dataDir}/custom_model_routers/cost_saver.yaml ${./cost_saver.yaml}
    assertFileContent home-files/.warp/skills/git-workflow/SKILL.md ${./git-workflow.md}
    assertFileContent home-files/.warp/skills/code-review/SKILL.md \
      ${./skills/code-review/SKILL.md}
    assertPathNotExists home-files/.warp/.mcp.json
  '';
}
