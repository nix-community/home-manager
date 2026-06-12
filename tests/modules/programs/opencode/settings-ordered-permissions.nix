{ lib, ... }:
{
  programs.opencode = {
    enable = true;
    settings = {
      permission.bash = {
        "aa *" = lib.hm.dag.entryAfter [ "zz *" ] "allow";
        "zz *" = "ask";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/opencode.json
    assertFileContent home-files/.config/opencode/opencode.json \
      ${./settings-ordered-permissions.json}
  '';
}
