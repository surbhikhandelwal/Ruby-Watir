require 'watir'
require 'watir-scroll'
require 'csv'
require 'date'
require 'watir-webdriver'
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
Selenium::WebDriver::Remote::Http::Default.prepend(Selenium::WebDriver::Remote::Http::DefaultExt)
# disable waiting for elements that aren't on the page - when fiddling around in console, 30s timeout may be an overkill
Watir.relaxed_locate = false
browser = Watir::Browser.new :chrome
browser.window.maximize	
browser.goto 'https://www.sidereel.com/users/login/'
puts browser.title
# To avoid pop ups for login later- writing code for login first
CSV.foreach("/home/qaserver/.jenkins/workspace/side_reel/side_reel_scraper/csv_input1.csv") do |row|

  puts row.inspect
   browser.element(xpath: ".//*[@id='user_email']").send_keys(row[0])
browser.element(xpath: ".//*[@id='user_password']").send_keys(row[1])
end
  csv_date=Time.now
  csv_final = Dir["/home/qaserver/.jenkins/workspace/side_reel/side_reel_scraper/final_result/"][0]
  path = csv_final + "Sidereel#{csv_date.strftime('%v')}.csv"
  CSV.open(path, "w+") do |head|
  # path=File.join, 'home', 'qaserver', '.jenkins', 'workspace', 'side_reel' ,'side_reel_scraper','final_result'
  # CSV.open(File.join(path, 'Sidereel' + csv_date.strftime('%v') + '.csv'), "a+") do |head|
    head << ["Scraped Date","Category","Series Name","Release_Year","Season Number","Episode Number","Episode Title","Hash"]
    #break
  end
 # path=File.join, 'home', 'surbhi', 'Desktop', 'Data', 'Sidereel' 
  #      CSV.open(File.join(path, 'Sidereel' + csv_date.strftime('%v') + '.csv'), "a+") do |head|
   # head << ["Scraped Date","Series Name","Release_Year","Season Number","Episode Number","Episode Title","Hash"]
   #end
browser.element(xpath: "//button[contains(@class,'loginSubmitEvent')]").click
browser.goto 'http://www.sidereel.com/calendar'

#t=Date.today.prev_day
browser.element(xpath: "//div[@id='calendar-container']//button[@class='slick-prev slick-arrow']").click
  sleep 2
  t=Date.today
  days = 2
 #while days > 0
    
    check_for_date = t - days
    #days -= 1
    current_date=check_for_date.strftime("%d")
  if current_date<'10'
    current_date=current_date[1]
  end
  puts current_date.inspect

dates=browser.elements(xpath: "//div[contains(@class,'slick-active')]/div/div/h2")
count_date=dates.count
counter=0
dates.each do |date|
  puts counter
  counter +=1
  puts date.text.strip
  
  d=date.text.split(//).last(2).join.strip
 
  puts d.inspect
  if d==current_date
    puts d
    break
  end
end
puts counter
shows=browser.elements(xpath: "//div[contains(@class,'slick-active')][#{counter}]/div/div/div/div/div[2]/div/a")
shows.each do |show|
  browser.execute_script("window.scrollBy(0,400)")
  #browser.window.last.use do
  series_title= show.text
  puts series_title
  #next if !series_title.include?("Dad")
  show.click(:command, :shift)
  sleep 5
  browser.windows.last.use
  puts browser.title
 
  puts browser.element(:xpath, ".//*[contains(@id,'tracked-show')]/div[1]/div[1]/div/h1").text
  datas=browser.elements(xpath: "//div[@class='show-for-medium-up']/div[contains(@class,'columns')]")
  count_data=datas.count
  counter_1=0
  browser.execute_script("window.scrollBy(0,1200)")
 


  datas.each do |data|
    counter_1 +=1
    if data.text.include? "Previous Episode"
      puts counter_1
      season_no=browser.element(xpath: "(//div[@class='episode-info']//span[@class='ordinals']//a[1])[#{counter_1}]").text.match(/([0-9]+)/)[1]
      puts season_no
      episode_no=browser.element(xpath: "//div[@class='show-for-medium-up'][#{counter_1}]/div/div/div/div[2]/div/div/span/span/a[2]").text.match(/([0-9]+)/)[1]
      puts episode_no
      episode_title=browser.element(xpath: "//div[@class='show-for-medium-up'][#{counter_1}]/div/div/div/div[2]/div/div/span[2]/a").text
      puts episode_title
      airing_date=""  
      begin
        airing_date_general=browser.element(xpath: "//div[@class='show-for-medium-up'][#{counter_1}]//div[contains(@class,'episode-airing-info')]")
        airing_US_date=browser.element(xpath: "//div[@class='show-for-medium-up'][#{counter_1}]//div[contains(@class,'episode-airing-info')]/span[contains(@class,'united-states')]")
        puts 'US:' +airing_US_date.text
        puts 'without US: '+airing_date_general.text
        rescue Watir::Exception::UnknownObjectException,Selenium::WebDriver::Error::UnknownError => e 
        puts e
        
      end
       puts "airing date: #{airing_date}"
        if airing_date_general.text.empty? 
        puts 'exists'
        airing_date=airing_US_date.text
      else
        puts 'US date doesnot exist'
        airing_date=airing_date_general.text
      end
      puts airing_date
      begin
        release_date=browser.element(xpath: "//div[contains(@class, 'show-for-medium-up')][#{count_data}]//div[contains(@class, 'episode-airing-info')]").text
        release_year=release_date.split(//).last(4).join
        puts release_year
      rescue
      end
      puts counter_1
      view_all=browser.element(xpath: "//div[@class='show-for-medium-up'][#{counter_1}]/div/div/div/div[@class='featured-links']/div/div/a[@class='search-for-links raised button']")
      bool= view_all.exists?
      puts bool
      service_videos=Hash.new (0)
      if bool
        view_all.click
        service_videos = {}
        puts "view all clicked!!"
        links=browser.elements(xpath:"//div[@class='link-results']//div[contains(@class,'link_')]/div/a[contains(@class,'bold link')]")
        puts "links #{links.count} #{links.inspect}"
          links.each do |link|
            string=link.href
            service_text=link.text
            puts service_text
            puts string 
            #begin  
            if string.include? "iTunes"
              puts 'itunes'
              service='itunes'
              id=string.match(/http(s)?:\/\/geo.itunes.apple.com\/us\/tv-season.*\/id([0-9]*)\?i=([0-9]*).*/)[3]
              puts id
            elsif string.include? "amazon.com"
              puts 'amazon'
              service= 'amazon'
              id=string.match(/http[s]?:\/\/(www.)?amazon\.com\/([a-zA-Z\/]*)\/([A-Za-z0-9]+)/)[3]
              puts id
            elsif string.include? "netflix"
              puts 'netflixusa'
              service='netflixusa'
              id=string.match(/http(s)?:\/\/www.netflix.*\/([0-9]+)/)[2]
            elsif (string.include? "hulu") && !(service_text.include? "Hulu Clip")
             puts 'hulu'
              service='hulu'
              id=string.match(/http(s)?:\/\/www.hulu.*\/([0-9]+)/)[2]
            elsif string.include? "showtimeanytime"
             puts 'showtimeanytime'
             service='showtimeanytime'
             id=string.match(/http(s)?:\/\/www.showtimeanytime.*\/([0-9]+)/)[2]
            elsif string.include? "youtube"
              puts 'youtube'
              service='youtube'
              id=string.match(/http[s]?:\/\/www.youtube\.com.*\/watch\?v=([A-Za-z0-9]+)/)
            elsif string.include? "hbogo"
              service='hbogo'
              id=string.match(/http:\/\/play.hbogo.com\/episode\/urn:hbo:episode:([A-Za-z0-9_]+)/)[1]
            end          
            service_videos[service] = service_videos.fetch(service, []) + [id]
            #rescue Watir::Exception::UnknownObjectException
            #end
          end
        end
        #next if bool
        #zip_array=service_array.zip id_array
        # service_id=service_videos[service].collect {|x,y| "#{x}##{y}"}
        
        hash1=service_videos.reject{|x,y| x.nil?}
        CSV.open(path, "ab") do |csv1|
        csv1 << [airing_date, "Recently Added", series_title, release_year, season_no, episode_no, episode_title, hash1]
      end
      break
    end  
  end
  browser.windows.last.close
  browser.windows.first.use 
  end
#end
sleep 5

