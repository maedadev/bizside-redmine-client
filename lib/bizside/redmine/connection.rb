require 'faraday'

class Bizside::Redmine::Connection

  attr_reader :host, :api_key, :verify_ssl

  def initialize(overrides = {})
    @host = overrides[:host] || Bizside.config.redmine.host
    @api_key = overrides[:api_key] || Bizside.config.redmine.api_key
    @verify_ssl = overrides.has_key?(:verify_ssl) ? overrides[:verify_ssl] : Bizside.config.redmine.verify_ssl
  end

  def get(path, params = {})
    begin
      connection.get(path, params) do |request|
        request.headers['X-Redmine-API-Key'] = api_key
      end
    rescue Faraday::ConnectionFailed => e
      raise 'Redmineサーバに接続できませんでした。'
    end
  end

  def post(path, params = {})
    begin
      connection.post(path) do |request|
        request.headers['X-Redmine-API-Key'] = api_key
        request.headers['Content-Type'] = 'application/json'
        request.body = params.to_json
      end
    rescue Faraday::ConnectionFailed => e
      raise 'Redmineサーバに接続できませんでした。'
    end
  end

  def put(path, params = {})
    begin
      connection.put(path) do |request|
        request.headers['X-Redmine-API-Key'] = api_key
        request.headers['Content-Type'] = 'application/json'
        request.body = params.to_json
      end
    rescue Faraday::ConnectionFailed => e
      raise 'Redmineサーバに接続できませんでした。'
    end
  end

  def post_or_put(path, content)
    begin
      connection.put(path) do |request|
        request.headers['X-Redmine-API-Key'] = api_key
        request.headers['Content-Type'] = 'application/xml'
        request.body = content
      end
    rescue Faraday::ConnectionFailed => e
      raise 'Redmineサーバに接続できませんでした。'
    end
  end

  def post_with_multipart(path, params = {})
    begin
      connection(:multipart => true).post(path) do |request|
        request.headers['X-Redmine-API-Key'] = api_key
        request.headers['Content-Type'] = 'application/octet-stream'
        request.body = File.binread(params[:file].path)
      end
    rescue Faraday::ConnectionFailed => e
      raise 'Redmineサーバに接続できませんでした。'
    end
  end

  private

  def connection(options = {})
    Faraday.new(:url => 'https://' + host, :ssl => ssl_options) do |faraday|
      if options[:multipart]
        faraday.request :multipart
      else
        faraday.request :url_encoded
      end
      faraday.adapter Faraday.default_adapter
    end
  end

  def ssl_options
    ssl_dir = File.expand_path(File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'ssl'))

    ssl_options = {
      :ca_path => ssl_dir,
      :ca_file => File.join(ssl_dir, 'cert.pem'),
      :verify => verify_ssl,
    }
  end

end
