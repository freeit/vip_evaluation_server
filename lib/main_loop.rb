##
# Loops for getting new events from *sys/events*.
# This class is a singelton, because it should be
# the only looping thing.
class MainLoop
  include Singleton

#  class << self
#    attr_accessor :exception_tries
#  end
#
#  attr_accessor :ecs

  @exception_tries= 0

  def initialize
    Rails.logger.info "*** VIP merge and compute service started ***"
    @ecs= HttpEcs.instance
  end

  def start
    loop do
      evbody=JSON::parse((ev=read_event).body)
      if evbody.blank?
        #Rails.logger.info "MainLoop#start: "
        sleep(1)
      else
        if evbody[0]["ressource"].start_with?(APP_CONFIG["eventtypes"]["job"]["name"])
          Rails.logger.info "***** received \"#{APP_CONFIG["eventtypes"]["job"]["name"]}\" event type"
          JobEvent.new.process(evbody)
        elsif evbody[0]["ressource"].start_with?(APP_CONFIG["eventtypes"]["result"]["name"])
          Rails.logger.info "***** received \"#{APP_CONFIG["eventtypes"]["result"]["name"]}\" event type"
          ResultEvent.new.process(evbody)
        else
          Rails.logger.info "***** Unknown event: #{evbody[0]}"
        end
      end
    end
  rescue => e
    Rails.logger.error "MainLoop#start:Exception: #{e.class}: #{e.message}"
    Rails.logger.error Rails.backtrace_cleaner.clean(e.backtrace)
    #retry if MainLoop.try_ones_more?
  end

  private

  def self.try_ones_more?
    if MainLoop.exception_tries < 1
      sleep(2**MainLoop.exception_tries)
      MainLoop.exception_tries+= 1
      true
    else
      false
    end
  end

  def read_event
    @ecs.connection["sys/events/fifo"].post ""
  end


end

