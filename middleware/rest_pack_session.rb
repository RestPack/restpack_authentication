#NOTE: this will soon be replaced with RestPack::Web

class RestPackSessionOLD
  def initialize(app, options={})
    @app = app
  end

  def call(env)
    identifier = Rack::Request.new(env).host
    response = RestPack::Core::Service::Commands::Domain::ByIdentifier.run({
      identifier: identifier,
      includes: 'applications'
    })

    if response.status == :ok
      domain = response.result[:domains][0]
      application = response.result[:applications][0]
      env[:restpack] = {
        domain: domain,
        domain_id: domain[:id],
        application: application,
        application_id: application[:id]
      }

      env['rack.session.options'] ||= {}
      env['rack.session.options'][:key] = 'restpack.session'
      env['rack.session.options'][:secret] = domain[:session_secret]
    else
      raise "[#{identifier}] is not a RestPack domain"
    end

    @app.call(env)
  end
end
