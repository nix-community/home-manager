{ config, ... }:

{
  services.recoll = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    configDir = "${config.xdg.configHome}/recoll";
    settings = {
      dbdir = "~/.cache/recoll/xapiandb";
      topdirs = [ "~/Downloads" "~/Documents" "~/library" ''~/"cool" files'' ];
      "skippedNames+" = [ "node_modules" ];
      underscoresasletter = true;
      nocjk = false;

      "~/library/projects" = {
        "skippedNames+" =
          [ ".editorconfig" ".gitignore" "result" "flake.lock" "go.sum" ];
      };

      "~/library/projects/software" = {
        "skippedNames+" = [ "target" "result" ];
      };

      "~/what-is-this-project" = { "skippedNames+" = [ "whoa-there" ]; };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/recollindex.service
    assertFileExists home-files/.config/systemd/user/recollindex.timer

    assertFileExists home-files/.config/recoll/recoll.conf
    assertFileContent home-files/.config/recoll/recoll.conf \
        ${./basic-configuration.conf}
  '';
}
