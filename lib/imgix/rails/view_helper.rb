module Imgix
  module Rails
    class ConfigurationError < StandardError; end

    module ViewHelper
      def ix_image_tag(source, options={})
        validate_configuration!

        normal_opts = options.slice!(*available_parameters)

        image_tag(client.path(source).to_url(options), normal_opts)
      end

    private

      def validate_configuration!
        imgix = config.imgix
        unless imgix.try(:[], :source)
          raise ConfigurationError.new("imgix source is not configured. Please set config.imgix[:source].")
        end

        unless imgix[:source].is_a?(Array) || imgix[:source].is_a?(String)
          raise ConfigurationError.new("imgix source must be a String or an Array.")
        end
      end

      def client
        return @client if @client

        opts = {
          host: config.imgix[:source],
          library_param: "rails",
          library_version: Imgix::Rails::VERSION
        }

        if config.imgix[:secure_url_token].present?
          opts[:token] = config.imgix[:secure_url_token]
        end

        @client = Imgix::Client.new(opts)
      end

      def config
        ::Rails.application.config
      end

      def available_parameters
        @available_parameters ||= parameters.keys
      end

      def parameters
        path = File.expand_path("../../../../vendor/parameters.json", __FILE__)
        @parameters ||= JSON.parse(File.read(path), symbolize_names: true)[:parameters]
      end
    end
  end
end