{
  pkgs,
  realPkgs,
  config,
  ...
}:

{
  programs.nushell = {
    enable = true;
    package = realPkgs.nushell;
    plugins = [ realPkgs.nushellPlugins.formats ];
  };

  nmt.script =
    let
      configDir =
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "home-files/Library/Application Support/nushell"
        else
          "home-files/.config/nushell";
      pluginConfig = configDir + "/plugin.msgpackz";
    in
    ''
      out=$(mktemp)
      pluginConfig=$(_abs ${pluginConfig})
      pluginFormatsFilename=$(_abs ${realPkgs.nushellPlugins.formats})/bin/nu_plugin_formats

      ${realPkgs.nushell}/bin/nu \
        --plugin-config $pluginConfig \
        ${./with-plugin/get-plugin-info.nu} "formats" $out

      assertFileExists ${pluginConfig}
      assertFileContains $out \
        "[[name, status, filename]; [formats, loaded, \"$pluginFormatsFilename\"]]"
    '';
}
