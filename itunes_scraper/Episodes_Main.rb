require 'watir'
require 'watir-scroll'
require 'csv'
require 'date'
require 'watir-webdriver'
require 'yaml'
#require '/home/surbhi/Desktop/Data/iTunes_Scraper/functions_iTunes.rb'
require '/home/qaserver/.jenkins/workspace/itunes_scraper/iTunes_Scraper_Episodes.rb'
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

