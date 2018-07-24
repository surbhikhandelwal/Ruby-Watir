require 'watir'
require 'watir-scroll'
require 'csv'
require 'date'
require 'watir-webdriver'
require 'yaml'
require 'D:/Surbhi/Next-Episode/functions_next_episode.rb'
include Functions
module Selenium
  module WebDriver
    module Remote
      module Http
        module DefaultExt
          def request(*args)
            tries ||= 3
            super
          rescue Net::ReadTimeout, Net::HTTPRequestTimeOut, Errno::ETIMEDOUT => ex
            puts "#{ex.class} detected, retrying operation"
           (tries -= 1).zero? ? raise : retry 
                     
          end
        end
      end
    end
  end
end
#Selenium::WebDriver::Remote::Http::Default.prepend(Selenium::WebDriver::Remote::Http::DefaultExt)
# disable waiting for elements that aren't on the page - when fiddling around in console, 30s timeout may be an overkill
initialise_browser
scrape_data
