require 'watir'
require 'watir-scroll'
require 'csv'
require 'date'
require 'watir-webdriver'
# require 'yaml'
# s.add_runtime_dependency 'yaml'	
#require 'watir-webdriver/extensions/wait'
require '/home/rishabh/Documents/Surbhi/Justwatch/justwatch_functions.rb'
include Functions
initialise_browser
scrape_data_tvshows
# initialise_browser
# scrape_data_movies