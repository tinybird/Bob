#!/usr/bin/env ruby

$: << File.dirname(__FILE__) + '/bob'
$: << File.dirname(__FILE__) + '/lib'
$: << File.dirname(__FILE__) + '/lib/action_mailer_optional_tls/lib'
$: << File.dirname(__FILE__) + '/lib/command_line'
$: << File.dirname(__FILE__) + '/helpers'

require 'bob_logger'
require 'project'
require 'settings'
require 'build'
require 'mailer'

begin
  require 'daemon'
rescue => e
  BobLogger.info "Build bot died: #{e}"
  
  if Settings.sender and Settings.admin_email_addresses.length > 0
     Mailer.send(:deliver_build_failure, Settings.admin_email_addresses,
                 Settings.sender, "Build bot died", "#{e}")
   end
end
