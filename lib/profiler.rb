# Usage (anywhere in the code):
# Profiler.start_profiling if defined?(Profiler)
# Profiler.stop_profiling if defined?(Profiler)
# Profiler.stop_profiling_and_open if defined?(Profiler)
#
# Modes:
# RubyProf::WALL_TIME
# RubyProf::CPU_TIME
# RubyProf::PROCESS_TIME
# RubyProf::ALLOCATIONS
# RubyProf::MEMORY
# RubyProf::GC_TIME
# RubyProf::GC_RUNS

# Open the report like so:
# qcachegrind tmp/ruby_prof_report/callgrind.out.12345

module Profiler
  def self.start_profiling(mode = RubyProf::WALL_TIME)
    @profile = RubyProf::Profile.new(measure_mode: mode)
    @profile.start
  end

  def self.stop_profiling
    result = @profile.stop
    save_profile_results(result)
  end

  def self.stop_profiling_and_open
    result = @profile.stop
    save_profile_results(result)
    open_latest_profile_report
  end

  def self.save_profile_results(result)
    output_path = Rails.root.join('tmp', 'ruby_prof_report')
    clear_directory(output_path)
    Dir.mkdir(output_path) unless Dir.exist?(output_path)
    printer = RubyProf::CallTreePrinter.new(result)
    printer.print(path: output_path, profile: 'callgrind')
  end

  def self.clear_directory(path)
    FileUtils.rm_rf(Dir.glob("#{path}/*"))
  end

  def self.open_latest_profile_report
    output_path = Rails.root.join('tmp', 'ruby_prof_report')
    latest_report = Dir.glob("#{output_path}/callgrind.out.*").min_by { |f| File.mtime(f) }
    if latest_report
      pid = Process.spawn("qcachegrind #{latest_report}")
      Process.detach(pid)
    else
      puts "No profile report found."
    end
  end
end
