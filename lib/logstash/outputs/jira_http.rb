# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"


class LogStash::Outputs::Jira_Http < LogStash::Outputs::Base
  config_name "jira_http"

  # The hostname to send logs to. This should target your JIRA server 
  # and has to have the REST interface enabled
  config :host, :validate => :string

  config :username, :validate => :string, :required => true
  config :password, :validate => :string, :required => true

  # JIRA Project number
  config :projectid, :validate => :string, :required => true

  # JIRA Issuetype number
  config :issuetypeid, :validate => :string, :required => true

  # JIRA Summary
  #
  # Truncated and appended with '...' if longer than 255 characters.
  config :summary, :validate => :string, :required => true

  # JIRA Priority
  config :priority, :validate => :string

  # JIRA Reporter
  config :reporter, :validate => :string

  # JIRA Reporter
  config :assignee, :validate => :string


  public
  def register    
    require "net/http"
    require "uri"
    require 'json'
  end

  public
  def receive(event)
    
    return if event == LogStash::SHUTDOWN

    summary = event.sprintf(@summary)
    summary = "#{summary[0,252]}..." if summary.length > 255

    uri = URI.parse("https://ring.digiturk.com.tr/jira/rest/api/2/issue")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri.request_uri)
    request.basic_auth @username, @password
    request.add_field('Content-Type', 'application/json')
    json_fields = {"fields"=> {
       "project"=> 
       {
          "id"=>  @projectid
       },
       "summary"=>  summary,
       "description"=>  event.sprintf(event.to_hash.to_yaml),
       "issuetype"=>  {
          "id"=>  @issuetypeid
       }
    }}
    json_fields["fields"].push({"reporter" => @reporter}) if @reporter
    json_fields["fields"].push({"assignee" => @assignee}) if @assignee
    json_fields["fields"].push({"priority" => @priority}) if @priority

    request.body = JSON.generate(json_fields)
    response = http.request(request)
  end # def receive
end # class LogStash::Outputs::Jira_Http
