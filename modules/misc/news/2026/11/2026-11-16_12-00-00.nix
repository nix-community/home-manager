{ config, ... }:
{
  time = "2026-11-16T12:00:00+00:00";
  condition = config.programs.gtt.enable;
  message = ''
    A new module is available: `programs.gtt`.

    GTT, originally Google Translate TUI, is a TUI for accessing a variety of
    translation services such as Apertium, Bing, DeepL, DeepLX, Google, Libre
    and Reverso.
  '';
}
