require 'logger'

class BobLogger < Logger
  private_class_method :new
  @@logger = nil
  def Logger.get
    @@logger = new(STDOUT) unless @@logger
    @@logger
  end

  def Logger.info(message)
    get.info(message)
  end

  def Logger.debug(message)
    get.debug(message)
  end
end
