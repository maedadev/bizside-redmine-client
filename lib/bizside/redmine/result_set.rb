class Bizside::Redmine::ResultSet
  include Enumerable

  attr_reader :key
  attr_reader :status
  attr_reader :rows
  attr_reader :errors

  def initialize(key, status, json_string = nil)
    @key = key
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

  def ==(target)
    self.key == target.key &&
      self.status == target.status &&
      self.rows == target.rows &&
      self.errors == target.errors
  end

  def each
    rows.each do |hash|
      yield hash
    end
  end

  private

  def warn(status)
    case status
    when 200, 201, 204
      return
    when 401
      message = "[Redmine] HTTP#{status}: API authentication failed."
    else
      message = "[Redmine] HTTP#{status}: An error has occurred."
    end

    if Bizside::Redmine::Client.logger
      Bizside::Redmine::Client.logger.warn message
    else
      puts message
    end
  end
end
