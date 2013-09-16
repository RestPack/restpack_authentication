class RestPackSession
  def initialize(app, options={})
    @app = app
  end

  def call(env)
    identifier = env['HTTP_HOST'].split(':')[0]
    identifier.slice!('auth.')

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

      env['rack.session.options'][:secret] = domain[:session_secret]
    else
      raise "[#{identifier}] is not a RestPack domain"
    end

    @app.call(env)
  end
end
