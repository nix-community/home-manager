require 'set'
require 'open3'

@dry_run = ENV['DRY_RUN']
@verbose = ENV['VERBOSE']

UnitsDir = 'home-files/.config/systemd/user'

# 1. Stop all services from the old generation that are not present in the new generation.
# 2. Ensure all services from the new generation that are wanted by active targets are running:
#    - Start services that are not already running.
#    - Restart services whose unit config files have changed between generations.
# 3. If any services were (re)started, wait 'start_timeout_ms' and report services
#    that failed to start. This helps debugging quickly failing services.
#
# Whenever service failures are detected, show the output of
# 'systemd --user status' for the affected services.
#
def setup_services(old_gen_path, new_gen_path, start_timeout_ms_string)
  start_timeout_ms = start_timeout_ms_string.to_i

  old_units_path = File.join(old_gen_path, UnitsDir) unless old_gen_path.empty?
  new_units_path = File.join(new_gen_path, UnitsDir)

  old_services = get_services(old_units_path)
  new_services = get_services(new_units_path)

  exit if old_services.empty? && new_services.empty?

  all_services = get_active_targets_units(new_units_path)
  maybe_changed = all_services & old_services
  changed_services = get_changed_services(old_units_path, new_units_path, maybe_changed)
  unchanged_oneshots = get_oneshot_services(maybe_changed - changed_services)

  # These services should be running when this script is finished
  services_to_run = all_services - unchanged_oneshots

  # Only stop active services, otherwise we might get a 'service not loaded' error
  # for inactive services that were removed in the current generation.
  to_stop = get_active_units(old_services - new_services)
  to_restart = changed_services
  to_start = get_inactive_units(services_to_run - to_restart)

  raise "daemon-reload failed" unless run_cmd('systemctl', '--user', 'daemon-reload')

  # Exclude units that shouldn't be (re)started or stopped
  no_manual_start, no_manual_stop, no_restart = get_restricted_units(to_stop + to_restart + to_start)
  notify_skipped_units(to_restart & no_restart)
  to_stop -= no_manual_stop
  to_restart -= no_manual_stop + no_manual_start + no_restart
  to_start -= no_manual_start

  if to_stop.empty? && to_start.empty? && to_restart.empty?
    print_service_msg("All services are already running", services_to_run)
  else
    puts "Setting up services" if @verbose
    systemctl_action('stop', to_stop)
    systemctl_action('start', to_start)
    systemctl_action('restart', to_restart)
    started_services = to_start + to_restart
    if start_timeout_ms > 0 && !started_services.empty? && !@dry_run
      failed = wait_and_get_failed_services(started_services, start_timeout_ms)
      if failed.empty?
        print_service_msg("All services are running", services_to_run)
      else
        puts
        puts "Error. These services failed to start:", failed
        show_failed_services_status(failed)
        exit 1
      end
    end
  end
end

def get_services(dir)
  services = get_service_files(dir) if dir && Dir.exists?(dir)
  Set.new(services)
end

def get_service_files(dir)
  Dir.chdir(dir) { Dir['*[^@].{service,socket,timer}'] }
end

def get_changed_services(dir_a, dir_b, services)
  services.select do |service|
    a = File.join(dir_a, service)
    b = File.join(dir_b, service)
    (File.size(a) != File.size(b)) || (File.read(a) != File.read(b))
  end
end

TargetDirRegexp = /^(.*\.target)\.wants$/

# @return all units wanted by active targets
def get_active_targets_units(units_dir)
  return Set.new unless Dir.exists?(units_dir)
  targets = Dir.entries(units_dir).map { |entry| entry[TargetDirRegexp, 1] }.compact
  active_targets = get_active_units(targets)
  active_units = active_targets.map do |target|
    get_service_files(File.join(units_dir, "#{target}.wants"))
  end.flatten
  Set.new(active_units)
end

# @return true on success
def run_cmd(*cmd)
  print_cmd cmd
  @dry_run || system(*cmd)
end

def systemctl_action(cmd, services)
  return if services.empty?

  verb = (cmd == 'stop') ? 'Stopping' : "#{cmd.capitalize}ing"
  puts "#{verb}: #{services.join(' ')}"

  cmd = ['systemctl', '--user', cmd, *services]
  if @dry_run
    puts cmd.join(' ')
    return
  end

  output, status = Open3.capture2e(*cmd)
  print output
  # Show status for failed services
  unless status.success?
    # Due to a bug in systemd, the '--user' argument is not always provided
    output.scan(/systemctl (?:--user )?(status .*?)['"]/).flatten.each do |status_cmd|
      puts
      run_cmd("systemctl --user #{status_cmd}")
    end
    exit 1
  end
end

def systemctl(*cmd)
  output, _ = Open3.capture2('systemctl', '--user', *cmd)
  output
end

def print_cmd(cmd)
  puts [*cmd].join(' ') if @verbose || @dry_run
end

def get_active_units(units)
  filter_units(units) { |state| state == 'active' }
end

def get_inactive_units(units)
  filter_units(units) { |state| state != 'active' }
end

def get_failed_units(units)
  filter_units(units) { |state| state == 'failed' }
end

def filter_units(units)
  return [] if units.empty?
  states = systemctl('is-active', *units).split
  units.select.with_index { |_, i| yield states[i] }
end

def get_oneshot_services(units)
  return [] if units.empty?
  types = systemctl('show', '-p', 'Type', *units).split
  units.select.with_index do |_, i|
    types[i] == 'Type=oneshot'
  end
end

def get_restricted_units(units)
  infos = systemctl('show', '-p', 'RefuseManualStart', '-p', 'RefuseManualStop', *units)
          .split("\n\n")
  no_manual_start = []
  no_manual_stop = []
  infos.zip(units).each do |info, unit|
    no_start, no_stop = info.split("\n")
    no_manual_start << unit if no_start.end_with?('yes')
    no_manual_stop << unit if no_stop.end_with?('yes')
  end
  # Get units that should not be restarted even if a change has been detected.
  no_restart_regexp = /^\s*X-RestartIfChanged\s*=\s*false\b/
  no_restart = units.select { |unit| systemctl('cat', unit) =~ no_restart_regexp }
  [no_manual_start, no_manual_stop, no_restart]
end

def wait_and_get_failed_services(services, start_timeout_ms)
  puts "Waiting #{start_timeout_ms} ms for services to fail"
  # Force the previous message to always be visible before sleeping
  STDOUT.flush
  sleep(start_timeout_ms / 1000.0)
  get_failed_units(services)
end

def show_failed_services_status(services)
  puts
  services.each do |service|
    run_cmd('systemctl', '--user', 'status', service)
    puts
  end
end

def print_service_msg(msg, services)
  return if services.empty?
  if @verbose
    puts "#{msg}:", services.to_a
  else
    puts msg
  end
end

def notify_skipped_units(no_restart)
  puts "Not restarting: #{no_restart.join(' ')}" unless no_restart.empty?
end

setup_services(*ARGV)
