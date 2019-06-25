class Bizside::Redmine::ResultSet
  include Enumerable

  attr_reader :status
  attr_reader :rows
  attr_reader :errors

  def initialize(key, status, json_string = nil)
    @status = status

    if json_string.present?
      json = ActiveSupport::JSON.decode(json_string.force_encoding('UTF-8'))
      @rows = key.present? ? json[key.to_s] : json
      @errors = json['errors']
    else
      warn(status)
    end

    @rows ||= []
  end

  def errors
    @errors
  end

  def each
    rows.each do |hash|
      yield hash
    end
  end

  private

  def warn(status)
    case status
    when 200
      return
    when 401
      message = "[Redmine] HTTP#{status}: API認証に失敗しました。"
    else
      message = "[Redmine] HTTP#{status}: エラー発生しました。"
    end

    if defined?(Rails) and Rails.logger
      Rails.logger.warn message
    else
      puts message
    end
  end
end
