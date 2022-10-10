{ config, lib, pkgs, ... }:

with lib;

let
  conf = builtins.toFile "settings-expected" "";
  keys = builtins.toFile "keys" ''
    add-item  a A
    del-item  d D
    edit-item  e E
    edit-note  n N
    end-of-week  $
    flag-item  !
    generic-add-appt  ^A
    generic-add-todo  ^T
    generic-cancel  ESC
    generic-change-view  TAB
    generic-command  :
    generic-config-menu  C
    generic-copy  c
    generic-credits  @
    generic-export  x X
    generic-goto  g G
    generic-goto-today  ^G
    generic-help  ?
    generic-import  i I
    generic-next-day  t ^L
    generic-next-month  m
    generic-next-week  w
    generic-next-year  y
    generic-other-cmd  o O
    generic-paste  p ^V
    generic-prev-day  T ^H
    generic-prev-month  M
    generic-prev-view  KEY_BTAB
    generic-prev-week  W ^K
    generic-prev-year  Y
    generic-quit  q Q
    generic-redraw  ^R
    generic-reload  R
    generic-save  s S ^S
    generic-scroll-down  ^N
    generic-scroll-up  ^P
    generic-select  SPC
    lower-priority  -
    move-down  j J DWN
    move-left  h H LFT
    move-right  l L RGT
    move-up  k K UP
    pipe-item  |
    raise-priority  +
    repeat  r
    start-of-week  0
    view-item  v V RET
    view-note  >'';
in {
  config = {
    programs.calcurse = { enable = true; };

    test.stubs.calcurse = { };

    nmt.script = ''
      assertFileExists home-files/.config/calcurse/conf
      assertFileContent home-files/.config/calcurse/conf ${conf}

      assertFileExists home-files/.config/calcurse/keys
      assertFileContent home-files/.config/calcurse/keys ${keys}
    '';
  };
}
