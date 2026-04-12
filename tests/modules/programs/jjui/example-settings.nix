{
  config,
  pkgs,
  ...
}:

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
    };

    nmt.script =
      let
        configDir = ".config/jjui";
      in
      ''
        assertFileContent \
          "home-files/${configDir}/config.toml" \
          ${./example-settings-expected.toml}
      '';
  };
}
