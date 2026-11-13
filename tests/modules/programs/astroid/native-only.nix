{ lib, pkgs, ... }:
{
  programs.astroid = {
    enable = true;
    package = null;
    settings = {
      editor.cmd = "native-editor";
      editor.external_editor = "true";
      poll.interval = 15;
      crypto.gpg.path = "/custom/gpg";
      thread_view.gravatar.enable = lib.mkForce "false";
    };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileExists home-files/.config/astroid/config
    ${pkgs.jq}/bin/jq -e '
      . == {
        "editor": {"cmd": "native-editor", "external_editor": "true"},
        "poll": {"interval": 15},
        "crypto": {"gpg": {"path": "/custom/gpg"}},
        "thread_view": {"gravatar": {"enable": "false"}}
      }
    ' "$TESTED/home-files/.config/astroid/config"
  '';
}
