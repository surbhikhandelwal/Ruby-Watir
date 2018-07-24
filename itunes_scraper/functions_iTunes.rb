require 'watir'
require 'watir-scroll'
require 'csv'
require 'date'
require 'watir-webdriver'
require 'yaml'
require 'time'
require 'headless'
require 'logger'
require 'retry'
module Selenium
  module WebDriver
    module Remote
      module Http
        module DefaultExt
          def request(*args)
            tries ||= 20
            super
          rescue Net::ReadTimeout, Net::HTTPRequestTimeOut, Errno::ETIMEDOUT => ex
            puts "#{ex.class} detected, retrying operation"
           (tries -= 20).zero? ? raise : retry 
                     
          end
        end
      end
    end
  end
end


module Functions
	Selenium::WebDriver::Remote::Http::Default.prepend(Selenium::WebDriver::Remote::Http::DefaultExt)
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
		max_retries = 30
  		times_retried = 0
		begin
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
		title_text =""
		
		csv_date=Time.now
  		path1=File.join, 'home', 'qaserver', '.jenkins', 'workspace' ,'itunes_scraper', 'Results', 'Movies'
		path=File.join, 'home', 'qaserver', '.jenkins', 'workspace' ,'itunes_scraper', 'Results', 'Movies'
		media_types=$browser.elements(xpath: $conf["media_type"])
		media_types.each do |media|
			media_text= media.text
			array_media<<media.href
			array_media_text<<media.text
		end

		array_media.each do |a|
			if a.include? "movies"
				# CSV.open("/home/surbhi/Desktop/Data/iTunes_Scraper/iTunes_movies_Scraper#{csv_date}.csv", "w+") do |head|
    #     			head << ["Movie Title", "Average Rating","Release Year","Link","Genre", "Actors", "Producers", "Directors"]
				# end
				$log = Logger.new("/home/qaserver/.jenkins/workspace/itunes_scraper/Logs/iTunes_Scraper_Movies#{csv_date.strftime('%v')}")
				$log.info("media link:  #{a}")
				$browser.goto a
				movie_genres =$browser.elements(xpath: $conf["movie_genre"])
				movie_genres.each do |genre|
					genre_text =genre.text
					$log.info (genre_text)
					array_movie_genre<<genre.href	
				end
				array_movie_genre.each do |b|
						$log.info("Genre link: #{b}")
						$browser.goto b
						movies =$browser.elements(xpath: $conf["movie_links"])
						movies.each do |link|
							movie_name =link.text
							$log.info (movie_name)
							array_movie_text<<link.text
							array_movie<<link.href
						end
					#break
				end	
				array_movie =array_movie.uniq
				$log.info("Array Movie Count:  #{array_movie.count}")
				array_movie.each do |c|
					service_videos =Hash.new (0)
					hash1 = Hash.new (0)
					id = ""
					$log.info (c)
					if c.include? "itunes"
              			service ='itunes'
              			$log.info (service)
              			id = c.match(/http(s)?:\/\/itunes.apple.com\/us\/movie.*\/([A-Za-z0-9-%]+)\/id([0-9]*).*/)[3]
              			$log.info (id)
              			service_videos[service] = service_videos.fetch(service, []) + [id]
              			hash1=service_videos.reject{|x,y| x.nil?}
              			$log.info (hash1)
              		end
					array_actors=[]
					array_directors=[]
					array_producers=[]	
					counter += 1
					# movie_title=array_movie_text[counter]
					# $log.info("Movie Title:  #{movie_title}")
					$log.info("Movie link:  #{c}")
					#begin
					$browser.goto c
					sleep 4
					# rescue Net::ReadTimeout => error
					#     if times_retried < max_retries
					#       times_retried += 1
					#       $log.info("Failed to <catch the element>, retry #{times_retried}/#{max_retries}")
					#       retry
					#     else
					#       $log.info("Exiting script. <Even after 30 retries net couldn't recover :( >")
					#       exit(1)
					#     end
				 #  	end
					title =catch_error_at_element($conf["content_title"])
					begin
						#title_text =title.text
						if title.include? "("
							title =title.split("(")[0].strip
							$log.info ("Movie title: #{title}")
						end
					rescue
						$log.info ("Error exists while editing title")
						title =title
					end
					$log.info ("Movie title: #{title}")

					average_rating = catch_error_at_element($conf["tomatometer"])
					actors_cast = catch_error_at_elements($conf["actors"])
					actors_cast.each do |d|
						array_actors<<d.text
					end
					$log.info("actors:  #{array_actors}")
					producers =catch_error_at_elements($conf["producers"])
					producers.each do |e|
						array_producers<<e.text
					end
					$log.info("producers:  #{array_producers}")
					directors =catch_error_at_elements($conf["directors"])
					directors.each do |f|
						array_directors<<f.text
					end
					$log.info("directors:    #{array_directors}")
					release_year =catch_error_at_element($conf["release_date_other_type"])
					movie_genre =catch_error_at_element($conf["genre_other_type"])
					CSV.open(File.join(path, 'iTunes_Scraper_Movies' + csv_date.strftime('%v') + '.csv'), "a+") do |csv|
          				csv << [title, average_rating, release_year, hash1, movie_genre, array_actors, array_producers, array_directors]
          			end
				end
			end
		end
	rescue Exception => e
		$log.info (e)
	end

	end
end