class Settings
  @sender = nil
  @email_when_no_status_change = false
  @scan_build = nil
  @sleep_duration = 60
  @admin_email_addresses = []
  
  class << self
    attr_accessor :sender, :email_when_no_status_change, :scan_build, :sleep_duration, :admin_email_addresses
  end
end
