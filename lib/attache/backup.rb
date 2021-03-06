class Attache::Backup < Attache::Base
  def initialize(app)
    @app = app
  end

  def _call(env, config)
    case env['PATH_INFO']
    when '/backup'
      request  = Rack::Request.new(env)
      params   = request.params
      return config.unauthorized unless config.authorized?(params)

      if config.storage && config.bucket
        sync_method = (ENV['BACKUP_ASYNC'] ? :async : :send)
        threads = []
        params['paths'].to_s.split("\n").each do |relpath|
          threads << Thread.new do
            Attache.logger.info "BACKUP remote #{relpath}"
            config.send(sync_method, :backup_file, relpath: relpath)
          end
        end
        threads.each(&:join)
      end
      [200, config.headers_with_cors, []]
    else
      @app.call(env)
    end
  end
end
