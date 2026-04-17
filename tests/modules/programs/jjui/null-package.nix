{
  pkgs,
  ...
}:

{
  config = {
    programs.jjui = {
      enable = true;
      package = null;
      settings = {
        revisions.template = "builtin_log_oneline";
      };
    };

    nmt.script =
      let
        configDir = ".config/jjui";
      in
      ''
        assertFileContent \
          "home-files/${configDir}/config.toml" \
          ${pkgs.writeText "expected" ''
            [revisions]
            template = "builtin_log_oneline"
          ''}
      '';
  };
}
