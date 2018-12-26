{
  "background_opacity" = 1;
  "colors" = {
    "bright" = {
      "black" = "0x666666";
      "blue" = "0x7aa6da";
      "cyan" = "0x54ced6";
      "green" = "0x9ec400";
      "magenta" = "0xb77ee0";
      "red" = "0xff3334";
      "white" = "0xffffff";
      "yellow" = "0xe7c547";
    };
    "dim" = {
      "black" = "0x333333";
      "blue" = "0x6699cc";
      "cyan" = "0x66cccc";
      "green" = "0x99cc99";
      "magenta" = "0xcc99cc";
      "red" = "0xf2777a";
      "white" = "0xdddddd";
      "yellow" = "0xffcc66";
    };
    "normal" = {
      "black" = "0x000000";
      "blue" = "0x7aa6da";
      "cyan" = "0x70c0ba";
      "green" = "0xb9ca4a";
      "magenta" = "0xc397d8";
      "red" = "0xd54e53";
      "white" = "0xffffff";
      "yellow" = "0xe6c547";
    };
    "primary" = {
      "background" = "0x191919";
      "foreground" = "0xeaeaea";
    };
  };
  "cursor" = {
    "style" = "Block";
    "unfocused_hollow" = true;
  };
  "draw_bold_text_with_bright_colors" = true;
  "dynamic_title" = true;
  "enable" = true;
  "font" = {
    "bold" = {
      "family" = "monospace";
    };
    "glyph_offset" = {
      "x" = 0;
      "y" = 0;
    };
    "italic" = {
      "family" = "monospace";
    };
    "normal" = {
      "family" = "monospace";
    };
    "offset" = {
      "x" = 0;
      "y" = 0;
    };
    "size" = 6;
  };
  "key_bindings" = [
    {
      "action" = "Paste";
      "key" = "V";
      "mods" = "Control|Shift";
    }
    {
      "action" = "Copy";
      "key" = "C";
      "mods" = "Control|Shift";
    }
    {
      "action" = "Paste";
      "key" = "Paste";
    }
    {
      "action" = "Copy";
      "key" = "Copy";
    }
    {
      "action" = "Quit";
      "key" = "Q";
      "mods" = "Command";
    }
    {
      "action" = "Quit";
      "key" = "W";
      "mods" = "Command";
    }
    {
      "action" = "PasteSelection";
      "key" = "Insert";
      "mods" = "Shift";
    }
    {
      "action" = "ResetFontSize";
      "key" = "Key0";
      "mods" = "Control";
    }
    {
      "action" = "IncreaseFontSize";
      "key" = "Equals";
      "mods" = "Control";
    }
    {
      "action" = "DecreaseFontSize";
      "key" = "Subtract";
      "mods" = "Control";
    }
    {
      "action" = "ClearLogNotice";
      "key" = "L";
      "mods" = "Control";
    }
    {
      "chars" = "\\f";
      "key" = "L";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001bOH";
      "key" = "Home";
      "mode" = "AppCursor";
    }
    {
      "chars" = "\\u001b[H";
      "key" = "Home";
      "mode" = "~AppCursor";
    }
    {
      "chars" = "\\u001bOF";
      "key" = "End";
      "mode" = "AppCursor";
    }
    {
      "chars" = "\\u001b[F";
      "key" = "End";
      "mode" = "~AppCursor";
    }
    {
      "chars" = "\\u001b[5;2~";
      "key" = "PageUp";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[5;5~";
      "key" = "PageUp";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[5~";
      "key" = "PageUp";
    }
    {
      "chars" = "\\u001b[6;2~";
      "key" = "PageDown";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[6;5~";
      "key" = "PageDown";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[6~";
      "key" = "PageDown";
    }
    {
      "chars" = "\\u001b[Z";
      "key" = "Tab";
      "mods" = "Shift";
    }
    {
      "chars" = "";
      "key" = "Back";
    }
    {
      "chars" = "\\u001b";
      "key" = "Back";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[2~";
      "key" = "Insert";
    }
    {
      "chars" = "\\u001b[3~";
      "key" = "Delete";
    }
    {
      "chars" = "\\u001b[1;2D";
      "key" = "Left";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[1;5D";
      "key" = "Left";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[1;3D";
      "key" = "Left";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[D";
      "key" = "Left";
      "mode" = "~AppCursor";
    }
    {
      "chars" = "\\u001bOD";
      "key" = "Left";
      "mode" = "AppCursor";
    }
    {
      "chars" = "\\u001b[1;2C";
      "key" = "Right";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[1;5C";
      "key" = "Right";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[1;3C";
      "key" = "Right";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[C";
      "key" = "Right";
      "mode" = "~AppCursor";
    }
    {
      "chars" = "\\u001bOC";
      "key" = "Right";
      "mode" = "AppCursor";
    }
    {
      "chars" = "\\u001b[1;2A";
      "key" = "Up";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[1;5A";
      "key" = "Up";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[1;3A";
      "key" = "Up";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[A";
      "key" = "Up";
      "mode" = "~AppCursor";
    }
    {
      "chars" = "\\u001bOA";
      "key" = "Up";
      "mode" = "AppCursor";
    }
    {
      "chars" = "\\u001b[1;2B";
      "key" = "Down";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[1;5B";
      "key" = "Down";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[1;3B";
      "key" = "Down";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[B";
      "key" = "Down";
      "mode" = "~AppCursor";
    }
    {
      "chars" = "\\u001bOB";
      "key" = "Down";
      "mode" = "AppCursor";
    }
    {
      "chars" = "\\u001b";
      "key" = "F1";
    }
    {
      "chars" = "\\u001bOQ";
      "key" = "F2";
    }
    {
      "chars" = "\\u001bOR";
      "key" = "F3";
    }
    {
      "chars" = "\\u001bOS";
      "key" = "F4";
    }
    {
      "chars" = "\\u001b[15~";
      "key" = "F5";
    }
    {
      "chars" = "\\u001b[17~";
      "key" = "F6";
    }
    {
      "chars" = "\\u001b[18~";
      "key" = "F7";
    }
    {
      "chars" = "\\u001b[19~";
      "key" = "F8";
    }
    {
      "chars" = "\\u001b[20~";
      "key" = "F9";
    }
    {
      "chars" = "\\u001b[21~";
      "key" = "F10";
    }
    {
      "chars" = "\\u001b[23~";
      "key" = "F11";
    }
    {
      "chars" = "\\u001b[24~";
      "key" = "F12";
    }
    {
      "chars" = "\\u001b[1;2P";
      "key" = "F1";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[1;2Q";
      "key" = "F2";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[1;2R";
      "key" = "F3";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[1;2S";
      "key" = "F4";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[15;2~";
      "key" = "F5";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[17;2~";
      "key" = "F6";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[18;2~";
      "key" = "F7";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[19;2~";
      "key" = "F8";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[20;2~";
      "key" = "F9";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[21;2~";
      "key" = "F10";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[23;2~";
      "key" = "F11";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[24;2~";
      "key" = "F12";
      "mods" = "Shift";
    }
    {
      "chars" = "\\u001b[1;5P";
      "key" = "F1";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[1;5Q";
      "key" = "F2";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[1;5R";
      "key" = "F3";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[1;5S";
      "key" = "F4";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[15;5~";
      "key" = "F5";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[17;5~";
      "key" = "F6";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[18;5~";
      "key" = "F7";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[19;5~";
      "key" = "F8";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[20;5~";
      "key" = "F9";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[21;5~";
      "key" = "F10";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[23;5~";
      "key" = "F11";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[24;5~";
      "key" = "F12";
      "mods" = "Control";
    }
    {
      "chars" = "\\u001b[1;6P";
      "key" = "F1";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[1;6Q";
      "key" = "F2";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[1;6R";
      "key" = "F3";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[1;6S";
      "key" = "F4";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[15;6~";
      "key" = "F5";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[17;6~";
      "key" = "F6";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[18;6~";
      "key" = "F7";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[19;6~";
      "key" = "F8";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[20;6~";
      "key" = "F9";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[21;6~";
      "key" = "F10";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[23;6~";
      "key" = "F11";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[24;6~";
      "key" = "F12";
      "mods" = "Alt";
    }
    {
      "chars" = "\\u001b[1;3P";
      "key" = "F1";
      "mods" = "Super";
    }
    {
      "chars" = "\\u001b[1;3Q";
      "key" = "F2";
      "mods" = "Super";
    }
    {
      "chars" = "\\u001b[1;3R";
      "key" = "F3";
      "mods" = "Super";
    }
    {
      "chars" = "\\u001b[1;3S";
      "key" = "F4";
      "mods" = "Super";
    }
    {
      "chars" = "\\u001b[15;3~";
      "key" = "F5";
      "mods" = "Super";
    }
    {
      "chars" = "\\u001b[17;3~";
      "key" = "F6";
      "mods" = "Super";
    }
    {
      "chars" = "\\u001b[18;3~";
      "key" = "F7";
      "mods" = "Super";
    }
    {
      "chars" = "\\u001b[19;3~";
      "key" = "F8";
      "mods" = "Super";
    }
    {
      "chars" = "\\u001b[20;3~";
      "key" = "F9";
      "mods" = "Super";
    }
    {
      "chars" = "\\u001b[21;3~";
      "key" = "F10";
      "mods" = "Super";
    }
    {
      "chars" = "\\u001b[23;3~";
      "key" = "F11";
      "mods" = "Super";
    }
    {
      "chars" = "\\u001b[24;3~";
      "key" = "F12";
      "mods" = "Super";
    }
  ];
  "live_config_reload" = true;
  "mouse" = {
    "double_click" = {
      "threshold" = 300;
    };
    "hide_when_typing" = false;
    "triple_click" = {
      "threshold" = 300;
    };
    "url" = {
      "launcher" = "xdg-open";
    };
  };
  "mouse_bindings" = [
    {
      "action" = "PasteSelection";
      "mouse" = "Middle";
    }
  ];
  "persistent_logging" = false;
  "render_timer" = false;
  "scrolling" = {
    "auto_scroll" = false;
    "faux_multiplier" = 3;
    "history" = 10000;
    "multiplier" = 3;
  };
  "selection" = {
    "save_to_clipboard" = false;
    "semantic_escape_chars" = ";│`|=\"' ()[]{;}<>";
  };
  "tabspaces" = 8;
  "visual_bell" = {
    "animation" = "EaseOutExpo";
    "color" = "0xffffff";
    "duration" = 0;
  };
  "window" = {
    "decorations" = "full";
    "dimensions" = {
      "columns" = 120;
      "lines" = 36;
    };
    "dynamic_padding" = false;
    "padding" = {
      "x" = 2;
      "y" = 2;
    };
    "start_maximized" = false;
  };
}
