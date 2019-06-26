require "bizside/redmine/client/version"
require "active_support/all"
require "bizside/redmine/connection"
require "bizside/redmine/result_set"

require "bizside/redmine/text_to_textile"
require "bizside/redmine/html_to_textile"

class Bizside::Redmine::Client
  cattr_accessor :logger, :config, instance_accessor: false
  attr_reader :prefix

  def initialize(overrides = {})
    overrides = overrides.symbolize_keys
    if logger = overrides.delete(:logger)
      @@logger = logger
    end

    @prefix = overrides[:prefix] || (Bizside::Redmine::Client.config ? Bizside::Redmine::Client.config[:prefix] : '/')
    @connection = Bizside::Redmine::Connection.new(overrides)
  end

  def projects(params = {})
    params = params.symbolize_keys

    api_params = {
      include: 'trackers,issue_categories',
      page: params[:page] || 1,
      per: params[:per] || 100
    }

    response = connection.get("#{prefix}/projects.json", api_params)
    decode(:projects, response)
  end

  def trackers
    response = connection.get("#{prefix}/trackers.json")
    decode(:trackers, response)
  end

  def wiki_pages(project_identifier)
    response = connection.get("#{prefix}/projects/#{project_identifier}/wiki/index.json")
    decode(:wiki_pages, response)
  end

  def create_issue(params)
    params = params.symbolize_keys
    issue_params = params[:issue].symbolize_keys

    api_params = {
      :issue => {
        :project_id => issue_params[:project_id],
        :subject => issue_params[:subject],
      }
    }
    api_params[:issue][:tracker_id] = issue_params[:tracker_id] if issue_params[:tracker_id]
    api_params[:issue][:status_id] = issue_params[:status_id] if issue_params[:status_id]
    api_params[:issue][:priority_id] = issue_params[:priority_id] if issue_params[:priority_id]
    api_params[:issue][:description] = issue_params[:description] if issue_params[:description]
    api_params[:issue][:category_id] = issue_params[:category_id] if issue_params[:category_id]
    api_params[:issue][:fixed_version_id] = issue_params[:fixed_version_id] if issue_params[:fixed_version_id]
    api_params[:issue][:assigned_to_id] = issue_params[:assigned_to_id] if issue_params[:assigned_to_id]
    api_params[:issue][:parent_issue_id] = issue_params[:parent_issue_id] if issue_params[:parent_issue_id]
    api_params[:issue][:custom_fields] = issue_params[:custom_fields] if issue_params[:custom_fields]
    api_params[:issue][:watcher_user_ids] = issue_params[:watcher_user_ids] if issue_params[:watcher_user_ids]
    api_params[:issue][:uploads] = issue_params[:uploads] if issue_params[:uploads]

    response = connection.post("#{prefix}/issues.json", api_params)
    decode(:issue, response)
  end

  def update_issue(id, params)
    params = params.symbolize_keys
    issue_params = params[:issue].symbolize_keys

    api_params = {
      :issue => {
        :notes => issue_params[:notes],
      }
    }
    api_params[:issue][:uploads] = issue_params[:uploads] if issue_params[:uploads]

    response = connection.put("#{prefix}/issues/#{id}.json", api_params)
    decode(:issue, response)
  end

  def create_wiki_page(params)
    path = "#{prefix}/projects/#{params[:project_identifier]}/wiki/#{params[:page_name]}.xml"
    content = "<wiki_page><text>#{params[:content]}</text></wiki_page>"
    response = connection.post_or_put(path, content)
    decode(:wiki_page, response)
  end

  def create_analyzed_wiki_pages(params)
    content = "<wiki_page><text>#{params[:content]}</text></wiki_page>"
    response = connection.post_or_put("#{prefix}/projects/#{params[:project_identifier]}/wiki/#{params[:page_name]}.xml", content)
    decode(:wiki_page, response)
  end

  def create_errors_wiki_pages(params)
    content = "<wiki_page><text>h3. #{params[:page_name]} <notextile></notextile>&lt;pre&gt;#{params[:content]}&lt;/pre&gt;</text></wiki_page>"
    response = connection.post_or_put("#{prefix}/projects/#{params[:project_identifier]}/wiki/#{params[:page_name]}.xml", content)
    decode(:wiki_page, response)
  end

  def create_aggregated_wiki_page(params)
    params.each do |project_identifier, hash|
      hash.each do |env, page_names|
        year_months = page_names.sort.reverse.join(" ").gsub(" ", "\n")
        content = "<wiki_page><text>#{year_months}</text></wiki_page>"
        connection.post_or_put("#{prefix}/projects/#{project_identifier}/wiki/#{env}-result-analyzer.xml", content)
      end
    end
  end

  def create_year_month_wiki_pages(params)
    params.each do |project_identifier, hash|
      hash.each do |year_month, page_names|
        page_names = page_names.sort.reverse.join(" ").gsub(" ", "\n")
        content = "<wiki_page><text>#{page_names}</text></wiki_page>"
        connection.post_or_put("#{prefix}/projects/#{project_identifier}/wiki/#{year_month}.xml", content)
      end
    end
  end

  def upload_file(params)
    options = params.symbolize_keys
    api_params = {
      :file => options[:file]
    }
    response = connection.post_with_multipart("#{prefix}/uploads.json", api_params)
    decode(:upload, response)
  end

  def dms_folders(params)
    params = params.symbolize_keys

    api_params = {}
    api_params[:folder_id] = params[:folder_id] if params[:folder_id].present?

    response = connection.get("#{prefix}/projects/#{params[:project_id]}/dmsf.json", api_params)
    decode("", response)
  end

  def dms_create_folder(params)
    params = params.symbolize_keys

    api_params = {
      dmsf_folder: {
        title: params[:title],
        description: params[:description].present? ? params[:description] : '-'
      }
    }
    api_params[:dmsf_folder_id] = params[:parent_folder_id] if params[:parent_folder_id].present?

    response = connection.post("#{prefix}/projects/#{params[:project_id]}/dmsf/create.json", api_params)
    decode("", response)
  end

  def dms_upload_file(params)
    params = params.symbolize_keys
    api_params = {
      :file => params[:file]
    }
    filename = File.basename(params[:file])
    response = connection.post_with_multipart("#{prefix}/projects/#{params[:project_id]}/dmsf/upload.json?filename=#{filename}", api_params)
    decode('', response)
  end

  def dms_commit_file(params)
    params = params.symbolize_keys
    api_params = {
      attachments: {
        folder_id: params[:folder_id],
        uploaded_file: {
          name: params[:name],
          title: params[:title],
          description: params[:description].present? ? params[:description] : '-',
          comment: params[:comment].present? ? params[:comment] : '-',
          token: params[:token]
        }
      }
    }
    response = connection.post("#{prefix}/projects/#{params[:project_id]}/dmsf/commit.json", api_params)
    decode("", response)
  end

  private

  def connection
    @connection
  end

  def decode(key, response)
    Bizside::Redmine::ResultSet.new(key, response.status, response.body)
  end
end
