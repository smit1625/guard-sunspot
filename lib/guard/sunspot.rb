require 'guard/compat/plugin'
require 'guard/sunspot/version'

module Guard
  class Sunspot < Plugin
    require 'guard/sunspot/runner'
    attr_reader :options, :runner

    DEFAULT_OPTIONS = {
      environment: 'development',
      bundler: false,
      zeus: false,
      start_on_start: true,
      timeout: 30
    }

    def initialize(options={})
      super
      @options = DEFAULT_OPTIONS.merge(options)
      @runner = Runner.new(@options)
      # @environment = @options.fetch(:environment, 'development')
      # @bundler = @options.fetch(:bundler, false)
    end

    def start
      UI.info "[Guard::Sunspot] will start Solr in #{options[:environment]}."
      reload('start') if options[:start_on_start]
      # system "#{rake} sunspot:solr:start RAILS_ENV=#{@environment}"
      # UI.info "Sunspot started"
    end

    def stop
      UI.info "[Guard::Sunspot] will stop Solr in #{options[:environment]}."
      runner.stop
      # system "#{rake} sunspot:solr:stop RAILS_ENV=#{@environment}"
      # UI.info "Sunspot stopped"
    end

    def reload(action='restart')
      title = "#{action.capitalize}ing Solr..."
      UI.info title
      if runner.restart
        UI.info "Solr #{action}ed, pid #{runner.pid}"
      else
        UI.info "Solr NOT #{action}ed, check your log files."
      end
      # stop
      # start
    end

    def run_on_changes(path)
      reload
    end
    # for guard 1.0.x and earlier
    alias :run_on_change :run_on_changes

    # private
    #
    # def rake
    #   rake = []
    #   rake << "bundle exec" if @bundler
    #   rake << "zeus" if @zeus
    #   rake << "rake"
    #   rake.join ' '
    # end
  end
end
