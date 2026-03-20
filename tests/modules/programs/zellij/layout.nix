{ pkgs, ... }:
{
  programs.zellij = {
    enable = true;
    layouts = {
      dev = {
        layout = {
          _children = [
            {
              default_tab_template = {
                _children = [
                  {
                    pane = {
                      size = 1;
                      borderless = true;
                      plugin = {
                        location = "zellij:tab-bar";
                      };
                    };
                  }
                  { "children" = { }; }
                  {
                    pane = {
                      size = 2;
                      borderless = true;
                      plugin = {
                        location = "zellij:status-bar";
                      };
                    };
                  }
                ];
              };
            }
            {
              tab = {
                _props = {
                  name = "Project";
                  focus = true;
                };
                _children = [
                  {
                    pane = {
                      command = "nvim";
                    };
                  }
                ];
              };
            }
            {
              tab = {
                _props = {
                  name = "Git";
                };
                _children = [
                  {
                    pane = {
                      command = "lazygit";
                    };
                  }
                ];
              };
            }
            {
              tab = {
                _props = {
                  name = "Files";
                };
                _children = [
                  {
                    pane = {
                      command = "yazi";
                    };
                  }
                ];
              };
            }
            {
              tab = {
                _props = {
                  name = "Shell";
                };
                _children = [
                  {
                    pane = {
                      command = "zsh";
                    };
                  }
                ];
              };
            }
          ];
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/zellij/layouts/dev.kdl
    assertFileContent home-files/.config/zellij/layouts/dev.kdl \
      ${pkgs.writeText "layout-dev-expected" ''
        layout {
        	default_tab_template {
        		pane {
        			borderless true
        			plugin {
        				location "zellij:tab-bar"
        			}
        			size 1
        		}
        		children
        		pane {
        			borderless true
        			plugin {
        				location "zellij:status-bar"
        			}
        			size 2
        		}
        	}
        	tab focus=true name="Project" {
        		pane {
        			command "nvim"
        		}
        	}
        	tab name="Git" {
        		pane {
        			command "lazygit"
        		}
        	}
        	tab name="Files" {
        		pane {
        			command "yazi"
        		}
        	}
        	tab name="Shell" {
        		pane {
        			command "zsh"
        		}
        	}
        }
      ''}
  '';
}
