class ResultEvent
  def initialize
    @ecs=HttpEcs.instance
  end

  def process(evbody)
    path= evbody[0]['ressource']
    resultr= @ecs.connection[path].delete
    result= JSON::parse(resultr)
    Rails.logger.info "***** ResultEvent#process: #{path} = #{result}"

    # remove exercise referenced through solution embedded in result
    path= URI(result["Result"]["Solution"]["exercise"]).path[1..-1]
    @ecs.connection[path].delete do |response, request, result, &block|
      case response.code
      when 404
        Rails.logger.info "***** ResultEvent#process: garbage collect:  resource = #{path} not found (404)"
      else
        response.return!(request, result, &block)
      end
    end

    points= -1
    result["Result"]["elements"].each do |e|
      case e["MIMEtype"]
      when "text/plain"
        if (val=e["value"]).strip.start_with?("*** Score:")
          points= val.strip.split(":")[1].to_i
          break
        end
      end
    end  
    p= {}

    p[:points]= points.to_i
    p[:identifier]= result["Result"]["Solution"]["evaluationService"]["jobID"]
    receiver= result["Result"]["Solution"]["evaluationService"]["jobSender"]
    body= "{\"Points\": #{p.to_json} }"
    Rails.logger.info "***** ResultEvent#process points body = #{body}, points receiver mid = #{receiver}"
    response= @ecs.connection[APP_CONFIG["resources"]["points"]["name"]].post body, {"X-EcsReceiverMemberships" => receiver} do |response, request, result|
      Rails.logger.info "***** ResultEvent#process post response headers: #{response.headers}"
    end
  end
end
