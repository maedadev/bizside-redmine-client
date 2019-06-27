require "test_helper"

class Bizside::Redmine::ClientTest < Minitest::Test
  def setup
    @host = "test.redmine.com"
    @prefix = "/redmine"
    @client = Bizside::Redmine::Client.new(host: @host, prefix: @prefix, api_key: "abcdefg")
  end

  def test_that_it_has_a_version_number
    refute_nil ::Bizside::Redmine::Client::VERSION
  end

  def test_projects
    response_body = <<-RES_JSON
      {
        "projects": [
          {"id": 1, "name": "TestPJ", "identifier": "test", "description": "Test Project"}
        ]
      }
    RES_JSON

    stub_request(:get, "#{request_host}/projects.json").
      with(query: {
        include: 'trackers,issue_categories',
        page: 1,
        per: 100
      }).
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new(:projects, 200, response_body)
    assert_equal @client.projects, result
  end

  def test_trackers
    response_body = <<-RES_JSON
      {
        "trackers": [
          {"id":1, "name": "Bug", "default_status": {"id": 1, "name": "New"}},
          {"id":2, "name": "Feature", "default_status": {"id": 1, "name": "New"}}
        ]
      }
    RES_JSON

    stub_request(:get, "#{request_host}/trackers.json").
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new(:trackers, 200, response_body)
    assert_equal @client.trackers, result
  end

  def test_wiki_pages
    project_identifier = 1
    response_body = <<-RES_JSON
      {
        "wiki_pages": [
          {"title": "Wiki Page 1"},
          {"title": "Wiki Page 2"}
        ]
      }
    RES_JSON

    stub_request(:get, "#{request_host}/projects/#{project_identifier}/wiki/index.json").
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new(:wiki_pages, 200, response_body)
    assert_equal @client.wiki_pages(project_identifier), result
  end

  def test_create_issue
    project_id = 1
    subject = "Test Issue"
    tracker_id = 10
    params = {
      issue: {
        project_id: project_id,
        subject: subject,
        tracker_id: tracker_id
      }
    }
    response_body = dummy_response

    stub_request(:post, "#{request_host}/issues.json").
      with(body: {
        issue: {
          project_id: project_id,
          subject: subject,
          tracker_id: tracker_id
        }
      }).
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new(:issue, 200, response_body)
    assert_equal @client.create_issue(params), result
  end

  def test_update_issue
    id = 100
    notes = "Test Note"
    params = {
      issue: {
        notes: notes
      }
    }
    response_body = dummy_response

    stub_request(:put, "#{request_host}/issues/#{id}.json").
      with(body: {
        issue: {
          notes: notes
        }
      }).
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new(:issue, 200, response_body)
    assert_equal @client.update_issue(id, params), result
  end

  def test_create_wiki_page
    project_identifier = 1
    page_name = "wiki_page_1"
    content_body = "Content Boby"
    params = {
      project_identifier: project_identifier,
      page_name: page_name,
      content: content_body
    }
    content = get_content(content_body)
    response_body = dummy_response

    stub_request(:put, "#{request_host}/projects/#{project_identifier}/wiki/#{page_name}.xml").
      with(body: content).
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new(:wiki_page, 200, response_body)
    assert_equal @client.create_wiki_page(params), result
  end

  def test_create_analyzed_wiki_pages
    project_identifier = 1
    page_name = "wiki_page_1"
    content_body = "Content Boby"
    params = {
      project_identifier: project_identifier,
      page_name: page_name,
      content: content_body
    }
    content = get_content(content_body)
    response_body = dummy_response

    stub_request(:put, "#{request_host}/projects/#{project_identifier}/wiki/#{page_name}.xml").
      with(body: content).
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new(:wiki_page, 200, response_body)
    assert_equal @client.create_analyzed_wiki_pages(params), result
  end

  def test_upload_file
    file = File.new('test/fixtures/file.txt')
    params = { file: file }
    response_body = dummy_response

    stub_request(:post, "#{request_host}/uploads.json").
      with(:headers => { "Content-Type" => "application/octet-stream" }).
      with(body: file.read).
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new(:upload, 200, response_body)
    assert_equal @client.upload_file(params), result
  end

  def test_dms_folders
    project_id = 1
    folder_id = 20
    params = {
      project_id: project_id,
      folder_id: folder_id
    }
    response_body = dummy_response

    stub_request(:get, "#{request_host}/projects/#{project_id}/dmsf.json").
      with(query: {folder_id: folder_id}).
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new("", 200, response_body)
    assert_equal @client.dms_folders(params), result
  end

  def test_dms_create_folder
    project_id = 1
    title = "DMS Folder Title"
    description = "DMS Folder Description"
    params = {
      project_id: project_id,
      title: title,
      description: description
    }
    response_body = dummy_response

    stub_request(:post, "#{request_host}/projects/#{project_id}/dmsf/create.json").
      with(body: {
        dmsf_folder: {
          title: title,
          description: description
        }
      }).
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new("", 200, response_body)
    assert_equal @client.dms_create_folder(params), result
  end

  def test_dms_upload_file
    project_id = 1
    file = File.new('test/fixtures/file.txt')
    filename = "file.txt"
    params = {
      project_id: project_id,
      file: file
    }
    response_body = dummy_response

    stub_request(:post, "#{request_host}/projects/#{project_id}/dmsf/upload.json?filename=#{filename}").
      with(:headers => { "Content-Type" => "application/octet-stream" }).
      with(body: file.read).
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new("", 200, response_body)
    assert_equal @client.dms_upload_file(params), result
  end

  def test_dms_commit_file
    project_id = 1
    folder_id = 20
    name = "upload_file_1"
    title = "Upload File Title"
    description = "Upload File Description"
    comment = "Comment1"
    token = "token1"
    params = {
      project_id: project_id,
      folder_id: folder_id,
      name: name,
      title: title,
      description: description,
      comment: comment,
      token: token
    }
    response_body = dummy_response

    stub_request(:post, "#{request_host}/projects/#{project_id}/dmsf/commit.json").
      with(body: {
        attachments: {
          folder_id: folder_id,
          uploaded_file: {
            name: name,
            title: title,
            description: description,
            comment: comment,
            token: token
          }
        }
      }).
      to_return(status: 200, body: response_body)

    result = Bizside::Redmine::ResultSet.new("", 200, response_body)
    assert_equal @client.dms_commit_file(params), result
  end

  private

  def get_content(body)
    "<wiki_page><text>#{body}</text></wiki_page>"
  end

  def dummy_response
    '{ "result": "OK" }'
  end

  def request_host
    "https://#{@host}#{@prefix}"
  end
end
