require 'require_all'
require_rel '.'

module Sandbox

  class Application

    DEFAULT_SETTINGS = {
      :autorequire => {
        :root => "#{File.dirname __FILE__}/../..",
        :directories => ["resources"]
      },
      :resource_methods => ["get", "post", "put", "patch", "delete", "options"]
    }

    def initialize(settings = {})
      @settings = DEFAULT_SETTINGS.merge(settings)
      @settings[:resource_methods].map! { |m| m.to_sym }

      @settings[:autorequire][:directories].each do |dir|
        require_all "#{@settings[:autorequire][:root]}/#{dir}"
      end
    end

    def handle_request(request)
      begin
        request[:resource] = request[:resource].to_sym
        request[:method] = request[:method].downcase.to_sym

        # Get the requested resource class
        handler = Application::get_resource request[:resource]

        if @settings[:resource_methods].include?(request[:method])
            && handler.method_defined? request[:method]
        then
          return handler.public_send(method, request)
        else
          raise Sandbox::ResourceMethodException,
              "The %s resource does not respond to %s requests" % [
                request[:resource], request[:method]
              ]
        end
      rescue Exception => e
        raise ApplicationException, "An unexpected error occurred"
      end
    end

    private:
    def Application::get_resource(resource)
      if Module.const_defined(resource)
        it = Object.const_get(resource)

        if it.is_a(Class)
            && it.class != Sandbox::Resource
            && it.is_a? Sandbox::Resource
        then
          return it
        else
          raise Sandbox::ResourceException,
              "The requested resource (\"#{resource}\") does not exist."
        end
      end
    end

  end

end