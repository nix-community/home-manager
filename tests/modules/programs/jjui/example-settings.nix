{
  config = {
    programs.jjui = {
      enable = true;
      settings = {
        revisions = {
          template = "builtin_log_compact";
          revset = "ancestors(@ | heads(remote_branches())) ~ empty()";
        };
      };
      configLua = /* lua */ ''
        local foo = require("plugins.foo")
        local bar = require("plugins.bar")

        function setup(config)
          foo.setup("#5B8DEF", config)
          bar.setup("#5B8DEF", config)

          config.action("show diff in diffnav", function()
            local change_id = context.change_id()
            if not change_id or change_id == "" then
              flash({ text = "No revision selected", error = true })
              return
            end

            exec_shell(string.format("jj diff -r %q --git --color always | diffnav", change_id))
          end, { desc = "show diff in diffnav", key = "ctrl+d", scope = "revisions" })
        end
      '';
      plugins = {
        foo = ./foo.lua;
        bar = /* lua */ ''
          local M = {}

          function M.setup(primary, config)
            config.ui = config.ui or {}
            config.ui.colors = config.ui.colors or {}

            config.ui.colors.title = { fg = primary, bold = true }
          end

          return M
        '';
      };
    };

    nmt.script =
      let
        configDir = ".config/jjui";
      in
      ''
        assertFileContent \
          "home-files/${configDir}/config.toml" \
          ${./example-settings-expected.toml}

        assertFileContent \
          "home-files/${configDir}/config.lua" \
          ${./config-expected.lua}

        assertFileContent \
          "home-files/${configDir}/plugins/foo.lua" \
         ${./foo.lua}

        assertFileContent \
          "home-files/${configDir}/plugins/bar.lua" \
          ${./bar-expected.lua}
      '';
  };
}
