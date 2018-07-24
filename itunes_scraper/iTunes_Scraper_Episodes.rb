require 'watir'
require 'watir-scroll'
require 'csv'
require 'date'
require 'watir-webdriver'
require 'yaml'
require 'time'
require 'headless'
require 'logger'
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
module Functions

	$conf = YAML::load_file(File.join(__dir__, 'properties_iTunes.yml'))
	def initialise_browser
		
		Watir.relaxed_locate = false
		$browser = Watir::Browser.new :chrome
		#, headless: true
		$browser.window.maximize 
		website_url=$conf["url"]
		puts "website url inspect: "+website_url.inspect
		$browser.goto website_url
		puts $browser.title
	end

	def catch_error_at_elements(xpath_from_conf)
		begin
			element_text = Array.new
			element_text = $browser.elements(xpath: xpath_from_conf)

		rescue =>e
			$log.info(e) 
		end
		return element_text
	end
	def catch_error_at_element(xpath_from_conf)
		begin
			#element_text = Array.new
			element_text_single = $browser.element(xpath: xpath_from_conf).text
		rescue =>e
			$log.info(e) 
		end
		return element_text_single
	end


	def scrape_data
		csv_date=Time.now
		array_movie=[]
		array_media=[]
		array_media_text=[]
		array_movie_genre=[]
		array_actors=[]
		array_directors=[]
		array_producers=[]
		array_movie_text=[]
		actors_cast = []
		array_tvshow_genre = []
		array_series_text = []
		array_series = []
		array_episode_title = []
		tvshow_genre_text = []
		episode_titles = []
		title=""
		genre_text = ""
		hash1 = ""
		service_videos=Hash.new (0)
		id = ""
		counter=0
		counter_epi=0
		hash1 = Hash.new (0)
		series_release_date = ""
		
		csv_date=Time.now
  		path1=File.join, 'home', 'qaserver', '.jenkins', 'workspace', 'itunes_scraper', 'Results', 'Episodes'
		path=File.join, 'home', 'qaserver', '.jenkins', 'workspace', 'itunes_scraper', 'Results', 'Episodes'
		media_types=$browser.elements(xpath: $conf["media_type"])
		media_types.each do |media|
			media_text= media.text
			array_media<<media.href
			array_media_text<<media.text
		end
		array_media.each do |a|
			
			if a.include? "tv-shows"
				begin
					$log = Logger.new("/home/qaserver/.jenkins/workspace/itunes_scraper/Logs/iTunes_Scraper_TV Shows#{csv_date.strftime('%v')}")
					$log.info("media link:  #{a}")
					$browser.goto a
					click_genre = $browser.element(xpath: $conf["check_genre_episodes"]).click
					tvshow_genres = $browser.elements(xpath: $conf["genre_episodes"])
					tvshow_genres.each do |g|
						tvshow_genre_text << g.text
						array_tvshow_genre<<g.href	
					end
					$log.info("array of tv show genre:  #{tvshow_genre_text}")
					array_tvshow_genre.each do |h|
					#if h.include? "latino-tv"
						$log.info("Genre link: #{h}")
						$browser.goto h
						series = $browser.elements(xpath: $conf["episode_links"])
						series.each do |i|
							series_name=i.text
							array_series_text<<i.text
							array_series<<i.href
						end
						#break
					end
					#end
					$log.info("array of series:  #{array_series_text}")
					array_series = array_series.uniq	
					$log.info ("Unique Season count:  #{array_series.count}")
					sleep 2
					array_series.each do |j|
						counter_epi += 1
						$browser.goto j
					 	ser_title = array_series_text[counter_epi-1]
					 	$log.info ("Series Title:  #{ser_title}")
						series_title = catch_error_at_element($conf["episode_title"])
						$log.info ("Series Title from page after launching it:  #{series_title}")
						begin
							season_num = series_title.split(",")[1].strip.match(/[0-9]+/)[0]
							# count_num = season_num.count
							# season_num = season_num[count_num - 1].strip
							$log.info("count:  #{count_num}")
							$log.info("Season Number:   #{season_num[count_num - 1]}")
						rescue =>e
							$log.info(e) 
							$log.info("season_num doesn't exist")
						end
						begin
							series_title = series_title.split(",")[0]
						rescue 	=>e
							$log.info(e) 
						end
						begin
							if series_title.include? "("
								series_title =series_title.split("(")[0].strip
							end
						rescue =>e
							$log.info(e) 
							series_title =series_title
						end
						series_genre = catch_error_at_element($conf["episode_genre"])
						$log.info("Genre of series:   #{series_genre}")
						series_release_date = catch_error_at_element($conf["episode_release_date"])
						begin
							series_release_date = series_release_date.split(",").last.strip
							$log.info("Release date of series:  #{series_release_date}")
						rescue =>e
							$log.info(e) 
						end
						# series_rating = catch_error_at_element($conf["tv_show_rating"])
						# $log.info("Rating of series:  #{series_rating}")
						#episode_titles = Hash.new {0}
						episode_titles = $browser.elements(xpath: $conf["episodes_in_season"])
						count_episode_in_season=0
						episode_titles.each do |k|
							hash1 = Hash.new (0)
							service_videos=Hash.new (0)
							itunes_link = ""
							count_episode_in_season += 1
							epi_title = k.attribute_value('preview-title')
							$log.info("Episode Title:  #{epi_title}")
							begin
								if epi_title.include? "Season"
									if epi_title.include? "Episode"
										if epi_title.include? ":"
											epi_title= epi_title.split(":")[1].strip
										elsif epi_title.include? ","
											epi_title =epi_title.split(",")[2].strip
										end
									end
								end
							rescue =>e
								$log.info(e) 
								epi_title =epi_title
							end
							begin
								if epi_title.include? "("
									epi_title =epi_title.split("(")[0].strip
								end
							rescue =>e
								$log.info(e) 
								epi_title =epi_title
							end
							episode_itunes_links = $browser.elements(xpath: $conf["episode_view_in_itunes"])
							count_episode = episode_itunes_links.count
							$log.info("count_episode:  #{count_episode}")
							$log.info("count_episode_in_season:  #{count_episode_in_season}")
							if !(count_episode_in_season > count_episode)
								service='itunes'
              					$log.info (service)
								episode_itunes_link = $browser.element(xpath: $conf["episode_view_in_itunes"] + "[#{count_episode_in_season}]").attribute_value('onclick')
								itunes_link = episode_itunes_link.match(/http(s)?:\/\/itunes.apple.com\/us\/tv-season.*\/id([0-9]*)\?i=([0-9]*)/)[3]
								$log.info("itunes_link:  #{itunes_link}")
								#$log.info(ser_title)
								$log.info(season_num)
								$log.info(count_episode_in_season)
								$log.info(epi_title)
								$log.info(series_release_date)
								#$log.info(series_rating)
								$log.info(itunes_link)
								service_videos[service] = service_videos.fetch(service, []) + [itunes_link]
              					hash1=service_videos.reject{|x,y| x.nil?}
              					$log.info (hash1)
							end
							CSV.open(File.join(path, 'iTunes_Scraper_Episodes' + csv_date.strftime('%v') + '.csv'), "a+") do |csv|
          						csv << [series_title, series_genre, season_num, count_episode_in_season, epi_title, series_release_date, hash1]
							end
						end
					end		
				rescue =>e
					$log.info(e) 
				end
			end
		end
	end
end