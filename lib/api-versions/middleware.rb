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

      env['HTTP_ACCEPT'] = accepts.join(',') if accepts.present?
      @app.call(env)
    end
  end
end
