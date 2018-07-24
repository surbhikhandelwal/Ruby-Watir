require 'watir'
require 'watir-scroll'
require 'csv'
require 'date'
require 'watir-webdriver'
require 'yaml'
require 'time'
#require 'select'
module Functions

	$conf = YAML::load_file(File.join(__dir__, 'properties.yml'))
	def initialise_browser
		
		Watir.relaxed_locate = false
		$browser = Watir::Browser.new :chrome
		$browser.window.maximize 
		website_url=$conf["url"]
		puts "website url inspect: "+website_url.inspect 
		$browser.goto website_url
		puts $browser.title
	end

	def scrape_data
		csv_date=Time.now
		puts csv_date
  		path='D:', 'Surbhi', 'Next-Episode' 
  		CSV.open(File.join(path, 'Next-Episode' + csv_date.strftime('%v') + '.csv'), "a+") do |head|
    		head << ["Air Date", "Service", "Series Name", "Release_Year", "Season Number", "Episode Number", "Episode Title", "Rovi ID", "Air Date UTC Time", "Ozone Timestamp created", "Result"]
    	break
 		end
		
		air_date_of_episode=""
		episode_title=""
		puts "start"
		$browser.element(xpath: $conf["channel_type"]).click
		sleep 2
		$browser.select_list(xpath: $conf["channel_type"]).option(:text => "Shows from all channels").select
		puts "home page"
		service=["HBO", "Netflix", "Showtime", "hulu", "Starz"]
		service.each do |x|
			$browser.windows.first.use
			$browser.element(xpath: $conf["prominent_channel_dropdown"]).click
			#Case 1: HBO
			
			counter=0
			sleep 2
			$browser.select_list(xpath: $conf["prominent_channel_dropdown"]).option(:text => "#{x}").select
			sleep 5
			puts "service name: "+ $browser.element(xpath: $conf["service_name"]).text
		
			#content_on_page=$browser.elements(xpath: $conf["contents"])
			begin
			content_on_each_day=$browser.elements(xpath: $conf["contents_each_day"])
			content_on_each_day.each do |title|
				$browser.windows.first.use
				air_date_of_episode=""
				episode_title=""
				counter +=1
				epi=$browser.element(xpath: $conf["season_epi_combo"]+"[#{counter}]").text
				puts "epi"+epi
				epi_num=epi.split("x")[1]
				puts epi_num
				series_name= title.text
				puts series_name
				#air_date=$browser.element(xpath: "(//div[@class='container_wrapper_schedule']//h2/span[@class='schedule_date'])[#{counter}]").text
				#date=DateTime.parse("#{air_date}").strftime("%y-%m-%d")
				#puts date
				title.click(:command, :control)
				sleep 5
				$browser.windows.last.use
				begin
					sleep 3
					air_time=$browser.element(xpath: $conf["air_time"])
				rescue Watir::Exception::UnknownObjectException
					puts "not found"
				end
				if air_time.text.include? "at"
					puts "air time: "+air_time.text
					t= air_time.text.slice! "at"
					time=DateTime.parse("#{air_time.text}").strftime("%H:%M")
					puts "time: "+time
					
					click_season=$browser.element(xpath: $conf["current_season"])
					puts "season nuber: "+click_season.text
					season_num= click_season.text.match(/[0-9].*/)
					puts season_num
					click_season.click
					episode_num=$browser.elements(xpath: $conf["episode_number"])
					counter1=0
					episode_num.each do |e|

						counter1 +=1
						begin
							if e.text.to_i == epi_num.to_i
								puts "episode no"
								puts e.text.to_i
								puts $conf["air_date"]+"[#{counter1}]"
								air_date_of_episode=$browser.element(xpath: $conf["air_date"]+"[#{counter1}]").text
								puts air_date_of_episode
								begin
									air_date_of_episode=DateTime.parse("#{air_date_of_episode}").strftime("%F")
									puts air_date_of_episode
								rescue ArgumentError
									puts "Invalid Date"
								end
								puts $conf["episode_title"]+"[#{counter1}]"
								episode_title=$browser.element(xpath: $conf["episode_title"]+"[#{counter1}]").text
								puts "episode title: "+episode_title
							end
						rescue NoMethodError, Watir::Exception::UnknownObjectException
						
						end
					end
					season_count=$browser.elements(xpath: $conf["seasons_count"]).count
					puts "season count"
					puts season_count
					puts "//div[@id='inner_schedule_seasons']/a[#{season_count}]"
					season_1=$browser.element(xpath: "//div[@id='inner_schedule_seasons']/a[#{season_count}]").click
					puts "season 1 clicked"
					release_year=$browser.element(xpath: $conf["series_release_year"]).text
					release_year=release_year.split(//).last(4).join
					puts "release year: "+release_year
					result="To be verified"
					air_date=air_date_of_episode+" "+time
					puts "final air date: "+air_date
					rovi_ID=""
					air_date_UTC_time=""
					ozone_timestamp_created=""
					# path=File.join, 'D:', 'Surbhi', 'Next-Episode'
					if x=="HBO"
        				CSV.open(File.join(path, 'Next-Episode' + csv_date.strftime('%v') + '.csv'), "a+") do |csv|
	          				csv << [air_date, "hbogo", series_name, release_year, season_num, epi_num, episode_title, rovi_ID, air_date_UTC_time, ozone_timestamp_created, result]
    	      				csv << [air_date, "hbonow", series_name, release_year, season_num, epi_num, episode_title, rovi_ID, air_date_UTC_time, ozone_timestamp_created, result]
        				end
        			elsif x=="Showtime"
        				CSV.open(File.join(path, 'Next-Episode' + csv_date.strftime('%v') + '.csv'), "a+") do |csv|
          					csv << [air_date, "showtime", series_name, release_year, season_num, epi_num, episode_title, rovi_ID, air_date_UTC_time, ozone_timestamp_created, result]
          					csv << [air_date, "showtimeanytime", series_name, release_year, season_num, epi_num, episode_title, rovi_ID, air_date_UTC_time, ozone_timestamp_created, result]
        				end
           			elsif x=="Netflix"
           				CSV.open(File.join(path, 'Next-Episode' + csv_date.strftime('%v') + '.csv'), "a+") do |csv|
          					csv << [air_date, "netflixusa", series_name, release_year, season_num, epi_num, episode_title, rovi_ID, air_date_UTC_time, ozone_timestamp_created, result]
          				end
          			else
           				CSV.open(File.join(path, 'Next-Episode' + csv_date.strftime('%v') + '.csv'), "a+") do |csv|
          					csv << [air_date, x, series_name, release_year, season_num, epi_num, episode_title, rovi_ID, air_date_UTC_time, ozone_timestamp_created, result]
          				end
					end
					$browser.windows.last.close
					$browser.windows.first.use 
				end
				puts "one service ends here"
				#$browser.windows.first.use 
			end
		rescue
			puts "no content available for the service"
		end
		end
	end
end