module ApiVersions
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      accept_string = env['HTTP_ACCEPT'] || ""
      accepts = accept_string.split(',')

      if env["PATH_INFO"].include?("/api") && accept_string.exclude?('application/vnd.')
        accepts.push("application/vnd.#{ApiVersions::VersionCheck.vendor_string}+json")
      end

      offset = 0
      accepts.dup.each_with_index do |accept, i|
        accept.strip!
        match = /\Aapplication\/vnd\.#{ApiVersions::VersionCheck.vendor_string}\s*\+\s*(?<format>\w+)\s*/.match(accept)
        if match
          accepts.insert i + offset, "application/#{match[:format]}"
          offset += 1
        end
      end

      if accepts.present?
        http_accept = accepts.join(',')

        current_version = http_accept[/version=(\d)/, 1]
        current_version = current_version.nil? ? VersionCheck.default_version : current_version.to_i

        version = if env['rack.request.query_hash'].try(:key?, 'api_version')
          env['rack.request.query_hash']['api_version']
        elsif VersionCheck.max_version < current_version
          VersionCheck.max_version
        else
          current_version
        end

        http_accept.gsub!(/version=\d/, "version=#{version}")
        env['HTTP_ACCEPT'] = http_accept
      end
      @app.call(env)
    end
  end
end
