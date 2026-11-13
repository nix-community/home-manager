{
  lib,
  options,
  pkgs,
  ...
}:
{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts."hm@example.com".astroid = {
    enable = true;
    sendMailCommand = "sendmail";
    extraConfig.select_query = "tag:legacy";
  };
  accounts.email.accounts."hm@example.com".notmuch.enable = true;

  programs.astroid = {
    enable = true;
    package = null;
    settings = {
      thread_index.cell.tags_length = "100";
      accounts."hm@example.com".custom_key = "canonical";
      editor.cmd = lib.mkForce "canonical-editor";
    };
    extraConfig = {
      poll.interval = lib.mkDefault 0;
      accounts."hm@example.com".select_query = "tag:global";
      editor.cmd = "legacy-editor";
    };
    externalEditor = "external-editor";
  };

  test.asserts.warnings.expected = [
    "The option `programs.astroid.externalEditor' defined in ${lib.showFiles options.programs.astroid.externalEditor.files} has been changed to `programs.astroid.settings.editor' that has a different type. Please read `programs.astroid.settings.editor' documentation and update your configuration accordingly."
    "The option `programs.astroid.extraConfig' defined in ${lib.showFiles options.programs.astroid.extraConfig.files} has been renamed to `programs.astroid.settings'."
  ];

  nmt.script = ''
    assertFileExists home-files/.config/astroid/config
    ${pkgs.jq}/bin/jq -e '
      .thread_index.cell.tags_length == "100"
      and .poll.interval == 0
      and .editor.cmd == "canonical-editor"
      and .editor.external_editor == "true"
      and .accounts["hm@example.com"].select_query == "tag:global"
      and .accounts["hm@example.com"].custom_key == "canonical"
      and .accounts["hm@example.com"].email == "hm@example.com"
      and .astroid.notmuch_config == "/home/hm-user/.config/notmuch/default/config"
      and .crypto.gpg.path == "@gnupg@/bin/gpg"
      and (.astroid | keys) == ["notmuch_config"]
      and (.crypto.gpg | keys) == ["path"]
      and (. | keys) == ["accounts", "astroid", "crypto", "editor", "poll", "thread_index"]
    ' "$TESTED/home-files/.config/astroid/config"
    assertPathNotExists home-files/.config/astroid/poll.sh
  '';
}
