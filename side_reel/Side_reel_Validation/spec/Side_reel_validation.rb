require 'Ozone_Global_Config'
require 'csv'
require 'mongo'
require 'rest_client'
require 'json'
require 'date'

include OzoneGlobalConfig

describe 'Service specific award shows scraper' do
	it 'Shows the coverage of required service shows on Ozone' do

		timestamp = Time.now.strftime("%d_%m_%Y_%H:%M")
		$rovi_ingestion_status = nil
		$gn_ingestion_status = nil
		$serv_name = "All"
		iterations = 0
		$avail_on_cloud_cnt = 0
		$avail_on_rovi_cnt = 0
		$not_avail_on_gn_cnt = 0
	# $rovi_ingest_failures_cnt = 0
	# $rovi_ingest_success_cnt = 0
	$not_avail_on_rovi_and_gn_cnt = 0		
	$not_avail_on_ozone_and_rovi_but_avail_on_gn_cnt = 0
	$not_avail_on_ozone_but_avail_on_rovi_and_gn_cnt = 0
	$not_avail_on_ozone_and_gn_dump_but_avail_on_rovi_dumps_cnt = 0
	$avail_on_gracenote_after_mapping_cnt = 0
	$real_gn_ingestion_cnt = 0
	$overall_failures = 0
	$base_url = $conf["request_headers"]["Host"]   
   

	Mongo::Logger.logger.level = ::Logger::FATAL

	run_date = Date.today
	run_date = run_date.strftime("%Y%m%d")

	csv_input = ENV['csv_input']
	if csv_input.nil?
		# csv_input = Dir["/var/lib/jenkins/workspace/Netflix_recents_validation/input_csv/#{run_date}Netflix_series.csv"]
		csv_input = Dir["/home/qaserver/.jenkins/workspace/side_reel/Side_reel_Validation/input_csv/*.csv"][0]
		puts "csv input file is : #{csv_input}"
	end

	csv_input1 = Dir["/home/qaserver/.jenkins/workspace/side_reel/Side_reel_Validation/master_csv/*.csv"][0]

	log_file = Dir["/home/qaserver/.jenkins/workspace/side_reel/Side_reel_Validation/logs/"][0]

	$arr_prog_ids = Array.new
	$arr_episode_prog_ids = Array.new
	$arr_incorrect_mapping_episodes = Array.new
	$launch_ids_from_csv = Array.new
	$ott_links_from_cloud = Array.new
	$all_vids_cloud =  Array.new
	arr_of_arrs = Array.new
	
	$to_validate_dump_array = ["rovi","gracenote","hulu","vudu"]
	primary_source = "Rovi"

	# tmp = csv_input1.dup
	# tmp.sub!(".csv", "")
	#temp = temp.slice! ".csv"
	log_output = log_file + "_#{$env}_#{timestamp}.log"

	#log = Logger.new("amazon_movies_recently_added_spec_#{$env}_#{timestamp}.log")
	log = Logger.new(log_output)

	#puts "Class: #{csv_input.class}"
	client = Mongo::Client.new([ '192.168.86.12:27017' ], :database => 'qadb')

	todays_date = Date.today
	log.info "todays Date: #{todays_date}"

	csv_final = Dir["/home/qaserver/.jenkins/workspace/side_reel/Side_reel_Validation/final_csv/"][0]
	temp = csv_final.dup
	#temp.sub!(".csv", "")
    csv_output = temp + "#{$env}_#{run_date}master_csv.csv"

    CSV.open(csv_output, "w+") do |head|
    	head << ["Scraped Date","category","Series Name","Release_Year","Season Number","Episode Number","Episode Title","Links","Result","Error","Program ID","Date Validated"]
    end

	if !csv_input.nil?
		counter = 0
		CSV.foreach(csv_input) do |row|
			#puts row
			if counter == 0
				log.info "Skip adding header"
				counter += 1
				next
			end
		
			#puts row[7]
			links = row[7]
			if links == "{}"
				log.info " Empty links from csv, hence skip"
			else
				log.info "valid Entry, Hence copy to master"
				ingest_to_master_csv(row,csv_input1,log)
			end	
		end	
	end

	CSV.foreach(csv_input1) do |row|
		begin
			log.info "#{$serv_name} Shows Main::Iteration: #{iterations}"
			if iterations == 0
				iterations += 1
				next
			end	
		puts "Iteration: #{iterations}"
		iterations = iterations +1			

		$arr_prog_ids = Array.new
		$state = nil
		scraped_date = row[0]
		log.info "#{$serv_name} Shows Main::scraped date got from csv: #{scraped_date}"

		category = row[1]
		log.info "#{$serv_name} Shows Main::category got from csv: #{category}"

		series_name = row[2]
		log.info "#{$serv_name} Shows Main::show got from csv: #{series_name}"

		#Get release year
		release_year = row[3]
		release_year = release_year.to_i
		log.info "#{$serv_name} Shows Main::release_year got from csv: #{release_year}"
		

		#Get release year
		season_number = row[4]
		log.info "#{$serv_name} Shows Main::season_number got from csv: #{season_number}"

		episode_number = row[5]
		log.info "#{$serv_name} Shows Main::episode_number got from csv: #{episode_number}"

		episode_title = row[6]
		log.info "#{$serv_name} Shows Main::episode_title got from csv: #{episode_title}"

		raw_launch_ids = row[7]
		#launch_ids_from_csv = extract_launchids_from_csv(raw_launch_ids,log)
		launch_ids_from_csv = eval(raw_launch_ids)
		log.info "#{$serv_name} Shows Main::launch_ids_from_csv got from csv: #{launch_ids_from_csv}"

		status = row[8]
		log.info "status: #{status}"
		all_vids_categorised_cloud = {}
		$error_with_service_count = 0 
		$error_with_service = Array.new
		$hulu_vids_cloud = Array.new
		$vudu_vids_cloud = Array.new
		
		if status == nil or status.include?"FAIL"
			prog_id = get_episode_id(series_name,release_year,season_number,episode_number,episode_title,log)
			log.info "#{$serv_name} Shows Main::Episode Id obtained: #{prog_id}"
			if prog_id == "Series got mapped but Episode Title didn't matched" or prog_id == "series didn't mapped" or prog_id == "Empty search results" or prog_id == "release year and airdate are null for season 1 episode 1" or prog_id == "series didn't mapped as release year of series,S1E1,airdate of S1E1 didn't mapped with input release year" or prog_id == "release year and airdate are null for season 1 episode 1 of all episodes API" or prog_id == "Series got mapped but All episodes api is Empty" or prog_id == "wip" or prog_id == "None of the series titles matched"
			#if prog_id == nil
				$state = prog_id
				log.info "#{$serv_name} Shows Main:: No program id returned, Hence checking dumps for metadata info"
				if primary_source == "Rovi"
					# query_dumps_for_episode_rovi_primary(client,series_name,release_year,season_number,episode_number,episode_title,launch_ids_from_csv,todays_date,scraped_date,raw_launch_ids,category,all_vids_categorised_cloud,log)
					$arr_prog_ids.push([scraped_date,category,series_name,release_year,season_number,episode_number,episode_title,raw_launch_ids,"#{$state}:FAIL","NA","NA",todays_date])
				end
				log.info "Final result for the episode: #{$arr_prog_ids[0]}"
				ingest_to_master_csv($arr_prog_ids[0],csv_output,log)
			else
			$state = "Prg_id obtained in search"	
			$avail_on_cloud_cnt += 1
			
			
			  #from given prog_id get all the ott links
			  $ott_links_from_cloud = get_all_ottlinks_from_cloud(prog_id,log)
			  #Extract all videos from cloud 
			  $rovi_vids_cloud = $ott_links_from_cloud["Rovi Videos"]
			  $gn_ott_vids_cloud = $ott_links_from_cloud["Gracenote Videos"]
			  $hulu_vids_cloud = $ott_links_from_cloud["Hulu Videos"]
			  $vudu_vids_cloud = $ott_links_from_cloud["Vudu Videos"]
			  $crawler_vids_cloud = $ott_links_from_cloud["Crawler Videos"]

			  $all_vids_cloud = $ott_links_from_cloud["All Videos"]
			  all_vids_categorised_cloud = categorise_ozone_launch_ids_based_on_service($all_vids_cloud,"SE",log)
			  log.info "Shows Main:: all_vids_categorised_cloud: #{all_vids_categorised_cloud}"

			  validate_cloud_with_external_portal_links(client,series_name,release_year,season_number,episode_number,episode_title,prog_id,launch_ids_from_csv,todays_date,scraped_date,raw_launch_ids,category,all_vids_categorised_cloud,log)
			  log.info "Final result for the episode: #{$arr_prog_ids[0]}"
			  ingest_to_master_csv($arr_prog_ids[0],csv_output,log)
			end

		else
			$arr_prog_ids.push(row)
			ingest_to_master_csv($arr_prog_ids[0],csv_output,log)
		end

			log.info "*******************************************************************************************"
			log.info "*******************************************************************************************"
		rescue Exception => exp_err
			log.info "#{$serv_name} Shows Main::Caught exception for series: #{series_name}"
			log.info "Exception: #{exp_err}"
			log.info "#{$serv_name} Shows Main::Backtrace: #{exp_err.backtrace}"
			$arr_prog_ids.push(row)
			ingest_to_master_csv($arr_prog_ids[0],csv_output,log)
		ensure
		   # reset_iteration_variables()
		end
	end




	# log.info "Array of program id is: #{$arr_prog_ids}"
	# arr_len = $arr_prog_ids.length
	# csv_final = Dir["/home/manju/Documents/Latest_validation/Side_reel_Validation/final_csv/"][0]
	# temp = csv_final.dup
	# #temp.sub!(".csv", "")
 #    csv_output = temp + "Master_overall_summary.csv"

 #    CSV.open(csv_output, "w+") do |head|
 #    	head << ["Scraped Date","Series Name","Release_Year","Season Number","Episode Number","Episode Title","Links","Result","Error","Date Validated"]
 #    end
 #    for i in 0..arr_len-1
 #    	CSV.open(csv_output, "a+") do |csv|
 #            #puts "#{arr_prog_ids[i].class}"
 #            csv << $arr_prog_ids[i]
 #        end
 #    end


 #    overall_passes = $avail_on_cloud_cnt - $overall_failures


	# puts "#{$avail_on_cloud_cnt} out of #{iterations} shows are available on ozone<br><br>"
	# log.info "#{$serv_name} Shows Main::#{$avail_on_cloud_cnt} out of #{iterations} shows are available in ozone"

	# puts "#{overall_passes} out of these #{$avail_on_cloud_cnt} shows have all episodes in cloud with perfectly ingested links<br><br>"
	# log.info "#{$serv_name} Shows Main::#{overall_passes} out of these #{$avail_on_cloud_cnt} shows have all episodes in cloud with perfectly ingested links"

	# puts "#{$overall_failures} out of these #{$avail_on_cloud_cnt} shows have ingestion failures/incorrect links<br><br>"
	# log.info "#{$serv_name} Shows Main::#{$overall_failures} out of these #{$avail_on_cloud_cnt} shows have ingestion failures/incorrect links"

	# if $not_avail_on_ozone_and_rovi_but_avail_on_gn_cnt != 0
	#   puts "#{$not_avail_on_ozone_and_rovi_but_avail_on_gn_cnt} out of the total #{iterations} shows are not available on ozone, but available in Gracenote Dump<br><br>"
 #      log.info "#{$serv_name} Shows Main::#{$not_avail_on_ozone_and_rovi_but_avail_on_gn_cnt} out of the total#{iterations} shows are not available on ozone, but available in Gracenote Dump"
 #    end

 #    if $not_avail_on_rovi_and_gn_cnt != 0
	#   puts "#{$not_avail_on_rovi_and_gn_cnt} out of the total #{iterations} shows are not available on rovi or gracenote dumps<br><br>"
 #      log.info "#{$serv_name} Shows Main::#{$not_avail_on_rovi_and_gn_cnt} out of the total #{iterations} shows are not available on rovi or gracenote dumps"
	# end

	# puts "#{$avail_on_rovi_cnt} out of #{iterations} amazon recently added  movies are available in rovi dump<br>"
	# log.info "#{$serv_name} Award Winning Movies Main::#{$avail_on_rovi_cnt} out of #{iterations} amazon recently added  movies are available in rovi dump"

	# puts "#{$rovi_ingest_success_cnt} out of this #{$avail_on_rovi_cnt} have Rovi Ingestion-PASS<br>"
	# log.info "#{$serv_name} Award Winning Movies Main::#{$rovi_ingest_success_cnt} out of this #{$avail_on_rovi_cnt} have Rovi Ingestion-PASS"

	# puts "#{$rovi_ingest_failures_cnt} out of this #{$avail_on_rovi_cnt} have Rovi Ingestion-FAIL<br><br>"
	# log.info "#{$serv_name} Award Winning Movies Main::#{$rovi_ingest_failures_cnt} out of this #{$avail_on_rovi_cnt} have Rovi Ingestion-FAIL"
	
	# puts "#{$avail_on_gracenote_after_mapping_cnt} out of #{iterations} amazon recently added  movies are available in gracenote dump<br>"
	# log.info "#{$serv_name} Award Winning Movies Main::#{$avail_on_gracenote_after_mapping_cnt} out of #{iterations} amazon recently added  movies are available in gracenote dump"

	# #puts "#{avail_on_gracenote_and_unable_to_map_cnt} out of this #{avail_on_gracenote_after_mapping_cnt} could not be mapped, hence ingestion could'nt be checked<br>"
	# log.info "#{$serv_name} Award Winning Movies Main::#{$avail_on_gracenote_and_unable_to_map_cnt} out of this #{$avail_on_gracenote_after_mapping_cnt} could not be mapped, hence ingestion could'nt be checked"

	# puts "#{$gn_ingest_success_cnt} out of the remaining #{$real_gn_ingestion_cnt} have Gracenote Ingestion-PASS<br>"
	# log.info "#{$serv_name} Award Winning Movies Main::#{$gn_ingest_success_cnt} out of the remaining #{$real_gn_ingestion_cnt} have Gracenote Ingestion-PASS"

	# puts "#{$gn_ingest_failures_cnt} out of the remaining #{$real_gn_ingestion_cnt} have Gracenote Ingestion-FAIL<br>"
	# log.info "#{$serv_name} Award Winning Movies Main::#{$gn_ingest_failures_cnt} out of the remaining #{$real_gn_ingestion_cnt} have Gracenote Ingestion-FAIL"

end
end
