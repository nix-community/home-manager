{
  time = "2026-04-12T11:50:28+00:00";
  condition = true;
  message = ''
    The `programs.jjui` module has been updated to the latest jjui configuration options.

    To adhere to the jjui defaults, `configDir` on Darwin now defaults to `~/.config/jjui/` from the previous `~/Library/Application Support/jjui/`.
    See https://idursun.github.io/jjui/customization/config-toml/.

    New module options are available:
      - `configLua` to configure the top-level Lua configuration, and
      - `plugins` to define Lua plugins.
    Remember to import and set up the defined plugins in `configLua`.
    For documentation on Lua configuration, see https://idursun.github.io/jjui/customization/config-lua/.
  '';
}
