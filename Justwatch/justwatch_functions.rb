module Functions
	 
	$conf = YAML::load_file(File.join(__dir__, 'justwatch_properties.yml'))
	def initialise_browser
		client = Selenium::WebDriver::Remote::Http::Default.new
		client.timeout = 700 # seconds � default is 60 second
		Watir.relaxed_locate = false
		$browser = Watir::Browser.new :chrome, :http_client => client
		#, headless: true
		$browser.window.maximize 
		website_url=$conf["url_us"]
		#Watir::Waiter.wait_until(15) { $browser.div(:class => "timeline").visible? } 
		puts "website url inspect: "+website_url.inspect
		$browser.goto website_url
		puts $browser.title
	end

	#Watir::Waiter.wait_until(15) { browser.div(:id => "updating_div").visible? } 

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

	#class Array
  		def partial_include? search
	    	self.each do |e|
	      		return true if search.include?(e.to_s)
	    	end
	    	return false
  		end
	#end

	def scrape_data_tvshows
		begin
		run_date = Date.today
		run_date = run_date.strftime("%d-%m-%Y")
		$log = Logger.new("/home/rishabh/Documents/Surbhi/Justwatch/Logs/justwatch_logs#{run_date}")
		CSV.open("/home/rishabh/Documents/Surbhi/Justwatch/Results/Episodes/output_tvshows_#{run_date}.csv", "w+") do |head|
    		head << ["Scraped date", "Type", "Series Title", "Release Year", "Season_Number","Episode_Number","Episode_Title", "Hash"]
		end
		series_title = ""
		release_year = ""
		season_num =""
		epi_num = ""
		epi_title =""
		show_link =Array.new (0)
		service_link =Array.new(0)
		links =Array.new(0)
		service_videos=Hash.new (0)
		service =""
		standard_services = ["nbc", "hulu", "amazon", "itunes", "hbo-now", "vudu", "showtime", "starz", "hbo-go", "netflix-kids"]
		sleep 1
		$browser.element(xpath: $conf["new"]).click
		services =$browser.elements(xpath: $conf["select_services"])
		services.each do |serv|
			begin
				serv_name =serv.href
				$log.info(serv_name)
				if serv_name.include? "playstation" || "abc"
					$log.info (serv_name)
					$browser.element(xpath:$conf["scroll_right"]).click
					sleep 1
				elsif standard_services.partial_include? serv_name
					serv.click				
				end	
			rescue
				$log.info("service can't be clicked")
			break
			end
		end
	    $browser.element(xpath: $conf["tv-shows"]).click
		$log.info("tv show clicked")
		$browser.execute_script("window.scrollBy(0,2400)")
		sleep 8
			shows =$browser.elements(xpath: $conf["yesterday_tvshows"])
			$log.info(shows.count)
			shows.each do |show|
				$log.info(show)
				show_link <<show.href
			end
			show_link =show_link.uniq
		$log.info (show_link)
		show_link.each do |a|
			begin
			service_videos.clear
			service_link.clear
			links.clear
			sleep 1
			$browser.goto a
			sleep 5
			series_title =catch_error_at_element($conf["series_title"])
			$log.info("Series title: #{series_title}")
			epi_details =catch_error_at_element($conf["epi_details"])
			$log.info("Episode Details:  #{epi_details}")
			$browser.element(xpath: $conf["epi_details"]).click
			epi_title =catch_error_at_element($conf["epi_title"]).strip
			$log.info("Episode title:  #{epi_title}")
			epi_links =$browser.elements(xpath: $conf["latest_epi_link"])
			if epi_details.include? "S1 E1"
				epi_links =$browser.elements(xpath: $conf["e1links"])
			end
			season_num =epi_details.split(" ")[0].match(/[0-9].*/)
			epi_num =epi_details.split(" ")[1].match(/[0-9].*/)
			$log.info ("EPI NUM: #{epi_num} SSN NUM: #{season_num}")
			epi_links.each do |link|
				links << link.href
			end
			$browser.element(xpath: $conf["series_title"]).click
			release_year =catch_error_at_element($conf["release_year"])
			release_year =release_year.split("(")[1].split(")")[0]
			$log.info("Release year:  #{release_year}")
			links.each do |l|
				if standard_services.partial_include? l
					$browser.goto l
					service_link <<$browser.url
				end
			end
			$log.info(service_link)
			service_link.each do |string|
				if string.include? "netflix"
					service ='netflixusa'
					id =string.match(/http(s)?:\/\/www.netflix.*\/([0-9]+)/)[2]
				
				elsif string.include? "hulu"
					service ='hulu'
					id =string.match(/http(s)?:\/\/www.hulu.*\/([0-9]+)/)[2]
				
				elsif string.include? "amazon"
					service ='amazon'
					id =string.match(/http[s]?:\/\/(www.)?amazon\.com\/([a-zA-Z\/]*)\/([A-Za-z0-9]+)/)[3]
				
				elsif string.include? "itunes"
					service ='itunes'
					id =string.match(/http(s)?:\/\/itunes.apple.com\/us\/tv-season.*\/id([0-9]*)\?i=([0-9]*).*/)[3]
				
				# if string.include? "hbo-now"

				# end
				elsif string.include? "vudu"
					service ='vudu'
					id =string.match(/http(s)?:\/\/www.vudu.com.*\/([0-9]+)/)[2]
				
				elsif string.include? "showtime"
					service ='showtime'
					id =string.match(/http(s)?:\/\/www.showtime.*\/([0-9]+)/)[2]
				
				elsif string.include? "starz"
					service ='starz'
					id =string.match(/http(s)?:\/\/www.starz.com.*\/([0-9]+)/)[2]
				
				elsif string.include? "hbo-go"
					service ='hbogo'
					id =string.match(/http:\/\/play.hbogo.com\/episode\/urn:hbo:episode:([A-Za-z0-9]+)/)[1]
				elsif string.include? "nbc"
					service ='nbc'
					id =string.match(/http(s)?:\/\/www.nbc.com.*\/([1-9*]+)/)[2]
				else
				 	next
				end
				#id =id.compact
				service_videos[service] = service_videos.fetch(service, []) + [id]
				#$log.info(service_videos)
				#service_videos=service_videos.reject{|x,y| y.nil?}
			end
			rescue Exception => e
				$log.info("Exception captured #{e}")
			end
			service_videos =service_videos.reject{|x,y| x.nil?}
			service_videos 	=service_videos.reject{|x,y| x.empty?}
			$log.info(service_videos)
			CSV.open("/home/rishabh/Documents/Surbhi/Justwatch/Results/Episodes/output_tvshows_#{run_date}.csv","a+") do |cs|
                cs << [run_date, "Recently Added", series_title, release_year, season_num, epi_num, epi_title, service_videos]
            end
        end
        rescue Exception => e
        $log.info ("Exception captured #{e}")  
		end
	end

	def scrape_data_movies
		begin
		run_date = Date.today
		run_date = run_date.strftime("%d-%m-%Y")
		$log = Logger.new("/home/rishabh/Documents/Surbhi/Justwatch/Logs/justwatch_logs#{run_date}")
		CSV.open("/home/rishabh/Documents/Surbhi/Justwatch/Results/Movies/output_movies_#{run_date}.csv", "w+") do |head|
    		head << ["Scraped date", "Type", "Movie Title", "Release Year", "Hash", "Cast"]
		end
		movie_title = ""
		release_year = ""
		show_link =Array.new (0)
		service_link =Array.new(0)
		links =Array.new(0)
		service_videos=Hash.new (0)
		final_cast =Array.new
		act =Array.new
		service =""

		standard_services = ["netflix", "hulu", "amazon", "itunes", "hbo-now", "vudu", "showtime", "starz", "hbo-go", "netflix-kids"]
		sleep 1
		$browser.element(xpath: $conf["new"]).click
		services =$browser.elements(xpath: $conf["select_services"])
		services.each do |serv|
			begin
				serv_name =serv.href
				$log.info(serv_name)
				if serv_name.include? "playstation" || "abc"
					$log.info (serv_name)
					$browser.element(xpath:$conf["scroll_right"]).click
					sleep 1
				elsif standard_services.partial_include? serv_name
					serv.click				
				end	
			rescue
				$log.info("service can't be clicked")
			break
			end
		end
		#$browser.element(xpath: $conf["tv-shows"]).click
		$browser.element(xpath: $conf["movies"]).click
		$browser.execute_script("window.scrollBy(0,2400)")
		sleep 5
		shows =$browser.elements(xpath: $conf["yesterday_tvshows"])
		$log.info(shows.count)
		shows.each do |show|
			$log.info(show)
			show_link <<show.href
		end
		show_link =show_link.uniq
		$log.info (show_link)
		show_link.each do |a|
			begin
			service_videos.clear
			service_link.clear
			links.clear
			act.clear
			final_cast.clear
			director = nil
			sleep 1
			$browser.goto a
			sleep 5
			movie_title =catch_error_at_element($conf["movie_title"])
			movie_title =movie_title.split("(")[0].strip
			$log.info("Movie title: #{movie_title}")

			release_year =catch_error_at_element($conf["release_year"])
			release_year =release_year.split("(")[1].split(")")[0]
			$log.info("Release year:  #{release_year}")
			epi_links =$browser.elements(xpath: $conf["movie_serv_links"])
			$browser.execute_script("window.scrollBy(0,2400)")

			director =$browser.element(xpath: $conf["director"]).text
			$log.info("Director: #{director}")
			actors =$browser.elements(xpath: $conf["cast"])
			actors.each do |cast|
				act << cast.text
			end
			if !(director.nil?)
				final_cast << director
			end
			final_cast = final_cast+act
			final_cast.reject { |e| e.empty? }
			epi_links.each do |link|
				links << link.href
			end
			$log.info ("links: #{links}")
			links.each do |l|
				if standard_services.partial_include? l
					$browser.goto l
					service_link <<$browser.url
				end
			end
			service_link =service_link.uniq
			$log.info(service_link)
			service_link.each do |string|
				if string.include? "netflix"
					service ='netflixusa'
					id =string.match(/http(s)?:\/\/www.netflix.*\/([0-9]+)/)[2]
				
				elsif string.include? "hulu"
					service ='hulu'
					id =string.match(/http(s)?:\/\/www.hulu.*\/([0-9]+)/)[2]
				
				elsif string.include? "amazon"
					service ='amazon'
					id =string.match(/http[s]?:\/\/(www.)?amazon\.com\/([a-zA-Z\/]*)\/([A-Za-z0-9]+)/)[3]
				
				elsif string.include? "itunes"
					service ='itunes'
					id =string.match(/http(s)?:\/\/itunes.apple.com\/us\/movie.*\/id([0-9]*)/)[2]
				
				# if string.include? "hbo-now"

				# end
				elsif string.include? "vudu"
					service ='vudu'
					id =string.match(/http(s)?:\/\/www.vudu.com.*\/([0-9]+)/)[2]
				
				elsif string.include? "showtime"
					service ='showtime'
					id =string.match(/http(s)?:\/\/www.showtime.*\/([0-9]+)/)[2]
				
				elsif string.include? "starz"
					service ='starz'
					id =string.match(/http(s)?:\/\/www.starz.com.*\/([0-9]+)/)[2]
				
				elsif string.include? "hbo-go"
					service ='hbogo'
					id =string.match(/http:\/\/play.hbogo.com\/feature\/urn:hbo:feature:([A-Za-z0-9]+)/)[1]
				else
				 	next
				end
				#id =id.compact
				service_videos[service] = service_videos.fetch(service, []) + [id]
				$log.info(service_videos)
				#service_videos=service_videos.reject{|x,y| y.nil?}
			end
		rescue Exception =>e
			$log.info("Exception captured #{e}")
		end
			service_videos =service_videos.reject{|x,y| x.nil?}
			service_videos 	=service_videos.reject{|x,y| x.empty?}
			#service_videos.uniq { |e| e[id] }
			$log.info(service_videos)
			CSV.open("/home/rishabh/Documents/Surbhi/Justwatch/Results/Movies/output_movies_#{run_date}.csv","a+") do |cs|
                cs << [run_date, "Recently Added", movie_title, release_year, service_videos, final_cast]
            end
        end
		rescue => e
			$log.info ("Error occurred: #{e}")
		end				
	end
end