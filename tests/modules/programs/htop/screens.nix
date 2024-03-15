{ lib, ... }:

{
  programs.htop.enable = true;
  programs.htop.settings = { screen_tabs = true; };
  programs.htop.screens = {
    "Main" = {
      fields =
        "PID USER PRIORITY NICE M_VIRT M_RESIDENT M_SHARE STATE PERCENT_CPU PERCENT_MEM TIME Command";
      sort_key = "PERCENT_MEM";
      tree_sort_key = "PERCENT_MEM";
      tree_view = false;
      tree_view_always_by_pid = false;
      sort_direction = -1;
      tree_sort_direction = -1;
      all_branches_collapsed = false;
    };
    "I/O" = lib.hm.dag.entryAfter [ "Main" ] {
      fields =
        "PID STATE STARTTIME M_RESIDENT COMM EXE USER IO_PRIORITY IO_RATE IO_READ_RATE IO_WRITE_RATE";
      sort_key = "IO_RATE";
      tree_sort_key = "PID";
      tree_view = false;
      tree_view_always_by_pid = false;
      sort_direction = -1;
      tree_sort_direction = -1;
      all_branches_collapsed = false;
    };
  };

  test.stubs.htop = { };

  nmt.script = ''
    htoprc=home-files/.config/htop/htoprc
    assertFileExists $htoprc
    assertFileContent $htoprc ${./screens.txt}
  '';

}
