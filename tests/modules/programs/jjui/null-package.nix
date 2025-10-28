{
  pkgs,
  ...
}:

{
  programs.jjui = {
    enable = true;
    package = null;
    settings = {
      revisions.template = "builtin_log_oneline";
    };
  };

  nmt.script =
    let
      configDir = if !pkgs.stdenv.isDarwin then ".config/jjui" else "Library/Application Support/jjui";
    in
    ''
      assertFileContent \
        "home-files/${configDir}/config.toml" \
        ${pkgs.writeText "expected" ''
          [revisions]
          template = "builtin_log_oneline"
        ''}
    '';
}
