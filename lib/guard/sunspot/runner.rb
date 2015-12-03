module Guard
  class Sunspot
    class Runner
      MAX_WAIT_COUNT = 10

      attr_reader :options, :pid

      def initialize(options={})
        @options = options
        @root = options[:root] ? File.expand_path(options[:root]) : Dir.pwd
      end

      def start
        if options[:zeus] && !wait_for_zeus
          UI.info "[Guard::Sunspot::Error] Could not find zeus socket file."
          return false
        end
        run_sunspot_command! 'start'
        wait_for_pid
      end

      def stop
        return unless has_pid?
        run_sunspot_command! 'stop'
        wait_for_no_pid
      end

      def restart
        UI.info '[Guard::Sunspot] Restart called!'
        stop; start end

      def environment
        { 'RAILS_ENV' => options[:zeus] ? nil : options[:environment] }
      end

      def pid_file
        @pid_file ||= File.expand_path File.join( @root, 'solr', 'pids',
          options[:environment], "sunspot-solr-#{options[:environment]}.pid" )
      end

      def pid; has_pid? ? read_pid : nil end

      def sleep_time
        options[:timeout].to_f / MAX_WAIT_COUNT.to_f
      end

      def wait_for_zeus
        wait_for_loop { File.exist? zeus_sockfile }
      end

      private

      def build_rake_command
        cmd = []
        cmd << 'bundle exec' if options[:bundler]
        cmd << 'zeus' if options[:zeus]
        cmd << 'rake'
        cmd.join ' '
      end

      def build_solr_command(cmd)
        "#{build_rake_command} sunspot:solr:#{cmd}"
      end

      def run_sunspot_command!(cmd)
        if options[:zeus]
          without_bundler_env { system environment, build_solr_command(cmd) }
        else system environment, build_solr_command(cmd) end
      end

      def without_bundler_env
        if defined?(::Bundler)
          ::Bundler.with_clean_env { yield }
        else yield end
      end

      def has_pid?; File.file? pid_file end
      def read_pid; Integer(File.read(pid_file)); rescue ArgumentError; nil end

      def wait_for_loop
        count = 0
        while !yield && count < MAX_WAIT_COUNT
          wait_for_action
          count += 1
        end
        !(count == MAX_WAIT_COUNT)
      end
      def wait_for_action; sleep sleep_time end
      def wait_for_pid;    wait_for_loop {  has_pid? } end
      def wait_for_no_pid; wait_for_loop { !has_pid? } end

      def zeus_sockfile; File.join(@root, '.zeus.sock') end

    end
  end
end
