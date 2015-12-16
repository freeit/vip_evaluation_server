class HttpEcs

  require 'rest_client'
  include Singleton

  attr_reader :connection

  CONTENT_TYPE_URI_LIST = { 'Content-Type' => 'text/uri-list' }
  CONTENT_TYPE_JSON = { 'Content-Type' => 'application/json' }

  def initialize
    @connection= RestClient::Resource.new(
      APP_CONFIG['ecs']['url'],
      :ssl_ca_file      =>  APP_CONFIG['ecs']['ssl_ca_file'],
      :verify_ssl       =>  APP_CONFIG['ecs']['verify_ssl'],
      :headers          =>  {"Content-Type" => :json, "Accept" => :json, "Authorization" => "Basic "+Base64.urlsafe_encode64(APP_CONFIG['ecs']['login']+":"+APP_CONFIG['ecs']['password'])}
    )
    if APP_CONFIG['proxy'].blank?
      RestClient.proxy = ""
    else
      RestClient.proxy = APP_CONFIG['proxy']
    end
  end

end
