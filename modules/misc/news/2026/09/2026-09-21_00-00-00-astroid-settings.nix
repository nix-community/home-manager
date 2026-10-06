{ config, ... }:
{
  time = "2026-09-21T00:00:00+00:00";
  condition = config.programs.astroid.enable;
  message = ''
    Astroid now supports JSON configuration through
    `programs.astroid.settings`. Move `programs.astroid.extraConfig` into
    `settings` and `programs.astroid.externalEditor` to `settings.editor.cmd`
    with `settings.editor.external_editor = "true"`. Both deprecated options
    remain as aliases and emit warnings. Home Manager supplies account,
    notmuch, and GPG defaults only when astroid accounts are configured; other
    defaults come from Astroid. Its built-in `editor.markdown_processor` is
    `cmark` instead of `marked`; set
    `programs.astroid.settings.editor.markdown_processor = "marked"` to keep
    `marked`. No config file is written for empty settings. Per-account
    `astroid.extraConfig` remains supported. Consolidate overlapping legacy
    and native keys under `settings`.
  '';
}
