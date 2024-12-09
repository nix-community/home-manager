let config = {
  filesize_metric: false
  table_mode: rounded
  use_ls_colors: true
}

$env.config.display_errors.exit_code = false
$env.config.hooks.pre_execution = [
    ({|| "pre_execution hook"})
]
$env.config.show_banner = false


alias ll = ls -a
alias lsname = (ls | get name)
