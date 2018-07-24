module MiscellaneousFunctions

  API_KEY = "id8"
  SECRET_KEY = "0c11TDcc0c11TDccgUSaCN66L0L2d4M9"
  BASE_URL = "http://ottlinks.veveo.net/ott/get_availability"
  PAGE_SIZE = 1000
  THREAD_SIZE = 10


  def get_ott_video_url(rovi_id: nil, type: 'download', data_id: nil)
  	params = {}
  	params['rovi_id_version'] = '2.0'
  	params['_version'] = 0
  	params['api_user_id'] = API_KEY
  	keys = []
  	refreshed_at = Time.now.to_i
  	type_of_dump = nil
  	
    params['rovi_id'] = rovi_id
    params['type'] = type
    params['data_id'] = data_id
    params['timestamp'] = Time.now.utc.strftime('%Y%m%dT%H%M%SZ')
    params['authentication'] = nil
    keys = params.keys.sort
    s = ''
    keys.each {|k| s += "#{k}#{params[k]}" if params[k]}
    hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), SECRET_KEY, s)
    params['authentication'] = "hmac_sha256_#{hmac}"
    urlencoded_params = (params.collect {|k,v| "#{k}=#{v}" if v}).compact.join('&')
    "#{BASE_URL}?#{urlencoded_params}"
  end

  def get_latest_rovi_ott_dump_date(client,log)
    dump_date = nil
    coll_dump_date = client[:rovi_ott_links_dump_date]
    query_dump_date = coll_dump_date.find({},{"sort" =>{ "$natural" => -1}}).limit(1)

    query_dump_date.each do |dt|
      du_dt = dt.to_json
      #puts du_dt
      pars_dt = JSON.parse(du_dt)
      date_str = pars_dt['ott_dump_date']
      dump_date = Date.parse date_str
      # puts dump_date.class
      # puts "Last added dump date is: #{dump_date}<br>"
      log.info "Last added dump date is: #{dump_date}<br>"
    end
    dump_date
  end

  def query_gracenote_dump_for_movie(movie_name,release_year,client,arr_prog_ids,log)
    gn_mongo = nil
    dump_date = Date.today - 1
    gn_coll = client[:GN_ott_episodes_ott]
    cnt = gn_coll.count({"title" => /#{movie_name}/i,"release_year" => release_year,"show_type" => "MO","gn_dump_date" => dump_date})
    if cnt == 0
      log.info "Can't find movie: #{movie_name} in GN dump with release_year: #{release_year}"   
      #arr_prog_ids.push([movie_name,release_year,"Movie not available on Rovi","Movie not available on Gracenote"]) 
      $not_avail_on_rovi_and_gn_cnt = $not_avail_on_rovi_and_gn_cnt + 1  
      log.info "$not_avail_on_rovi_and_gn_cnt: #{$not_avail_on_rovi_and_gn_cnt}" 
    else
      gn_coll.find({"title" => /#{movie_name}/i,"release_year" => release_year,"show_type" => "MO","gn_dump_date" => dump_date}).limit(1).each do |doc|
        doc_json = doc.to_json
     
        parsed_doc = JSON.parse(doc_json)
        log.info "Resp from GN dump: #{parsed_doc}"
        gn_links_from_mongo = parsed_doc["Videos"]
        if !gn_links_from_mongo.empty?
          services_from_mongo = gn_links_from_mongo.keys

          log.info "Filter out the GN Mongo response to contain only supported services"
          services_from_mongo.each do |key|
            if key.downcase == serv_name
              next
            else
              gn_links_from_mongo.delete(key)
            end
          end

          log.info "gn_links_from_mongo for movie-#{movie_name}: #{gn_links_from_mongo}"
          gn_links_from_mongo_final = gn_links_from_mongo.values
          gn_mongo = make_one_single_array(gn_links_from_mongo_final)
          log.info "Main: gn cloud for movie-#{movie_name}: #{gn_mongo}"
          $not_avail_on_rovi_but_avail_on_gn_cnt = $not_avail_on_rovi_but_avail_on_gn_cnt + 1 
          log.info "not_avail_on_rovi_but_avail_on_gn_cnt: #{$not_avail_on_rovi_but_avail_on_gn_cnt}" 
        else
          gn_mongo = []
          log.info "Main: GN Metadata available, but no valid gn links for program in dump"
        end
        #arr_prog_ids.push([movie_name,release_year,"Movie not available on Rovi","But movie available on GN.","GN links: #{gn_mongo}"]) 
      end
    end
    gn_mongo
  end

  def query_dumps_for_movie(movie_name,release_year,client,arr_prog_ids,log)
    log.info "Misc Functions::query_dumps_for_movie, first going to check if movie available in Rovi Metadata Dump." 
    rovi_metadata_coll = client[:program_general]
    cnt = rovi_metadata_coll.count({"release_year" => release_year,"show_type" => "MO",:$or => [{"long title": /#{movie_name}/i},{"original title": /#{movie_name}/i},{"alias title": /#{movie_name}/i}]})
    #cnt = rovi_metadata_coll.count({"long_title" => /#{movie_name}/i,"release_year" => release_year,"show_type" => "MO"})
    if cnt == 0
      log.info "Can't find movie: #{movie_name} in Rovi Metadata dump with release_year: #{release_year},proceed to check in gracenote dump"   
      gn_ott_links_mongo = query_gracenote_dump_for_movie(movie_name,release_year,client,arr_prog_ids,log)
      if gn_ott_links_mongo.nil?
        log.info "if: Movie-#{movie_name} not available on rovi metadata dump and gracenote dump"
        arr_prog_ids.push([movie_name,release_year,"","Movie not available on Rovi Metadata Dump","","Movie not available on Gracenote dump",""])
      elsif gn_ott_links_mongo.empty? 
        log.info "elsif: Movie-#{movie_name} not available on rovi metadata dump but available on gracenote dump.No ott links of primary services supported by caavo on GN dump"
        arr_prog_ids.push([movie_name,release_year,"","Movie not available on Rovi Metadata Dump","","Movie available on Gracenote dump","No valid Primary OTT links on Gracenote Dump"])
      else
        log.info "else: Movie-#{movie_name} not available on rovi metadata dump but available on  gracenote dump,with valid links"
        arr_prog_ids.push([movie_name,release_year,"","Movie not available on Rovi Metadata Dump","","Movie available on Gracenote dump","Valid Primary OTT links available on Gracenote Dump"])    
      end
      # $not_avail_on_rovi_and_gn_cnt = $not_avail_on_rovi_and_gn_cnt + 1  
      # #puts "not_avail_on_rovi_and_gn_cnt: #{not_avail_on_rovi_and_gn_cnt}"  
      # log.info "$not_avail_on_rovi_and_gn_cnt: #{$not_avail_on_rovi_and_gn_cnt}" 
    else
      rovi_metadata_coll.find({"release_year" => release_year,"show_type" => "MO",:$or => [{"long title": /#{movie_name}/i},{"original title": /#{movie_name}/i},{"alias title": /#{movie_name}/i}]}).limit(1).each do |doc|
        log.info "Found a match in Rovi Metadata dump,proceed to check if atleast one Rovi/GN link is available OTT Link"
        doc_json = doc.to_json
        prog_id = get_rovi_id_from_query(doc_json,log)
        dump_date = get_latest_rovi_ott_dump_date(client,log)
        rovi_ott_coll = client[:rovi_ott_links]
        #Get Rovi OTT Links for movie
        rovi_ott_links = get_ott_links_from_mongo_db(rovi_ott_coll,prog_id,dump_date,log)
        gn_ott_links  = query_gracenote_dump_for_movie(movie_name,release_year,client,arr_prog_ids,log)
        if !rovi_ott_links.nil? and !gn_ott_links.nil?
          log.info "IF: rovi ott links and gn ott links not nil!!!"
          if rovi_ott_links.empty? and gn_ott_links.empty?
            log.info "if: Movie-#{movie_name} available on rovi metadata dump,rovi ott dump & gn dump, but no valid primary ott links on rovi ott dump and gn dump"
            arr_prog_ids.push([movie_name,release_year,"","Movie available on Rovi Metadata Dump","Movie available in Rovi OTT dump","No Valid Primary OTT links on Rovi OTT Dump","Movie available on Gracenote dump","No valid Primary OTT links on Gracenote Dump"])
          elsif gn_ott_links.empty?
            log.info "elsif: Movie-#{movie_name} available on rovi metadata dump,rovi ott dump & gn dump, valid primary ott links available on rovi ott dump but no valid primary ott links on gn dump"
            arr_prog_ids.push([movie_name,release_year,"","Movie available on Rovi Metadata Dump","Movie available in Rovi OTT dump","Valid Primary OTT links available on Rovi OTT Dump","Movie available on Gracenote dump","No valid Primary OTT links on Gracenote Dump"])
          elsif rovi_ott_links.empty?
            log.info "elsif: Movie-#{movie_name} available on rovi metadata dump,rovi ott dump & gn dump,no valid primary ott links available on rovi ott dump, but valid primary ott links on gn dump"
            arr_prog_ids.push([movie_name,release_year,"","Movie available on Rovi Metadata Dump","Movie available in Rovi OTT dump","No Valid Primary OTT links on Rovi OTT Dump","Movie available on Gracenote dump","Valid Primary OTT links available on Gracenote Dump"])
          else
            log.info "else: Movie-#{movie_name} available on rovi metadata dump,rovi ott dump & gn dump, valid primary ott links on both rovi and gn dump"
            arr_prog_ids.push([movie_name,release_year,"","Movie available on Rovi Metadata Dump","Movie available in Rovi OTT dump","Valid Primary OTT links available on Rovi OTT Dump","Movie available on Gracenote dump","Valid Primary OTT links available on Gracenote Dump"])
          end
        elsif !rovi_ott_links.nil?
          log.info "ELSIF: rovi ott links not nil!!!"
          if rovi_ott_links.empty?
            log.info "if: Movie-#{movie_name} available on rovi metadata dump & rovi ott dump but not gn dump,  no valid primary ott links on rovi dump"
            arr_prog_ids.push([movie_name,release_year,"","Movie available on Rovi Metadata Dump","Movie available in Rovi OTT dump","No Valid Primary OTT links on Rovi OTT Dump","Movie not available on Gracenote dump",""])
          else
            log.info "if: Movie-#{movie_name} available on rovi metadata dump & rovi ott dump but not gn dump, valid primary ott links avail on rovi dump"
            arr_prog_ids.push([movie_name,release_year,"","Movie available on Rovi Metadata Dump","Movie available in Rovi OTT dump","Valid Primary OTT links on Rovi OTT Dump","Movie not available on Gracenote dump",""])
          end
        elsif !gn_ott_links.nil? 
          log.info "ELSIF: GN ott links not nil!!!"
          if gn_ott_links.empty?
            log.info "if: Movie-#{movie_name} available on rovi metadata dump & gn ott dump but not robi ott dump,  no valid primary ott links on gn dump"
            arr_prog_ids.push([movie_name,release_year,"","Movie available on Rovi Metadata Dump","Movie not available in Rovi OTT dump","","Movie available on Gracenote dump","No valid Primary OTT links on Gracenote Dump"])
          else
            log.info "else: Movie-#{movie_name} available on rovi metadata dump & gn ott dump but not robi dump, valid primary ott links avail on gn dump"
            arr_prog_ids.push([movie_name,release_year,"","Movie available on Rovi Metadata Dump","Movie not available in Rovi OTT dump","","Movie available on Gracenote dump","Valid Primary OTT links available on Gracenote Dump"])
          end
        else
          log.info "ELSE: both rovi and gn ott links nil"
          arr_prog_ids.push([movie_name,release_year,"","Movie available on Rovi Metadata Dump","Movie not available in Rovi OTT dump","","Movie not available on Gracenote dump",""])
        end
      end
    end
  end

  def get_rovi_id_from_query(doc_returned,log)
    log.info "Value from mongo: #{doc_returned} before processing"
    doc_json = doc_returned.to_json
    parsed_doc = JSON.parse(doc_json)
    #puts parsed_doc
    log.info "Resp from Rovi ott dump: #{parsed_doc}"
    #array_elem.push(parsed_doc)
    prog_id = parsed_doc["program id"]
    prog_id
  end

  def check_rovi_ingestion_status(client,prog_id,prog_name,rovi_vids_cloud,log)
    $log.info "Misc functions::check_rovi_ingestion_status"
    rovi_vids_mongo = get_ott_links_from_mongo_db(client,prog_id,log)
    log.info "Rovi vids from mongo: #{rovi_vids_mongo}"
    diff1 = rovi_vids_mongo - rovi_vids_cloud
    log.info "Few Mongo vids are missing in cloud :#{diff1}"
    diff2 = rovi_vids_cloud - rovi_vids_mongo
    log.info "Extra vids in cloud which were not there in rovi dump :#{diff2}"
    if diff1.empty? and diff2.empty?
      log.info "Rovi Ingestion Status for program-#{prog_name}: PASS"
      $rovi_ingestion_status = "PASS"
      $rovi_ingest_success_cnt = $rovi_ingest_success_cnt + 1
      log.info "Rovi Ingesion-PASS count: #{$rovi_ingest_success_cnt}"
    else
      log.info "Rovi Ingestion Status for program-#{prog_name}: FAIL"
      $rovi_ingestion_status = "FAIL"
      $rovi_ingest_failures_cnt = $rovi_ingest_failures_cnt + 1
      log.info "Rovi Ingesion-FAIL count: #{$rovi_ingest_failures_cnt}"
      $rovi_ingestion_overall_failure = true if $rovi_overall_ingestion_status_updated == false
      $rovi_overall_ingestion_status_updated = true
    end
    #arr_prog_ids.push([prog_name,release_year,prog_id,"Rovi Video Links available on cloud",rovi_ingestion_status])
    #$avail_on_rovi_cnt = $avail_on_rovi_cnt + 1
    #log.info "avail_on_rovi_cnt: #{$avail_on_rovi_cnt}"
  end

  def check_gn_ingestion_status(client,movie_name,release_year,gn_vids_cloud,log)
    $log.info "Misc functions::check_gn_ingestion_status"
    dump_date = Date.today - 1
    $avail_on_gracenote_after_mapping_cnt = $avail_on_gracenote_after_mapping_cnt + 1
    log.info "avail_on_gracenote_after_mapping_cnt: #{$avail_on_gracenote_after_mapping_cnt}"
    log.info "gn_vids_cloud: #{gn_vids_cloud}"
    gn_vids_cloud_categorised = categorise_launch_ids_based_on_service($gn_ott_vids_cloud,"MO",log)
    gn_coll = client[:GN_ott_episodes_ott]
    cnt = gn_coll.count({"title" => /#{movie_name}/i,"release_year" => release_year,"show_type" => "MO","gn_dump_date" => dump_date})
    if cnt == 0
      log.info "Can't find movie: #{movie_name} in GN dump with release_year: #{release_year}"   
      #arr_prog_ids.push([movie_name,release_year,"GN Video Links available in cloud","Unable to map with Gracenote dump,hence cannot check ingestion status"]) 
      $avail_on_gracenote_and_unable_to_map_cnt = $avail_on_gracenote_and_unable_to_map_cnt + 1    
      log.info "avail_on_gracenote_and_unable_to_map_cnt: #{$avail_on_gracenote_and_unable_to_map_cnt}"
    else
      gn_coll.find({"title" => /#{movie_name}/i,"release_year" => release_year,"show_type" => "MO","gn_dump_date" => dump_date}).limit(1).each do |doc|
        gn_vids_mongo = nil
        all_links_cloud = nil
        hash_of_gn_links = {}
        categorised_hash_of_gn_links = {}
        doc_json = doc.to_json
        log.info "Value from mongo: #{doc_json} before processing"
        parsed_doc = JSON.parse(doc_json)
        log.info "Resp from GN dump: #{parsed_doc}"
        gn_links_from_mongo = parsed_doc["Videos"]
        if !gn_links_from_mongo.empty?
          log.info "gn_links_from_mongo for movie-#{movie_name}: #{gn_links_from_mongo}"
          services_from_mongo = gn_links_from_mongo.keys
          log.info "Filter out the GN Mongo response to contain only primary services"

          services_from_mongo.each do |key|
            new_key = nil
            if $serv_name.include? key.downcase || key.downcase == "hbo"
              if  key.downcase == "hulu" and !$hulu_vids_cloud.empty?
                log.info "Hulu links fetched from dump, skip it during the validation-don't add to array"
                gn_links_from_mongo.delete(key)
              elsif key.downcase == "vudu" and !$vudu_vids_cloud.empty?
                log.info "Vudu links fetched from dump, skip it during the validation-don't add to array"
                gn_links_from_mongo.delete(key)
              else
                new_key = key.downcase
                hash_of_gn_links[new_key] = gn_links_from_mongo[key]
              end
              next
            else
              if key.downcase.include? "itunes"
                new_key = "itunes"
                hash_of_gn_links[new_key] = gn_links_from_mongo[key]
                next 
              elsif key.downcase.include? "netflix"
                new_key = "netflixusa"
                hash_of_gn_links[new_key] = gn_links_from_mongo[key]
                next
              else
                log.info "#{key} not part of primary services supported by Caavo"
                gn_links_from_mongo.delete(key)
              end
            end
          end
          log.info "hash_of_gn_links:#{hash_of_gn_links}"
          categorised_hash_of_gn_links = get_categorised_gn_launch_ids(hash_of_gn_links,"MO",log)
          gn_links_from_mongo_final = categorised_hash_of_gn_links.values
          log.info "gn_links_from_mongo_final: #{gn_links_from_mongo_final}"
          gn_vids_mongo = make_one_single_array(gn_links_from_mongo_final)
          log.info "gn_vids_mongo: #{gn_vids_mongo}"
          all_links_from_cloud = $all_vids_categorised_cloud.values
          log.info "all_links_from_cloud: #{all_links_from_cloud}"
          all_links_cloud = make_one_single_array(all_links_from_cloud)
          log.info "all_links_cloud: #{all_links_cloud}"
        else
          gn_vids_mongo = []
          log.info "check_rovi_ingestion_status: GN Metadata available, but no valid gn links for program in dump"
        end

        log.info "check_rovi_ingestion_status: gn_vids_mongo for movie-#{movie_name}: #{gn_vids_mongo}"
        log.info "gn_vids_cloud: #{gn_vids_cloud}"

        gn_links_from_cloud = gn_vids_cloud_categorised.values
        log.info "gn_links_from_cloud: #{gn_links_from_cloud}"
        all_gn_links_cloud = make_one_single_array(gn_links_from_cloud)
        log.info "all_gn_links_cloud: #{all_gn_links_cloud}"

        diff1 = gn_vids_mongo - all_links_cloud
        log.info "Few GN Mongo vids are missing in cloud :#{diff1}"
        diff2 = all_gn_links_cloud - gn_vids_mongo
        log.info "Extra GN vids in cloud which were not there in rovi dump :#{diff2}"
        if diff1.empty? and diff2.empty?
        #if diff1.empty?
          log.info "GN Ingestion Status for movie-#{movie_name}: PASS"
          $gn_ingestion_status = "GN Ingestion Status: PASS"
          $gn_ingest_success_cnt = $gn_ingest_success_cnt + 1
          log.info "GN Ingestion Status: PASS count: #{$gn_ingest_success_cnt}"
        else
          log.info "GN Ingestion Status for movie-#{movie_name}: FAIL"
          $gn_ingestion_status = "GN Ingestion Status: FAIL"
          $gn_ingest_failures_cnt = $gn_ingest_failures_cnt + 1
          log.info "GN Ingestion Status: FAIL count: #{$gn_ingest_failures_cnt}"
        end
        #arr_prog_ids.push([movie_name,release_year,"GN Video Links available in cloud",gn_ingestion_status]) 
      end
    end
    $real_gn_ingestion_cnt = $avail_on_gracenote_after_mapping_cnt - $avail_on_gracenote_and_unable_to_map_cnt
  end

  def validate_rovi_and_gn_links_in_all_series_episodes(client,series_name,release_year,prog_id,no_of_seasons,log,season_Start_cnt,last_episode_cnt)
    log.info "Misc Functions::validate_individual_service_links_in_all_series_episodes"
    $episodes_without_ott_links_cnt = 0
    $episodes_cnt = 0
    $episodes_with_ott_errors_cnt = 0
    $episodes_with_ott_links_from_crawler = 0
    $rovi_ingest_success_cnt = 0
    $rovi_ingest_failures_cnt = 0
    $episodes_with_rovi_links_ingested = 0
    $episodes_with_gn_links_ingested = 0
    $gn_ingest_failures_cnt = 0
    $gn_ingest_success_cnt = 0
    $incorrect_mapping_cnt = 0
    $avail_on_gracenote_and_unable_to_map_cnt = 0
    $GN_Series_ID = nil
    $count = 0
    $last_episode_obtained = 0
    episode_title,ser_name,seas_no,episode_no,ep_prog_id = nil
    episode_list = populate_episodes_in_array(series_name,prog_id,no_of_seasons,log,season_Start_cnt,last_episode_cnt)
    len = episode_list.length
    for i in 0..len-1
      begin
        log.info "For loop: #{i}th episode object"
        $gn_ingestion_status = nil
        $rovi_ingestion_status = nil
        log.info "Object: #{episode_list[i]}"
        $episodes_cnt += 1
        ott_links_from_cloud_for_episode = episode_list[i][:videos]
        episode_title = episode_list[i][:original_episode_title]
        log.info "Episode title: #{episode_title}"
        ser_name = episode_list[i][:long_title]
        log.info "Series: #{ser_name}"
        seas_no = episode_list[i][:episode_season_number]
        log.info "Season no: #{seas_no}"
        episode_no = episode_list[i][:episode_season_sequence]
        log.info "Episode no: #{episode_no}"
        ep_prog_id = episode_list[i][:id]
        log.info "Episode prog id: #{ep_prog_id}"

        episode_videos_json_raw = episode_list[i][:videos]
        log.info "episode_videos_json_raw: #{episode_videos_json_raw}"
        #episode_videos_json = episode_videos_json_raw.to_json
        #log.info "parsed json : #{episode_videos_json}"
        $ott_links_cloud_complete = arrange_ottlinks_from_cloud(episode_videos_json_raw,log)

       # $ott_links_cloud_complete = get_ott_links_from_cloud(ep_prog_id,log)
        $rovi_vids_cloud = $ott_links_cloud_complete["Rovi Videos"]
        $gn_ott_vids_cloud = $ott_links_cloud_complete["Gracenote Videos"]
        $hulu_vids_cloud = $ott_links_cloud_complete["Hulu Videos"]
        $vudu_vids_cloud = $ott_links_cloud_complete["Vudu Videos"]
        $crawler_vids_cloud = $ott_links_cloud_complete["Crawler Videos"]
        if !$rovi_vids_cloud.empty?
          log.info "Rovi vids available, increase count"
          $episodes_with_rovi_links_ingested += 1
        end
        if !$gn_ott_vids_cloud.empty?
          log.info "GN vids available, increase count"
          $episodes_with_gn_links_ingested += 1
        end
        if !$crawler_vids_cloud.empty?
          log.info "Crawler vids available, increase count"
          $episodes_with_ott_links_from_crawler += 1
        end
        $all_vids_cloud = $ott_links_cloud_complete["All Videos"]
        $all_vids_categorised_cloud = categorise_ozone_launch_ids_based_on_service($all_vids_cloud,"SE",log)
        validate_rovi_and_gn_link_ingestion_series_episode(client,ep_prog_id,ser_name,release_year,seas_no,episode_no,episode_title,log)
      rescue Exception => exp_err
        log.info "Misc Functions::validate_individual_service_links_in_all_series_episodes - Caught exception for series: #{series_name},season no: #{seas_no},episode_no: #{episode_no},pr"
        log.info "Exception: #{exp_err}"
        log.info "#{$serv_name} Shows Main::Backtrace: #{exp_err.backtrace}"
        $arr_episode_prog_ids.push([ser_name,seas_no,episode_no,"Exception while comparing OTT links with Rovi and GN dumps"])
        next
      end
    end

     for x in 0..$count-1
      #temporary code to handle missing episodes
      $episodes_cnt += 1
      $episodes_with_ott_errors_cnt += 1
      $episodes_without_ott_links_cnt +=1
      extra_episode_no = ($last_episode_obtained+ x + 1).to_s
      $arr_episode_prog_ids.push([series_name,no_of_seasons,extra_episode_no,"NA","NA","NA","NA","NA","FAIL"])

    end


    compute_overall_summary_of_series(ser_name,release_year,prog_id,log)
  end

  def populate_episodes_in_array(series_name,prog_id,no_of_seasons,log,season_Start_cnt,last_episode_cnt)
    log.info "Misc functions::populate_episodes_in_array"
    complete_episode_list = Array.new    
    episodes_api = "/programs/#{prog_id}/episodes"
    no_of_seasons = no_of_seasons.to_i
    last_sn_last_eps = last_episode_cnt.to_i
    for i in season_Start_cnt..no_of_seasons
      log.info "Iteration: #{i}"
      new_api = episodes_api + "?season_number=" + i.to_s + "&ott=true&service=" + $serv_name
      get new_api
      response_code_validation("get",new_api)

      if i == no_of_seasons and json_body.length < last_sn_last_eps
        $count = last_sn_last_eps - json_body.length
        $last_episode_obtained = json_body.length
      end

      complete_episode_list = complete_episode_list + json_body
      log.info "Complete episode list: #{complete_episode_list}"
    end
    complete_episode_list
  end

  def validate_rovi_and_gn_link_ingestion_series_episode(client,prog_id,series_name,release_year,season_no,episode_no,episode_title,log)
    log.info "Ozone_Api_Specific_Functions::validate_rovi_and_gn_link_ingestion_series_episode"
    check_rovi_ingestion_status(client,prog_id,series_name,$rovi_vids_cloud,log)
    check_gn_ingestion_status_episode(client,series_name,release_year,season_no,episode_no,episode_title,prog_id,log)
    iterate_ott_errors_cnt_based_on_ingestion_status(log)

    if !$rovi_vids_cloud.empty? and !$gn_ott_vids_cloud.empty?
      log.info "validate_rovi_and_gn_link_ingestin::Non-empty rovi and gracenote vids"
      if $gn_ingestion_status.nil?
        log.info "GN ingestion status -nil, unable to find match in gn dump"
        $avail_on_gracenote_and_unable_to_map_cnt += 1
        log.info "Miscellaneous Functions::avail_on_gracenote_and_unable_to_map_cnt: #{$avail_on_gracenote_and_unable_to_map_cnt}"
        $arr_episode_prog_ids.push([series_name,season_no,episode_no,prog_id,$GN_Episode_ID,"Yes",$rovi_ingestion_status,"Yes","Could not find in GN dump, Hence Unable to Map"])
      else
        log.info "GN ingestion status - not nil, found match in gn dump, update accordingly"
        $arr_episode_prog_ids.push([series_name,season_no,episode_no,prog_id,$GN_Episode_ID,"Yes",$rovi_ingestion_status,"Yes",$gn_ingestion_status])
      end
    elsif !$rovi_vids_cloud.empty?
      log.info "validate_rovi_and_gn_link_ingestin::Elsif non-empty rovi vids"
      if $gn_ingestion_status.nil?
        log.info "GN ingestion status -nil, unable to find match in gn dump"
        $avail_on_gracenote_and_unable_to_map_cnt += 1
        log.info "Miscellaneous Functions::avail_on_gracenote_and_unable_to_map_cnt: #{$avail_on_gracenote_and_unable_to_map_cnt}"
        $arr_episode_prog_ids.push([series_name,season_no,episode_no,prog_id,$GN_Episode_ID,"Yes",$rovi_ingestion_status,"No","Not in GN dump,Not in Cloud, Nothing to map"])
      else
        log.info "GN ingestion status - not nil, found match in gn dump, update accordingly"
        $arr_episode_prog_ids.push([series_name,season_no,episode_no,prog_id,$GN_Episode_ID,"Yes",$rovi_ingestion_status,"No",$gn_ingestion_status])
      end
    elsif !$gn_ott_vids_cloud.empty?
      log.info "validate_rovi_and_gn_link_ingestin::Else non-empty gn vids"
      if $gn_ingestion_status.nil?
        log.info "GN ingestion status -nil, unable to find match in gn dump"
        $avail_on_gracenote_and_unable_to_map_cnt += 1
        log.info "Miscellaneous Functions::avail_on_gracenote_and_unable_to_map_cnt: #{$avail_on_gracenote_and_unable_to_map_cnt}"
        $arr_episode_prog_ids.push([series_name,season_no,episode_no,prog_id,$GN_Episode_ID,"No",$rovi_ingestion_status,"Yes","Could not find in GN dump, but found in cloud, Unable to map"])
      else
        log.info "GN ingestion status - not nil, found match in gn dump update accordingly"
        $arr_episode_prog_ids.push([series_name,season_no,episode_no,prog_id,$GN_Episode_ID,"No",$rovi_ingestion_status,"Yes",$gn_ingestion_status])
      end
    else
      log.info "validate_rovi_and_gn_link_ingestin::Else both rovi and gn videos empty in cloud"
      $episodes_without_ott_links_cnt += 1
      #$episodes_with_ott_errors_cnt += 1
      if $gn_ingestion_status.nil?
        log.info "GN ingestion status -nil, unable to find match in gn dump"
        $avail_on_gracenote_and_unable_to_map_cnt += 1
        log.info "Miscellaneous Functions::avail_on_gracenote_and_unable_to_map_cnt: #{$avail_on_gracenote_and_unable_to_map_cnt}"
        $arr_episode_prog_ids.push([series_name,season_no,episode_no,prog_id,$GN_Episode_ID,"No",$rovi_ingestion_status,"No","Could not find in cloud and GN dump, Nothing to map"])
      else
        log.info "GN ingestion status - not nil, found match in gn dump update accordingly"
        $arr_episode_prog_ids.push([series_name,season_no,episode_no,prog_id,$GN_Episode_ID,"No",$rovi_ingestion_status,"No",$gn_ingestion_status])
      end
    end 
  end

  def check_gn_ingestion_status_episode(client,series_name,release_year,season_no,episode_no,episode_title,ep_prog_id,log)
    log.info "Miscellaneous Functions::check_gn_ingestion_status_episode"
    $GN_Episode_ID = nil
    gn_coll = client[:GN_ott_episodes_ott]
    log.info "Miscellaneous Functions::gn_vids_cloud: #{$gn_ott_vids_cloud}"
    gn_vids_cloud_categorised = categorise_launch_ids_based_on_service($gn_ott_vids_cloud,"SE",log)
    dump_date = Date.today - 2
    rel_year = release_year.to_i
    log.info "Querying GN dump with Series name : #{series_name}, Release year :#{rel_year}, Season number : #{season_no}, episode_number: #{episode_no},dump date:#{dump_date}"
    #cnt = gn_coll.count({"title" => /#{series_name}/i,"season_number" => "#{season_no}","episode_number" => "#{episode_no}","episode_title" => "#{episode_title}","gn_dump_date" => dump_date})
    cnt = gn_coll.count({"title" => /^#{series_name}/i,"release_year" => rel_year,"season_number" => "#{season_no}","episode_number" => "#{episode_no}","gn_dump_date" => dump_date})
    if cnt == 0
      log.info "Miscellaneous Functions::Can't find #{series_name}, Se #{season_no}, Ep #{episode_no} in GN dump"
      #$arr_episode_prog_ids.push([series_name,season_no,episode_no,"","GN Video Links are shown in cloud","Unable to map, cannot check ingestion status"])
      if !$gn_ott_vids_cloud.empty?
        log.info "GN links available on cloud, but unable to get results while querying gn dump"
      else
        log.info "GN links empty on cloud and unable to get results while querying gn dump"
        $not_avail_on_gn_cnt += 1
      end

    else
     # gn_coll.find({"title" => /#{series_name}/i,"season_number" => "#{season_no}","episode_number" => "#{episode_no}","episode_title" => "#{episode_title}","gn_dump_date" => dump_date}).limit(1).each do |doc|
      gn_coll.find({"title" => /^#{series_name}/i,"release_year" => rel_year,"season_number" => "#{season_no}","episode_number" => "#{episode_no}","gn_dump_date" => dump_date}).limit(1).each do |doc|
        gn_vids_mongo = nil
        all_links_cloud = nil
        #gn_series_id_updated = false
        hash_of_gn_links = {}
        categorised_hash_of_gn_links = {}
        doc_json = doc.to_json
        log.info "Miscellaneous Functions::Value from mongo: #{doc_json} before processing"
        parsed_doc = JSON.parse(doc_json)  
        log.info "Resp from GN dump: #{parsed_doc}"
        gn_links_from_mongo = parsed_doc["Videos"]
        if $GN_Series_ID.nil?
          $GN_Series_ID = parsed_doc["id"]
          log.info "Misc Functions:: GN series id is: #{$GN_Series_ID}"
        end
        $GN_Episode_ID = parsed_doc["sequence_id"]
        log.info "Misc Functions:: GN episode id is: #{$GN_Episode_ID}"
        if !gn_links_from_mongo.empty?
          log.info "Miscellaneous Functions::gn_links_from_mongo for series-#{series_name},season_num-#{season_no},episode num-#{episode_no}: #{gn_links_from_mongo}"
          services_from_mongo = gn_links_from_mongo.keys
          log.info "Miscellaneous Functions::Filter out the GN Mongo response to contain only primary services"
          services_from_mongo.each do |key| 
            log.info "Miscellaneous Functions::Key is: #{key}"
            new_key = nil
            if $serv_name.include? key.downcase
                 if  key.downcase == "hulu" and !$hulu_vids_cloud.empty?
                log.info "Hulu links fetched from dump, skip it during the validation-don't add to array"
                gn_links_from_mongo.delete(key)
              elsif key.downcase == "vudu" and !$vudu_vids_cloud.empty?
                log.info "Vudu links fetched from dump, skip it during the validation-don't add to array"
                gn_links_from_mongo.delete(key)
              elsif key.downcase == "netflix"
                new_key = "netflixusa"
                hash_of_gn_links[new_key] = gn_links_from_mongo[key]
              else
                new_key = key.downcase
                hash_of_gn_links[new_key] = gn_links_from_mongo[key]
              end
              next
            else
             # if key.downcase.include? "itunes"
             #    new_key = "itunes"
             #    hash_of_gn_links[new_key] = gn_links_from_mongo[key]
             #    next 
             #  elsif key.downcase.include? "netflix"
             #    new_key = "netflixusa"
             #    hash_of_gn_links[new_key] = gn_links_from_mongo[key]
             #    next
              if key.downcase.include? $serv_name
                new_key = $serv_name
                hash_of_gn_links[new_key] = gn_links_from_mongo[key]
                next
              else
                log.info "#{key} not part of primary services supported by Caavo"
                gn_links_from_mongo.delete(key)
              end
            end
          end #end of services from mongo FOR loop
         

          categorised_hash_of_gn_links = get_categorised_gn_launch_ids(hash_of_gn_links,"SE",log)
          gn_links_from_mongo_final = categorised_hash_of_gn_links.values
          log.info "Miscellaneous Functions::gn_links_from_mongo_final: #{gn_links_from_mongo_final}"
          gn_vids_mongo = make_one_single_array(gn_links_from_mongo_final)
          log.info "Miscellaneous Functions::gn_vids_mongo: #{gn_vids_mongo}"
          all_links_from_cloud = $all_vids_categorised_cloud.values
          log.info "Miscellaneous Functions::all_links_from_cloud: #{all_links_from_cloud}"
          all_links_cloud = make_one_single_array(all_links_from_cloud)
          log.info "Miscellaneous Functions::all_links_cloud: #{all_links_cloud}"
        else
          gn_vids_mongo = []
          log.info "Miscellaneous Functions::check_rovi_ingestion_status: GN Metadata available, but no valid gn links for program in dump"
        end 
        log.info "Miscellaneous Functions::check_gn_ingestion_status: gn_vids_mongo for series-#{series_name}: #{gn_vids_mongo}"
        #log.info "gn_vids_cloud: #{gn_vids_cloud}"
    
        gn_links_from_cloud = gn_vids_cloud_categorised.values
        log.info "Miscellaneous Functions::gn_links_from_cloud: #{gn_links_from_cloud}"
        all_gn_links_cloud = make_one_single_array(gn_links_from_cloud)
        log.info "Miscellaneous Functions::all_gn_links_cloud: #{all_gn_links_cloud}"
        log.info "To check whether all videos from Gn dump are present in cloud or not"
        diff1 = gn_vids_mongo - all_links_cloud
        log.info "diff1 = #{gn_vids_mongo} - #{all_links_from_cloud}"
        log.info "Miscellaneous Functions::Few GN Mongo vids are missing in cloud :#{diff1}"
        log.info "To check whether all videos in cloud with GN link are coming from GN dump or not"
        diff2 = all_gn_links_cloud - gn_vids_mongo
        log.info "diff2 = #{all_gn_links_cloud} - #{gn_vids_mongo}"
        log.info "Miscellaneous Functions::Extra GN vids in cloud which were not there in GN dump :#{diff2}"
        if diff1.empty? and diff2.empty?
        #if diff1.empty?
          log.info "GN Ingestion Status for series-#{series_name}: PASS"
          $gn_ingestion_status = "PASS"
          $gn_ingest_success_cnt += 1
          log.info "GN Ingestion Status: PASS count: #{$gn_ingest_success_cnt}"
        else
          if !diff1.empty?
            log.info "Incorrect mapping count ++"
            $incorrect_mapping_cnt += 1
            $arr_incorrect_mapping_episodes.push([series_name,season_no,episode_no,ep_prog_id,"Resp from GN dump: #{parsed_doc}","Few GN Mongo vids are missing in cloud :#{diff1}"])
            $arr_incorrect_mapping_episodes.push(["***************************************"])
            $arr_incorrect_mapping_episodes.push(["***************************************"])
          end
          log.info "GN Ingestion Status for series-#{series_name}: FAIL"
          $gn_ingestion_status = "FAIL"
          $gn_ingest_failures_cnt += 1
          log.info "GN Ingestion Status: FAIL count: #{$gn_ingest_failures_cnt}"
          $gn_ingestion_overall_failure = true if $gn_overall_ingestion_status_updated == false
          $gn_overall_ingestion_status_updated = true
        end
        #arr_prog_ids.push([movie_name,release_year,"GN Video Links available in cloud",gn_ingestion_status])  
      end
    end
    
  end

  def iterate_ott_errors_cnt_based_on_ingestion_status(log)
    log.info "API specs::iterate_ott_errors_cnt_based_on_ingestion_status"
    if !$gn_ingestion_status.nil?
      if $rovi_ingestion_status.include? "FAIL" or $gn_ingestion_status.include? "FAIL"
        log.info "Iterate cnt of episodes with ott error"
        $episodes_with_ott_errors_cnt += 1
      end
    else
      if $rovi_ingestion_status.include? "FAIL"
        log.info "Iterate cnt of episodes with ott error,coz of rovi ott ingestion error"
        $episodes_with_ott_errors_cnt += 1
      end
    end
  end

  def compute_overall_summary_of_series(series_name,release_year,prog_id,log)
    log.info "Misc Functions::compute_overall_summary_of_series"
    unmapped_string = "#{$avail_on_gracenote_and_unable_to_map_cnt} out of #{$episodes_cnt} episodes could not be mapped in GN dump"
    if $episodes_without_ott_links_cnt > 0
      log.info "Misc Functions::episodes without ott > 0"
      if $episodes_without_ott_links_cnt == $episodes_cnt
        log.info "Misc Functions::episodes without ott == episode cnt"

        unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
        #Reporting Format - [Name,Release_Year,Show_Type,RoviID,Available on Ozone,OTT Links Available,Error,Rovi Status,GN Status,Overall Status]
        $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","No",nil,unmapped_string,"Not available in Rovi Dump","Not available in GN dump","FAIL"])
        log.info "#{$episodes_without_ott_links_cnt} out of #{$episodes_cnt} episodes of Series #{series_name} do not have ott links at all."
      else
        if $rovi_ingest_failures_cnt > 0 and $gn_ingest_failures_cnt > 0 
          log.info "Misc Functions::rovi and gn ingestion failures > 0"
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","No ott links available for #{$episodes_without_ott_links_cnt} out of #{$episodes_cnt} episodes","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors",unmapped_string,"Rovi Ingestion Status - FAIL","GN Ingestion Status - FAIL","FAIL"])
        
        elsif $rovi_ingest_failures_cnt > 0 and $gn_ingest_failures_cnt == 0 
          log.info "Misc Functions::rovi ingestion failures > 0, gn ingest =0"
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","No ott links available for #{$episodes_without_ott_links_cnt} out of #{$episodes_cnt} episodes","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors",unmapped_string,"Rovi Ingestion Status - FAIL","GN Ingestion Status - PASS","FAIL"])
        
        elsif $rovi_ingest_failures_cnt == 0 and $gn_ingest_failures_cnt > 0 
          log.info "Misc Functions::gn ingestion failures > 0, rovi ingest =0"
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","No ott links available for #{$episodes_without_ott_links_cnt} out of #{$episodes_cnt} episodes","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors",unmapped_string,"Rovi Ingestion Status - PASS","GN Ingestion Status - FAIL","FAIL"])
        
        elsif $rovi_ingest_failures_cnt > 0
          log.info "Misc Functions::rovi failures > 0"
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","No ott links available for #{$episodes_without_ott_links_cnt} out of #{$episodes_cnt} episodes","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors",unmapped_string,"Rovi Ingestion Status - FAIL","Not available in GN dump","FAIL"])
        
        elsif $gn_ingest_failures_cnt > 0 
          log.info "Misc Functions:: gn ingestion failures > 0"
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","No ott links available for #{$episodes_without_ott_links_cnt} out of #{$episodes_cnt} episodes","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors",unmapped_string,"Not available in Rovi dump","GN Ingestion Status - FAIL","FAIL"])
        else 
          log.info "Misc Functions:: else both gn ingestion failures"
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","No ott links available for #{$episodes_without_ott_links_cnt} out of #{$episodes_cnt} episodes","No",unmapped_string,"Rovi Ingestion Status - PASS","GN Ingestion Status - PASS","FAIL"]) 
        end
        log.info "#{$episodes_without_ott_links_cnt} out of #{$episodes_cnt} episodes of Series #{series_name} do not have ott links for some episodes."
        log.info "#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes of Series #{series_name} have ott errors."
      end
    else
      if $rovi_ingest_failures_cnt == 0 and $gn_ingest_failures_cnt == 0
        #if ($rovi_ingest_success_cnt > 0 and $episodes_with_rovi_links_ingested == $rovi_ingest_success_cnt) and ($gn_ingest_success_cnt > 0 and $episodes_with_gn_links_ingested == $gn_ingest_success_cnt)
        if $rovi_ingest_success_cnt > 0  and $gn_ingest_success_cnt > 0 
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","Yes","No",unmapped_string,"Rovi Ingestion Status - PASS","GN Ingestion Status - PASS","PASS"])
          log.info "#{$rovi_ingest_success_cnt} out of #{$episodes_cnt} have been ingested succesfully from rovi dump,hence Rovi Ingestion Status -PASS"
          log.info "#{$gn_ingest_success_cnt} out of #{$episodes_cnt} have been ingested succesfully from gn dump,hence GN Ingestion Status -PASS"
        elsif $rovi_ingest_success_cnt > 0
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","Yes","No",unmapped_string,"Rovi Ingestion Status - PASS","Not available in GN dump","PASS"])
          log.info "#{$rovi_ingest_success_cnt} out of #{$episodes_cnt} have been ingested succesfully from rovi dump,hence Rovi Ingestion Status -PASS"
        else
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","Yes","No",unmapped_string,"Not available in Rovi dump","GN Ingestion Status - PASS","PASS"])
          log.info "#{$gn_ingest_success_cnt} out of #{$episodes_cnt} have been ingested succesfully from gn dump,hence GN Ingestion Status -PASS"
        end
      else
        if $rovi_ingest_failures_cnt > 0 and $gn_ingest_failures_cnt > 0 
          log.info "Rovi and gn ingestion failures!"
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","Yes","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors",unmapped_string,"Rovi Ingestion Status - FAIL","GN Ingestion Status - FAIL","FAIL"])
          log.info "#{$rovi_ingest_failures_cnt} out of #{$episodes_cnt} have rovi ingestion failures,hence ingestion status -FAIL"
          log.info "#{$gn_ingest_failures_cnt} out of #{$episodes_cnt} have gn ingestion failures,hence ingestion status -FAIL"
        elsif $rovi_ingest_failures_cnt > 0 and $gn_ingest_failures_cnt == 0 
          log.info "Rovi failures more than 0, GN failures =0 !"
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","Yes","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors",unmapped_string,"Rovi Ingestion Status - FAIL","GN Ingestion Status - PASS","FAIL"])
          log.info "#{$rovi_ingest_failures_cnt} out of #{$episodes_cnt} have rovi ingestion failures"
          log.info "#{$gn_ingest_failures_cnt} out of #{$episodes_cnt} have gn ingestion failures"
        elsif $rovi_ingest_failures_cnt == 0 and $gn_ingest_failures_cnt > 0 
          log.info "GN failures more than 0, Rovi failures =0 !"
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","Yes","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors",unmapped_string,"Rovi Ingestion Status - PASS","GN Ingestion Status - FAIL","FAIL"])
          log.info "#{$rovi_ingest_failures_cnt} out of #{$episodes_cnt} have rovi ingestion failures"
          log.info "#{$gn_ingest_failures_cnt} out of #{$episodes_cnt} have gn ingestion failuresL"
        elsif $rovi_ingest_failures_cnt > 0
          log.info "Rovi ingestion failures!"
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","Yes","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors",unmapped_string,"Rovi Ingestion Status - FAIL","Not available in GN dump","FAIL"])
          log.info "#{$rovi_ingest_failures_cnt} out of #{$episodes_cnt} have rovi ingestion failures,hence ingestion status -FAIL"
        elsif $gn_ingest_failures_cnt > 0 
          log.info "GN ingestion failures!"
          unmapped_string = "None" if $avail_on_gracenote_and_unable_to_map_cnt == 0
          $arr_prog_ids.push([series_name,release_year,"SM",prog_id,$GN_Series_ID,"Yes","Yes","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors",unmapped_string,"Not available in Rovi dump","GN Ingestion Status - FAIL","FAIL"])
          log.info "#{$gn_ingest_failures_cnt} out of #{$episodes_cnt} have gn ingestion failures,hence ingestion status -FAIL"
        end
      end
    end 
  end

  def query_dumps_for_series(client,series_name,release_year,season_cnt,log)
    log.info "Misc Functions::query_dumps_for_series"
    rovi_metadata_coll = client[:program_general]
    rel_year_option1 = release_year - 1
    rel_year_option2 = release_year + 1
    $ott_links_available = false
    cnt = rovi_metadata_coll.count({:$or => [{"release_year" => release_year},{"release_year" => rel_year_option1},{"release_year" => rel_year_option2}],"show_type" => "SM",:$or => [{"long title": /#{series_name}/i},{"original title": /#{series_name}/i},{"alias title": /#{series_name}/i}]})
    if cnt == 0
      log.info "Can't find series: #{series_name} in Rovi Metadata dump with release_year: #{release_year},proceed to check in gracenote dump"   
      query_gracenote_dump_for_series(client,series_name,release_year,"Not in Rovi",log)
    else
      log.info "Count equal to one or more"
      $not_avail_on_ozone_but_avail_in_rovi_dumps_cnt += 1
      rovi_metadata_coll.find({:$or => [{"release_year" => release_year},{"release_year" => rel_year_option1},{"release_year" => rel_year_option2}],"show_type" => "SM",:$or => [{"long title": /#{series_name}/i},{"original title": /#{series_name}/i},{"alias title": /#{series_name}/i}]}).each do |doc|
        log.info "Found a match in Rovi Metadata dump,proceed to check if atleast one Rovi/GN link is available OTT Link"
      doc_json = doc.to_json
        prog_id = get_rovi_id_from_query(doc_json,log)
        rovi_metadata_coll.find({"series id" => prog_id,"show_type" => "SE"}).each do |episode|   
          log.info "episode object!!"
          ep_json = episode.to_json
          ep_prog_id = get_rovi_id_from_query(ep_json,log)
          ott_links = get_ott_links_from_mongo_db(client,ep_prog_id,log)
          if !ott_links.empty?
            log.info "Ott links are not empty for episode with prog_id: #{ep_prog_id}!! The series should have come as part of ozone search!!" 
            $ott_links_available = true
            break
          else
          log.info "Ott links are empty for episode with prog_id: #{ep_prog_id}"            
            next
          end
        end
        query_gracenote_dump_for_series(client,series_name,release_year,"In Rovi",log)
      end
    end
  end

  def query_gracenote_dump_for_series(client,series_name,release_year,status,log)
    log.info "Misc Functions::query_gracenote_dump_for_series"
    dump_date = Date.today - 1
    count_added = false
    gn_coll = client[:GN_ott_episodes_ott]
    rel_year_option1 = release_year - 1
    rel_year_option2 = release_year + 1
    cnt = gn_coll.count({"title" => /^#{series_name}/i,:$or => [{"release_year" => release_year},{"release_year" => rel_year_option1},{"release_year" => rel_year_option2}],"show_type" => "SM","gn_dump_date" => dump_date})
    if cnt == 0
      log.info "Can't find series: #{series_name} in GN dump with release_year: #{release_year}"
      if status == "Not in Rovi"
        log.info "Series not in rovi and gracenote!Update array with details"
        $arr_prog_ids.push([series_name,release_year,"SM",nil,nil,"No","No",nil,nil,"Not Available on Rovi","Not available on GN dump","FAIL"])
        $not_avail_on_rovi_and_gn_cnt = $not_avail_on_rovi_and_gn_cnt + 1 
      else
        if $ott_links_available == true
          log.info "Series in rovi metadata with atleast one ott link and not there in gracenote dump"
          $not_avail_on_ozone_and_gn_dump_but_avail_on_rovi_dumps_cnt += 1
          $arr_prog_ids.push([series_name,release_year,"SM",nil,nil,"No","No",nil,nil,"Available on Rovi metadata & ott dumps(atleast 1 episode has ott links)","Not available on GN dump","FAIL"])
        else
          log.info "Series in rovi metadata but not in ott dump and not there in gracenote dump"
          $arr_prog_ids.push([series_name,release_year,"SM",nil,nil,"No","No",nil,nil,"Available on Rovi Metadata dump,but not on Rovi OTT Dump","Not available on GN dump","FAIL"])
        end
      end
 
      log.info "$not_avail_on_rovi_and_gn_cnt: #{$not_avail_on_rovi_and_gn_cnt}" 
    else
       log.info "Series in gracenote dump,let's see how many programs match with the same name and release year"
      gn_coll.find({"title" => /^#{series_name}/i,:$or => [{"release_year" => release_year},{"release_year" => rel_year_option1},{"release_year" => rel_year_option2}],"show_type" => "SM","gn_dump_date" => dump_date}).each do |doc|
        log.info "Series: #{series_name} found in GN dump with release_year: #{release_year}"
        doc_json = doc.to_json
        parsed_doc = JSON.parse(doc_json)
        log.info "Document from GN dump: #{parsed_doc}"
      end
      if status == "Not in Rovi"
        log.info "Series not in rovi metadata but there in gracenote dump! Update array with details"
        $arr_prog_ids.push([series_name,release_year,"SM",nil,nil,"No","No",nil,nil,"Not available on Rovi","Series with similar name and release year available on GN dump","FAIL"])
      else
        if $ott_links_available == true
          log.info "Series in rovi metadata with one valid ott links + there in gracenote dump! Update array with details"
          if !count_added
            log.info "Count +1 => program not there in ozone"
            $not_avail_on_ozone_but_avail_on_rovi_and_gn_cnt += 1
            count_added = true
          end
          $arr_prog_ids.push([series_name,release_year,"SM",nil,nil,"No","No",nil,nil,"Available on Rovi metadata & ott dumps(atleast 1 episode has ott links)","Series with similar name and release year available on GN dump","FAIL"])
        else
          log.info "Series in rovi metadata but no valid ott links + there in gracenote dump! Update array with details"
          if !count_added
            log.info "Count +1 => program not there in ozone"
            $not_avail_on_ozone_and_rovi_but_avail_on_gn_cnt += 1
            count_added = true
          end
          $arr_prog_ids.push([series_name,release_year,"SM",nil,nil,"No","No",nil,nil,"Available on Rovi Metadata dump,but not on Rovi OTT Dump","Series with similar name and release year available on GN dump","FAIL"])
        end
      end
    end
  end



  def extract_launchids_from_csv(raw_launch_ids,log)
    temp1 = Array.new
    temp2 = Array.new
    value_array = Array.new
    temp_hash = {}
    $launch_id_from_csv_hash = Hash.new
    temp1 = raw_launch_ids.split("|") 
    log.info "split of services: #{temp1}"
    for i in 0..temp1.length - 1
      temp2 = temp1[i].split("#")
      log.info "split of hash and key: #{temp2}"
      key = temp2[0]
      log.info "key: #{key}"

      value_array = temp2[1].split(";")
      log.info "value: #{value_array}"


      temp_hash = {key => value_array}
      log.info "temp hash: #{temp_hash}"
      $launch_id_from_csv_hash[key] = value_array 

      log.info "final hash: #{$launch_id_from_csv_hash}"

    end  
    $launch_id_from_csv_hash
  end
  
  
  def validate_cloud_with_external_portal_links(client,series_name,release_year,season_number,episode_number,episode_title,prog_id,launch_ids_from_csv,todays_date,scraped_date,raw_launch_ids,category,all_vids_categorised_cloud,log)
   log.info "Misc Functions::validate_cloud_with_external_portal_links"
   log.info "The links from cloud to validate: #{all_vids_categorised_cloud}"
   log.info "The links from csv to validate: #{launch_ids_from_csv}" 
   len = launch_ids_from_csv.length
   log.info "Size of hash with all services : #{len}"
   diff1 = Array.new
    rovi_status = nil
    gn_status = nil
    vudu_status = nil
    hulu_status = nil
    
   
   for i in 0..len - 1
      temp1 = launch_ids_from_csv.keys[i]
       log.info "The key : #{temp1}"
      var1 = launch_ids_from_csv[temp1]
       log.info "links from csv for #{temp1}: #{var1}"
       var2 = []
        if all_vids_categorised_cloud.empty?
          var2 = []
        else 
          var2 = all_vids_categorised_cloud[temp1]
          log.info "links from cloud for #{temp1} : #{var2}"
        end  
      
        diff1 = var1 - var2
        log.info "diff1: #{diff1}" 
        if !diff1.empty?
          $error_with_service_count += 1
          $error_with_service.push(["#{temp1}"])
          serv_name = temp1

          if $to_validate_dump_array.include?"rovi"
            rovi_status = rovi_db_check_status(client,prog_id,temp1,diff1,log)
          end

          if $to_validate_dump_array.include?"gracenote"
            gn_status = gn_db_check_status(client,series_name,release_year,season_number,episode_number,episode_title,prog_id,serv_name,diff1,log)
          end

          if $to_validate_dump_array.include?"vudu"
            if temp1.include? "vudu"
              log.info "Some VUDU links are missing, verify if its present in Vudu Dump" 
              vudu_status = vudu_db_check_status(client,series_name,release_year,season_number,episode_number,episode_title,diff1,log)
            end
          end
          
          if $to_validate_dump_array.include?"hulu"   
            if temp1.include? "hulu"
             log.info "Some HULU links are missing, verify if its present in HULU Dump" 
             hulu_status = hulu_db_check_status(client,series_name,release_year,season_number,episode_number,episode_title,diff1,log)
            end 
          end  
        end 
   end
   if $error_with_service_count < 1
    log.info "Sending to Print Array: to print in Final CSV"
     $arr_prog_ids.push([scraped_date,category,series_name,release_year,season_number,episode_number,episode_title,raw_launch_ids,"#{$state}:PASS","NO Error","#{prog_id}",todays_date]) 
   else
    log.info "Few links missing for service #{$error_with_service}, Lets validate in dump" 
    error_list = $error_with_service.join(", ")
    error_list = error_list.gsub(",",";")
    log.info "Final Error list: #{error_list}" 
    log.info "Sending to Print Array: to print in Final CSV"
    $arr_prog_ids.push([scraped_date,category,series_name,release_year,season_number,episode_number,episode_title,raw_launch_ids,"#{$state}:FAIL",error_list,"#{prog_id}",todays_date]) 
   end 
  
  end

  def rovi_db_check_status(client,prog_id,serv_name,diff1,log)
    log.info "Miscellaneous Functions:: rovi_db_check_status" 
    rovi_videos_from_dump = Array.new
    index_pc_platform = nil
    complete_video_list = nil
    dump_date = get_latest_rovi_ott_dump_date(client,log)
    collection = client[:rovi_ott_links]
    prog_id_query = prog_id.to_s
    videos_list_got_from_rovi_dump = Array.new
    res = collection.find({:rovi_id => prog_id_query,:rovi_dump_date => { '$eq' => dump_date }}, {'availability' => 1}).limit(1).each do |doc|
        doc_json = doc.to_json
        parsed_doc = JSON.parse(doc_json)
        program_id = parsed_doc['rovi_id']
        log.info "Rovi Program id is: #{program_id}<br>"
        videos = parsed_doc["availability"]["platform_availabilities"]
        for i in 0..videos.length
          platform = videos[i]["platform_id"]
          if platform == "pc"
            log.info "PC platform videos appear in #{i}th index "
            index_pc_platform = i
            break
          end
        end

        next if index_pc_platform.nil?
 
        if index_pc_platform && videos[index_pc_platform]["platform_id"] == "pc"
          
          complete_video_list = videos[index_pc_platform]['source_availabilities']
          #$log.info "Complete video list is: #{complete_video_list} <br>"
          for i in 0..complete_video_list.length-1
            video_obj = complete_video_list[i]
            content_type = video_obj['content_form']
            service_name = video_obj['source_id']
            #$log.info content_type
            if content_type == 'full' && service_name == serv_name
              #$log.info "inside if!!"
          
              video_obj.delete("cache_expiry_timestamp")
              video_obj.delete("last_refreshed_timestamp")
              video_obj.delete("updated_at")
              video_obj.delete("refreshed_at")
              video_obj.delete("content_expiry_timestamp")
              video_obj.delete("price_currency")
              video_obj.delete("source_program_id_space")
              video_obj.delete("is_3d")
              video_obj.delete("audio_languages")
              video_obj.delete("subtitle_languages")
              if video_obj["price"] == ""
                  video_obj["price"] = "0.0"
              end
              vid_price = video_obj["price"]
              cld_price = vid_price.to_f.to_s

              video_obj["price"] = cld_price

              if video_obj["source_id"] == "hulu"
                video_obj.delete("source_program_id")
              end

              if(serv_name == "netflixusa")
                  if !video_obj["link"]["uri"].include? "netflix"
                  next
                end
              end

              if(serv_name == "showtime")
                if video_obj["link"]["uri"].include? "showtimeanytime"
                  next
                end
              
                if !video_obj["link"]["uri"].include? serv_name
                  next
                end  
              end
              
              if !$hulu_vids_cloud.empty? and video_obj["source_id"] == "hulu"
                log.info "Hulu links fetched from dump, skip it during the validation-don't add to array"
                next
              end
              if !$vudu_vids_cloud.empty? and video_obj["source_id"] == "vudu"
                log.info "Vudu links fetched from dump, skip it during the validation-don't add to array"
                next
              end

              videos_list_got_from_rovi_dump.push(video_obj)
            end
          end
        end
      end
    videos_list_got_from_rovi_dump = transform_keys_to_symbols(videos_list_got_from_rovi_dump)
    #$log.info "Videos extracted from rovi dump: #{videos_list_got_from_rovi_dump} <br><br>"
    log.info "Videos extracted from rovi dump: #{videos_list_got_from_rovi_dump}"

    rovi_videos_from_dump = categorise_launch_ids_based_on_service(videos_list_got_from_rovi_dump,"SE",log)

    diff2 = diff1 - rovi_videos_from_dump[serv_name]
    log.info "diff2 = #{diff2}"

    if !diff2.empty?
      rovi_db_avail_status = "FAIL"
    else 
      rovi_db_avail_status = "PASS"
    end
    log.info "rovi_db_avail_status: #{rovi_db_avail_status}" 
    rovi_db_avail_status
  end  

  def gn_db_check_status(client,series_name,release_year,season_number,episode_number,episode_title,prog_id,serv_name,diff1,log)
    gn_db_avail_status = nil
    gn_coll = client[:GN_ott_episodes_ott]
    gn_vids_mongo = nil
    log.info "Miscellaneous Functions::gn_db_check_status"
    dump_date = Date.today - 2
    rel_year = release_year.to_i
    season_no = season_number
    episode_no = episode_number
    log.info "Querying GN dump with Series name : #{series_name}, Release year :#{rel_year}, Season number : #{season_number}, episode_number: #{episode_number},dump date:#{dump_date}"
    cnt = gn_coll.count({"title" => /^#{series_name}/i,"release_year" => rel_year,"season_number" => "#{season_no}","episode_number" => "#{episode_no}","gn_dump_date" => dump_date})
    if cnt == 0
      log.info "Miscellaneous Functions::Can't find #{series_name}, Se #{season_no}, Ep #{episode_no} in GN dump"
      #$arr_episode_prog_ids.push([series_name,season_no,episode_no,"","GN Video Links are shown in cloud","Unable to map, cannot check ingestion status"])
      $not_avail_on_gn_cnt += 1
      gn_vids_mongo = []
     
    else
      gn_coll.find({"title" => /^#{series_name}/i,"release_year" => rel_year,"season_number" => "#{season_no}","episode_number" => "#{episode_no}","gn_dump_date" => dump_date}).limit(1).each do |doc|
        hash_of_gn_links = {}
        categorised_hash_of_gn_links = {}
        doc_json = doc.to_json
        log.info "Miscellaneous Functions::Value from mongo: #{doc_json} before processing"
        parsed_doc = JSON.parse(doc_json)  
        log.info "Resp from GN dump: #{parsed_doc}"
        gn_links_from_mongo = parsed_doc["Videos"]
        if $GN_Series_ID.nil?
          $GN_Series_ID = parsed_doc["id"]
          log.info "Misc Functions:: GN series id is: #{$GN_Series_ID}"
        end
        $GN_Episode_ID = parsed_doc["sequence_id"]
        log.info "Misc Functions:: GN episode id is: #{$GN_Episode_ID}"
        if !gn_links_from_mongo.empty?
          log.info "Miscellaneous Functions::gn_links_from_mongo for series-#{series_name},season_num-#{season_no},episode num-#{episode_no}: #{gn_links_from_mongo}"
          services_from_mongo = gn_links_from_mongo.keys
          log.info "Miscellaneous Functions::Filter out the GN Mongo response to contain only primary services"
          services_from_mongo.each do |key| 
            log.info "Miscellaneous Functions::Key is: #{key}"
            new_key = nil
            if serv_name.include? key.downcase
                # if  key.downcase == "hulu" and !$hulu_vids_cloud.empty?
                # log.info "Hulu links fetched from dump, skip it during the validation-don't add to array"
                # gn_links_from_mongo.delete(key)
                # elsif key.downcase == "vudu" and !$vudu_vids_cloud.empty?
                # log.info "Vudu links fetched from dump, skip it during the validation-don't add to array"
                # gn_links_from_mongo.delete(key)
                if key.downcase == "netflix"
                new_key = "netflixusa"
                hash_of_gn_links[new_key] = gn_links_from_mongo[key]
                else
                new_key = key.downcase
                hash_of_gn_links[new_key] = gn_links_from_mongo[key]
                end
              next
            else
              if key.downcase.include? serv_name
                new_key = serv_name
                hash_of_gn_links[new_key] = gn_links_from_mongo[key]
                next
              else
                log.info "#{key} not part of primary services supported by Caavo"
                gn_links_from_mongo.delete(key)
              end
            end
          end #end of services from mongo FOR loop
           

            categorised_hash_of_gn_links = get_categorised_gn_launch_ids(hash_of_gn_links,"SE",log)
            gn_links_from_mongo_final = categorised_hash_of_gn_links.values
            log.info "Miscellaneous Functions::gn_links_from_mongo_final: #{gn_links_from_mongo_final}"
            gn_vids_mongo = make_one_single_array(gn_links_from_mongo_final)
      
        else
          gn_vids_mongo = []
          log.info "Miscellaneous Functions::check_rovi_ingestion_status: GN Metadata available, but no valid gn links for program in dump"
        end 
      end
   end 
      diff2 = diff1 - gn_vids_mongo
      log.info "diff2= #{diff1} - #{gn_vids_mongo} "
      log.info "diff2= #{diff2}, missing links in GN dump "
      if !diff2.empty?
        gn_db_avail_status = "FAIL"
      else 
        gn_db_avail_status = "PASS"
      end
     
    log.info "gn_db_avail_status: #{gn_db_avail_status}" 
    gn_db_avail_status
  end  


  def hulu_db_check_status(client,series_name,release_year,season_number,episode_number,episode_title,diff1,log)
    log.info "Miscellaneous Functions::hulu_db_check_status"
    hulu_db_avail_status = nil
    hulu_mongo = Array.new
    hulu_coll = client[:HuluValidEpisodes]
    rel_year = release_year.to_i
    seas_no = season_number.to_i
    epis_no = episode_number.to_i
    log.info "Querying Hulu dump with Series name : #{series_name}, Release year :#{rel_year}, Season number : #{seas_no}, episode_number: #{epis_no}"
    
    cnt = hulu_coll.count({"series.name" => /#{series_name}/i,"series.original_premiere_date" => /#{release_year}/i,"season.number" => seas_no,"number" => epis_no})
    if cnt == 0
      log.info "Not found in Hulu dump"
      hulu_db_avail_status = "FAIL"
    else

      hulu_coll.find({"series.name" => /^#{series_name}/i,"series.original_premiere_date" => /#{release_year}/i,"season.number" => seas_no,"number" => epis_no},{android_link:1,title:1,_id:0}).limit(1).each do |doc|
        doc_json = doc.to_json
        log.info "Miscellaneous Functions::Value from mongo: #{doc_json} before processing"
        parsed_doc = JSON.parse(doc_json)  
        log.info "Resp from hulu dump: #{parsed_doc}"
        title_from_mongo = parsed_doc["title"]
        log.info "Title obtained by dump: #{title_from_mongo}"
        link_from_mongo = parsed_doc["android_link"]
        log.info "Raw link obtained from mongo: #{link_from_mongo}"
          if !link_from_mongo.empty?
            log.info "Miscellaneous Functions::hulu_links_from_mongo for series-#{series_name},season_num-#{seas_no},episode num-#{epis_no}: #{link_from_mongo}"
            launch_id = link_from_mongo.match(/http[s]?:\/\/(www.)?hulu\.com\/watch\/([A-Za-z0-9]+)/)[2]
            hulu_mongo.push(launch_id)
          else
            hulu_mongo = []
            log.info "Miscellaneous Functions::check_hulu_ingestion_status: hulu Metadata available, but no valid hulu links for program in dump"
          end 
        log.info "Miscellaneous Functions::check_hulu_ingestion_status: hulu_mongo for series-#{series_name}: #{hulu_mongo}"
       end 
      end 

    if !hulu_mongo.empty?
      diff2 = diff1 - hulu_mongo
      log.info "diff2 : #{diff2}" 
      if diff2.empty? 
        hulu_db_avail_status = "PASS"
      else 
        hulu_db_avail_status = "FAIL"
      end  
    end
    log.info "hulu_db_avail_status: #{hulu_db_avail_status}" 
    hulu_db_avail_status
  end  


  def vudu_db_check_status(client,series_name,release_year,season_number,episode_number,episode_title,diff1,log)
    log.info "Miscellaneous Functions::vudu_db_check_status"
    vudu_mongo = Array.new
    vudu_coll = client[:vududump]
    rel_year = release_year.to_i
    seas_no = season_number.to_i
    epis_no = episode_number.to_i
    log.info "Querying vudu dump with Series name : #{series_name}, Release year :#{rel_year}, Season number : #{seas_no}, episode_number: #{epis_no}"
    
    cnt = vudu_coll.count({"series_title" => /#{series_name}/i,"season_number" => "#{seas_no}","episode_number" => "#{epis_no}"})
    if cnt == 0
      log.info "Nothing found in Vudu Dump."
     vudu_db_avail_status = "FAIL"
     log.info "vudu_db_avail_status: #{vudu_db_avail_status}"

   else
    vudu_coll.find({"series_title" => /#{series_name}/i,"season_number" => "#{season_number}","episode_number" => "#{episode_number}"}).limit(1).each do |doc|
        doc_json = doc.to_json
        log.info "Miscellaneous Functions::Value from mongo: #{doc_json} before processing"
        parsed_doc = JSON.parse(doc_json)  
        log.info "Resp from vudu dump: #{parsed_doc}"
        title_from_mongo = parsed_doc["title"]
        title_from_mongo = series_name.gsub(/#{title_from_mongo}\: /,"")
        log.info "Title obtained by dump: #{title_from_mongo}"
        link_from_mongo = parsed_doc["url"]
        log.info "Raw link obtained from mongo: #{link_from_mongo}"
        if !link_from_mongo.empty?
          log.info "Miscellaneous Functions::vudu_links_from_mongo for series-#{series_name},season_num-#{seas_no},episode num-#{epis_no}: #{link_from_mongo}"
          launch_id = link_from_mongo.match(/http[s]?:\/\/(www.)?vudu\.com\/movies\/#!content\/([A-Za-z0-9]+)/)[2]
        vudu_mongo.push(launch_id)
        else
          vudu_mongo = []
          log.info "Miscellaneous Functions::check_vudu_ingestion_status: vudu Metadata available, but no valid vudu links for program in dump"
        end 
        log.info "Miscellaneous Functions::check_vudu_ingestion_status: vudu_mongo for series-#{series_name}: #{vudu_mongo}"
       end 
    end     
        if !vudu_mongo.empty?     
        diff2 = diff1 - vudu_mongo
        if diff2.empty?
          vudu_db_avail_status = "FAIL"
        else 
          vudu_db_avail_status = "PASS"
        end
        log.info "vudu_db_avail_status: #{vudu_db_avail_status}" 
        end
        vudu_db_avail_status
    
  end  

  # def query_dumps_for_episode(client,series_name,release_year,season_number,episode_number,episode_title,todays_date,scraped_date,raw_launch_ids,category,log)
  #   log.info "Misc Functions::query_dumps_for_episode"
  #   rovi_metadata_coll = client[:program_general]
  #   rel_year_option1 = release_year - 1
  #   rel_year_option2 = release_year + 1
  #   $ott_links_available = false
  #   cnt = rovi_metadata_coll.count({:$or => [{"release_year" => release_year},{"release_year" => rel_year_option1},{"release_year" => rel_year_option2}],:$or => [{"long title": /#{series_name}/i},{"original title": /#{series_name}/i},{"alias title": /#{series_name}/i}],"episode title" => /#{episode_title}/i,"show type" => "SE"})
  #   if cnt == 0
  #     log.info "Can't find series: #{series_name} in Rovi Metadata dump with release_year: #{release_year},write to csv" 
  #     log.info "Sending to Print Array: to print in Final CSV"  
  #     $arr_prog_ids.push([scraped_date,category,series_name,release_year,season_number,episode_number,episode_title,raw_launch_ids,"FAIL","#{$state}: not found in rovi metadata also",todays_date]) 
  #   else
  #     rovi_metadata_coll.find({:$or => [{"release_year" => release_year},{"release_year" => rel_year_option1},{"release_year" => rel_year_option2}],:$or => [{"long title": /#{series_name}/i},{"original title": /#{series_name}/i},{"alias title": /#{series_name}/i}],"episode title" => /#{episode_title}/i,"show type" => "SE"}).each do |episode|   
  #       log.info "episode object!!"
  #       ep_json = episode.to_json
  #       ep_prog_id = get_rovi_id_from_query(ep_json,log)
  #       log.info "ep_prog_id: #{ep_prog_id}"  
  #       full_Episodes_dump = client[:program_Full_Sequencing]
  #       log.info "got program id, entering program_Full_Sequencing db to get season number and episode number" 
  #       count1 = full_Episodes_dump.count({"program id" => "#{ep_prog_id}"})
  #       if count1 == 0 
  #       	$arr_prog_ids.push([scraped_date,category,series_name,release_year,season_number,episode_number,episode_title,raw_launch_ids,"FAIL","#{$state}:series mapped but episode not available in Rovi dump",todays_date])
  #       else	
  #         full_Episodes_dump.find({"program id" => "#{ep_prog_id}"}).each do |episode_detail|
  #           log.info "entered metadata seq: #{ep_prog_id}" 
  #           episode_detail_json = episode_detail.to_json
  #           parsed_doc = JSON.parse(episode_detail_json)
  #           seas_no = parsed_doc["season number"]
  #           epis_no = parsed_doc["program id"]
  #           log.info "obtained : seas_no : #{seas_no}, epis_no : #{epis_no}" 
  #           if season_number == seas_no && episode_number == epis_no
  #             log.info "Sending to Print Array: to print in Final CSV"
  #             $arr_prog_ids.push([scraped_date,category,series_name,release_year,season_number,episode_number,episode_title,raw_launch_ids,"FAIL","#{$state}: Available in Rovi dump",todays_date]) 
  #           else
  #             log.info "Sending to Print Array: to print in Final CSV"
  #             $arr_prog_ids.push([scraped_date,category,series_name,release_year,season_number,episode_number,episode_title,raw_launch_ids,"FAIL","#{$state}: Series mapped but episode sequence not mapped",todays_date]) 
  #           end
  #         end 
  #       end 
  #     end
  #   end    
  # end

  def ingest_to_master_csv(row,csv_input1,log)
  	CSV.open(csv_input1, "ab") do |csv1|
  	  csv1 << row
    end 
  end 

  def mod_title(title)
    title_mod = title.downcase
    #title_mod = title_mod.gsub(/^(the |an |a )/,'')
    title_mod = title_mod.gsub(/[;|:|\-|,|.|'|"|?|!|@|#]/,'')
    title_mod = title_mod.gsub(/&/,'and')
    return title_mod
  end
  
  # def get_episode_id(series_name,release_year,season_number,episode_number,episode_title,log)
  #   series_mapped_flag = 0
  #   episode_mapped_flag = 0
  #   episode_id = 0
  #   title_totest = series_name
  #   title_totest_m = mod_title(title_totest);
  #   rel_year_totest = release_year
  #   season_number_totest = season_number
  #   episode_number_totest = episode_number
  #   episode_title_totest = episode_title
  #   episode_title_totest_m = mod_title(episode_title_totest);
  #   base_url = $conf["request_headers"]["Host"]   
  #   log.info ("Base URL: #{base_url}")   
  #   r = JSON.parse(RestClient.get(base_url + "/voice_search?search_apps=true&q=#{URI.escape"(#{title_totest})"}", {:authorization => 'Token token=64becbd7666f73e6d825b9f3d9bf270a9fc3c5b2590df3da3d4cb65d77f0b2b0'}))
  #   r.each do |req|
  #     if req["action_type"] == "ott_search"
  #       req['results'].each do |obj|
  #         rovi_longtitle = obj["object"]["long_title"]
  #         rovi_longtitle = mod_title(rovi_longtitle);
  #         rovi_originaltitle = obj["object"]["original_title"]
  #         rovi_originaltitle = mod_title(rovi_originaltitle);
  #         if (rovi_longtitle == title_totest_m) || (rovi_originaltitle == title_totest_m)
  #           if obj["object"]["show_type"] == "SM"
  #             if (obj["object"]["release_year"] == rel_year_totest) || (obj["object"]["release_year"] == rel_year_totest-1) || (obj["object"]["release_year"] == rel_year_totest+1)
  #               pgm_id_to_test = obj["object"]["series_id"]
  #               series_mapped_flag = 1
  #               if series_mapped_flag ==1
  #                 episodes_oz = JSON.parse(RestClient.get(base_url + "/programs/#{(pgm_id_to_test)}/episodes?season_number=#{season_number_totest}", {:authorization => 'Token token=64becbd7666f73e6d825b9f3d9bf270a9fc3c5b2590df3da3d4cb65d77f0b2b0'}))
  #                 episodes_oz.each do |ro|
  #                   oz_ep_title = mod_title(ro["episode_title"])
  #                   oz_org_ep_title = mod_title(ro["original_episode_title"])
  #                   if (oz_ep_title == episode_title_totest_m) || (oz_org_ep_title == episode_title_totest_m)
  #                     episode_mapped_flag = 1
  #                     episode_id = ro["id"]
  #                     break
  #                   end
  #                 end
  #               end
  #             end
  #           end
  #         end
  #         if series_mapped_flag == 1
  #           break
  #         end
  #       end
  #     end
  #   end
  #   if episode_mapped_flag == 1 && series_mapped_flag == 1
  #     return episode_id
  #   elsif series_mapped_flag == 1 && episode_mapped_flag == 0
  #     return "episode couldn't mapped in Ozone"
  #   else
  #     return "series not mapped in Ozone"
  #   end
  # end

  #########################################################################

  def query_dumps_for_episode_rovi_primary(client,series_name,release_year,season_number,episode_number,episode_title,launch_ids_from_csv,todays_date,scraped_date,raw_launch_ids,category,all_vids_categorised_cloud,log)
    log.info "Misc Functions::query_dumps_for_episode"
    rovi_metadata_coll = client[:program_general]
    rel_year_option1 = release_year - 1
    rel_year_option2 = release_year + 1
    $ott_links_available = false
    cnt = rovi_metadata_coll.count({:$or => [{"release_year" => release_year},{"release_year" => rel_year_option1},{"release_year" => rel_year_option2}],:$or => [{"long title": /#{series_name}/i},{"original title": /#{series_name}/i},{"alias title": /#{series_name}/i}],"episode title" => /#{episode_title}/i,"show type" => "SE"})
    if cnt == 0
      $state = $state + ":Not found in Rovi Metadata"
      log.info "Can't find series: #{series_name} in Rovi Metadata dump with release_year: #{release_year}"
      log.info "Continue to check other dumps for the videos match"
      ############################
      log.info "The links from csv to validate: #{launch_ids_from_csv}" 
      len = launch_ids_from_csv.length
      log.info "Size of hash with all services : #{len}"
      diff1 = Array.new
      gn_status = nil
      vudu_status = nil
      hulu_status = nil
     
      for i in 0..len - 1
        temp1 = launch_ids_from_csv.keys[i]
        log.info "The key : #{temp1}"
        var1 = launch_ids_from_csv[temp1]
        log.info "links from csv for #{temp1}: #{var1}"
        
        diff1 = var1 
        log.info "diff1: #{diff1}" 

        serv_name = temp1
        if $to_validate_dump_array.include?"gracenote"
          gn_status = gn_db_check_status(client,series_name,release_year,season_number,episode_number,episode_title,nil,serv_name,diff1,log)
        end

        if $to_validate_dump_array.include?"vudu"
          if temp1.include? "vudu"
            log.info "Some VUDU links are missing, verify if its present in Vudu Dump" 
            vudu_status = vudu_db_check_status(client,series_name,release_year,season_number,episode_number,episode_title,diff1,log)
          end
        end
          
        if $to_validate_dump_array.include?"hulu"   
          if temp1.include? "hulu"
            log.info "Some HULU links are missing, verify if its present in HULU Dump" 
            hulu_status = hulu_db_check_status(client,series_name,release_year,season_number,episode_number,episode_title,diff1,log)
          end 
        end  
      end
      status_of_dumps = "gn_status : #{gn_status},hulu_status : #{hulu_status} vudu_status: #{vudu_status}"
      $arr_prog_ids.push([scraped_date,category,series_name,release_year,season_number,episode_number,episode_title,raw_launch_ids,"#{$state}:FAIL",status_of_dumps,todays_date])
      log.info "Finished querying dumps"

      ##########################
                               
    else
      temp_array = Array.new
      rovi_metadata_coll.find({:$or => [{"release_year" => release_year},{"release_year" => rel_year_option1},{"release_year" => rel_year_option2}],:$or => [{"long title": /#{series_name}/i},{"original title": /#{series_name}/i},{"alias title": /#{series_name}/i}],"episode title" => /#{episode_title}/i,"show type" => "SE"}).each do |episode|   
        temp_array.push(episode)  
      end

      log.info "episode object from rovi metadata: #{temp_array}"
      list_of_episodes_nos = temp_array.length
      log.info "length of episodes returned by rovi metadata dump:#{list_of_episodes_nos} "
      program_ids_from_metadata_dump = Array.new 
      if list_of_episodes_nos > 1
          for i in 0..list_of_episodes_nos - 1
            id_returned = get_rovi_id_from_query(temp_array[i],log)
            program_ids_from_metadata_dump.push(id_returned)
          end  
          log.info "List of program id's got from rovi metadata: #{program_ids_from_metadata_dump}"
          ep_prog_id = validate_episode_id_with_credits(client,program_ids_from_metadata_dump,season_number,episode_number,log)
      else 
        ep_prog_id = get_rovi_id_from_query(temp_array[0],log)
      end 
    log.info "Finalized program ID from rovi metadata: #{ep_prog_id}"
    $state = $state + ":Got prog id from rovi metadata"    
    validate_cloud_with_external_portal_links(client,series_name,release_year,season_number,episode_number,episode_title,ep_prog_id,launch_ids_from_csv,todays_date,scraped_date,raw_launch_ids,category,all_vids_categorised_cloud,log) 
    end 
  end

  def get_season_sequence_match_status(client,ep_prog_id,season_number,episode_number,log)
    log.info "ep_prog_id: #{ep_prog_id}"  
    full_Episodes_dump = client[:program_Full_Sequencing]
    log.info "got program id, entering program_Full_Sequencing db to get season number and episode number" 
    count1 = full_Episodes_dump.count({"program id" => "#{ep_prog_id}"})
    if count1 == 0 
        status_of_episode_sequence_match = "prog_id not found in full sequence dump"      
    else  
      full_Episodes_dump.find({"program id" => "#{ep_prog_id}"}).each do |episode_detail|
        log.info "entered metadata seq: #{ep_prog_id}" 
        episode_detail_json = episode_detail.to_json
        parsed_doc = JSON.parse(episode_detail_json)
        seas_no = parsed_doc["season number"]
        epis_no = parsed_doc["program id"]
        log.info "obtained : seas_no : #{seas_no}, epis_no : #{epis_no}" 

        if season_number == seas_no && episode_number == epis_no
          status_of_episode_sequence_match = "sequence matched"    
        else
          status_of_episode_sequence_match = "Sequence not matched"                 
        end
      end 
    end 
    status_of_episode_sequence_match
  end  


  def validate_episode_id_with_credits(client,program_ids_from_metadata_dump,season_number,episode_number,log)
    #query program credits dump
    full_name_credits_dump = Array.new
    final_prg_id = nil
    program_credits_dump = client[:program_credits] 

    for i in 0..program_ids_from_metadata_dump.length-1
      count1 = program_credits_dump.count({"program id" => "#{program_ids_from_metadata_dump[i]}"})
      if count1 == 0 
          status_of_credits_match = "No credits found for the ID,check the next id"
          next      
      else  
        program_credits_dump.find({"program id" => "#{program_ids_from_metadata_dump[i]}"}).each do |credit|
          individual_credits_json = credit.to_json
          parsed_doc = JSON.parse(individual_credits_json)
          if parsed_doc["credit type"] == "Actor"
            full_name_credits_dump.push(parsed_doc["full credit name"])
          else
            next  
          end
        end
      end  
      episode_sequence_match_status = get_season_sequence_match_status(client,program_ids_from_metadata_dump[i],season_number,episode_number,log)
      
      if full_name_credits_dump.include? "credits from SQL dump" or episode_sequence_match_status == "sequence matched"
        log.info "Found the right program id...."
        final_prg_id = program_ids_from_metadata_dump[i]
        break
      else
        log.info "Not the right program id, hence skipping the program id"
        next
      end
    end
    final_prg_id       
  end  


  # def voice_search_pagination(search_term,log)
  #   total_response = Array.new
  #   results_array = Array.new
  #   search_api = "/voice_search/v2?q="+"#{search_term}"
  #   get search_api
  #   log.info "json_body: #{json_body}"
  #   log.info "json_body_length: #{json_body.length}"
  #   # log.info "json_body_results: #{json_body[:results]}"
  #   results_array = json_body[:results]
  #   if !results_array.nil?
  #     log.info "json_body_results_length : #{(json_body[:results]).length}"
  #     ott_search_index = get_index_of_ott_search_object(results_array,log)
  #     other_responses = Array.new
  #     if ott_search_index != nil
  #       log.info "#{results_array[ott_search_index]}"
  #       if results_array[ott_search_index].key?(:next_page)
  #         log.info "next_page key exists"
  #         total_response =  results_array[ott_search_index][:results]
  #         other_responses = collect_all_pages_info(results_array[ott_search_index][:next_page],log)
  #         total_response = total_response + other_responses
  #       else
  #         log.info "No next_page key present ; hence getting existing results"
  #         total_response =  results_array[ott_search_index][:results]
  #       end
  #     else
  #       $state = "No ott object found in results"
  #       log.info "#{$state}"
  #     end    

  #   else
      
  #     $state = "empty results from cloud"
  #     log.info "#{$state}"
  #   end      
  #     total_response
  # end  

  # def collect_all_pages_info(url,log)
  #   rest_results_array = Array.new
  #   next_key = true
  #   while (next_key)
  #     get url
  #     log.info "current next_page response : #{(json_body[:results])[0][:results]}"
  #     log.info "current next_page response length: #{((json_body[:results])[0][:results]).length}"
  #     rest_results_array = rest_results_array + (json_body[:results])[0][:results]

  #     if json_body[:results][0].key?(:next_page)
  #       url = json_body[:results][0][:next_page]
  #       next_key = true
  #     else
  #        next_key = false
  #     end  
  #   end
  #   log.info "length of next pages response obtained: #{rest_results_array.length}"  
  #   rest_results_array
  # end  

  def voice_search_pagination(search_term,tab,log)
    total_response = Array.new
    results_array = Array.new
    search_api = "/v2/voice_search?q="+"#{search_term}"
    retry_cnt = 3
      begin
      get search_api
      response_code_validation("get",search_api)
      rescue Exception => err 
        log.error "Error in getting response <br>"
        log.error "Error!!!: #{err} <br"
        retry_cnt -= 1
        if retry_cnt > 0
          sleep 10
          retry
        else
          log.info "retry count: #{retry_cnt}"
        end
      end  
    log.info "voice_search_response: #{json_body}"
    log.info "voice_search_response_length: #{json_body.length}"
    # log.info "json_body_results: #{json_body[:results]}"
    results_array = json_body[:results]
    if results_array.length > 0
      log.info "json_body_results_length : #{(json_body[:results]).length}"
      if tab == "ott_search"
        ott_search_index = get_index_of_ott_search_object(results_array,log)
      elsif tab == "epg_search"
        ott_search_index = get_index_of_epg_search_object(results_array,log)
      elsif tab == "upcoming_epg_search"
        ott_search_index = get_index_of_upcoming_epg_search_object(results_array,log)
      end
              
      other_responses = Array.new
      if ott_search_index != nil
        log.info "#{results_array[ott_search_index]}"
        if results_array[ott_search_index].key?(:next_page_params)
          log.info "page_params key exists"
          total_response =  results_array[ott_search_index][:results]

          query = results_array[ott_search_index][:next_page_params][:query]
          search_id = results_array[ott_search_index][:next_page_params][:search_id]
          page = results_array[ott_search_index][:next_page_params][:page]
          filter = results_array[ott_search_index][:next_page_params][:filter]
          # final_next_url = "/v2/?query=" + "#{query}" +"&search_id=" + "#{search_id}" + "&page=" + "#{page}" + "&filter=" + "#{filter}"        
          final_next_url = nil
          if results_array[ott_search_index][:next_page_params].key?(:upcoming_feed_index)
            log.info "upcoming_feed_index key found"
            upcoming_feed_index = results_array[ott_search_index][:next_page_params][:upcoming_feed_index]
            final_next_url = "/v2/voice_search?query=" + "#{query}" +"&search_id=" + "#{search_id}" + "&page=" + "#{page}" + "&filter=" + "#{filter}" + "&upcoming_feed_index=" + "#{upcoming_feed_index}"
          else
            final_next_url = "/v2/voice_search?query=" + "#{query}" +"&search_id=" + "#{search_id}" + "&page=" + "#{page}" + "&filter=" + "#{filter}"
          end  

          other_responses = collect_all_pages_info(final_next_url,log)
          total_response = total_response + other_responses
        else
          log.info "No page_params key present ; hence getting existing results"
          total_response =  results_array[ott_search_index][:results]
        end
      else
        $state = "No requested object found in results"
        log.info "#{$state}"
      end    

    else
      
      $state = "empty results from cloud"
      log.info "#{$state}"
    end      
      total_response
  end  

  def collect_all_pages_info(url,log)
    rest_results_array = Array.new
    next_key = true

    while (next_key)
      retry_cnt = 3
      begin
        log.info "next page url to query: #{url}"
        get url
        response_code_validation("get",url)
      rescue Exception => err 
        log.error "Error in getting response <br>"
        log.error "Error!!!: #{err} <br"
        retry_cnt -= 1
        if retry_cnt > 0
          sleep 10
          retry
        else
          log.info "retry count: #{retry_cnt}"
        end
      end
      if (json_body[:results]).length > 0
        log.info "current next_page response : #{json_body}"
        log.info "current next_page results response length: #{((json_body[:results])[0][:results]).length}"
        rest_results_array = rest_results_array + (json_body[:results])[0][:results]

        if json_body[:results][0].key?(:next_page_params)
          query = json_body[:results][0][:next_page_params][:query]
          search_id = json_body[:results][0][:next_page_params][:search_id]
          page = json_body[:results][0][:next_page_params][:page]
          filter = json_body[:results][0][:next_page_params][:filter]
          if json_body[:results][0][:next_page_params].key?(:upcoming_feed_index)
            upcoming_feed_index = json_body[:results][0][:next_page_params][:upcoming_feed_index]
            url = "/v2/voice_search?query=" + "#{query}" +"&search_id=" + "#{search_id}" + "&page=" + "#{page}" + "&filter=" + "#{filter}" + "&upcoming_feed_index=" + "#{upcoming_feed_index}"
          else
            url = "/v2/voice_search?query=" + "#{query}" +"&search_id=" + "#{search_id}" + "&page=" + "#{page}" + "&filter=" + "#{filter}"
          end  
          
          next_key = true
        else
           next_key = false
        end 
      else
        log.info "No results found in the URL obtained"
        next_key = false
      end   
    end
    log.info "length of next pages response obtained: #{rest_results_array.length}"  
    rest_results_array
  end  

  #########################################################################

  def get_episode_id(series_name,release_year,season_number,episode_number,episode_title,log)
    $series_mapped_flag = 0
    $episode_mapped_flag = 0
    $title_mapped_flag = 0
    $episode_id = 0
    $series_id = 0
    title_totest = series_name
    title_totest_m = mod_title(title_totest);
    rel_year_totest = release_year
    season_number_totest = season_number
    episode_number_totest = episode_number
    episode_title_totest = episode_title
    episode_title_totest_m = mod_title(episode_title_totest);
       
    # r = JSON.parse(RestClient.get($base_url + "/voice_search?q=#{URI.escape"(#{title_totest})"}", {:authorization => 'Token token=64becbd7666f73e6d825b9f3d9bf270a9fc3c5b2590df3da3d4cb65d77f0b2b0'}))
    r = voice_search_pagination(title_totest,"ott_search",log)
    r = JSON.parse((r.to_json))
    log.info "total responses from all the pages: #{r}"
    log.info "total responses from all the pages length : #{r.length}"
    search_obj = []
    if !r.empty?      
      r.each do |obj|
        if $series_mapped_flag == 1
          break
        end
        series_mapped_flag = 0
        rovi_longtitle = obj["object"]["long_title"]
        rovi_longtitle = mod_title(rovi_longtitle);
        rovi_originaltitle = obj["object"]["original_title"]
        rovi_originaltitle = mod_title(rovi_originaltitle); 
        rovi_alias = obj["object"]["alias_title"]
        rovi_alias = mod_title(rovi_alias); 
        rovi_alias1 = obj["object"]["alias_title_2"]
        rovi_alias1 = mod_title(rovi_alias1);
        rovi_alias2 = obj["object"]["alias_title_3"]
        rovi_alias2 = mod_title(rovi_alias2);
        rovi_alias3 = obj["object"]["alias_title_4"]
        rovi_alias3 = mod_title(rovi_alias3);
        if ((rovi_longtitle == title_totest_m) || (rovi_originaltitle == title_totest_m) || (rovi_alias == title_totest_m) || (rovi_alias1 == title_totest_m) || (rovi_alias2 == title_totest_m) || (rovi_alias3 == title_totest_m))
          $title_mapped_flag =1
          if obj["object"]["show_type"] == "SM"
            if (obj["object"]["release_year"] == rel_year_totest) || (obj["object"]["release_year"] == rel_year_totest-1) || (obj["object"]["release_year"] == rel_year_totest+1)
              $series_mapped_flag = 1
              log.info "Series got mapped and going for episode ID"
              log.info "Mapped series is #{obj["object"]["series_id"]}"
              log.info "episode title from input is #{episode_title_totest_m}"
              $series_id = obj["object"]["series_id"]
              #log.info ("Murali: Direct series match")
              #log.info ("Murali: Direct series match, season_number in test is #{season_number_totest}")
              episodes_oz = JSON.parse(RestClient.get($base_url + "/programs/#{$series_id}/episodes?season_number=#{season_number_totest}", {:authorization => 'Token token=64becbd7666f73e6d825b9f3d9bf270a9fc3c5b2590df3da3d4cb65d77f0b2b0'}))
              #log.info ("Murali: Direct series match,episode mapping in progress stage 1")
              if !episodes_oz.empty?
                log.info "Series got mapped and Episodes are not empty"
                #log.info ("Murali: Direct series match,episode mapping in progress stage 2 : Episodes not empty in seasonapi")
                episodes_oz.each do |ro|
                  ep_title = ro["episode_title"]
                  ep_title = mod_title(ep_title);
                  ep_org_title = ro["original_episode_title"]
                  ep_org_title = mod_title(ep_org_title);
                  if (ep_title == episode_title_totest_m) || (ep_org_title == episode_title_totest_m)
                    #log.info ("Murali: Direct series match and episode ID is returned")
                    log.info "direct series ID match and episode ID is returned"
                    return ro["id"]
                    break
                  end
                  #log.info "episode title under test is #{ep_title}"
                  #log.info "All original episode title under test is #{ep_org_title}"
                end
              else
                log.info "Series got mapped and episodes page for seasons API is empty so checking All episodes API"
                ret = verify_series_episodes($series_id,episode_title_totest_m,log);
                #log.info ("Murali: Direct series match, season sequence Not Available")
                return ret
              end
              log.info "Series got mapped but episode couldn't get mapped"
              return "Series got mapped but Episode Title didn't matched"
            end
            if $series_mapped_flag == 0
              search_obj << obj["object"]["series_id"]
            end
          end
        end
      end
    end
    if $series_mapped_flag == 0 && !r.empty?
      log.info "Only Titlematch so checking title's Season/Episodes to match series and episode"
      log.info "Mapped titles are #{search_obj}"
      if search_obj.length > 0
        #log.info ("Murali: More Titles available")
        #if more than one search result matches then iterate through them w.r.t S1E1 releaseyear/airdate and get 1 Episode ID
        search_obj.each do |sid|
          ret_s = String.new
          #log.info "testing.......................#{ret_s}"
          #log.info "series to test is #{sid}"
          ret_s = verify_series_season(sid,rel_year_totest,season_number_totest,episode_number_totest,episode_title_totest_m,log);
          #log.info "testing.......................#{ret_s}"
          #log.info "returned for thiss issue is #{ret_s}"
          #returns Episode ID if series ID matches else nil wil be rerturned
          if ret_s != nil
            log.info "got mapped from series titles mapped"
            return ret_s
          end
        end
        #fetched_episodeid = ret  
        log.info "series didn't mapped"
        return "series didn't mapped" 
      else
        return "None of the series titles matched"
      end
    else
      #this case needs to be checked with some more conditions
      log.info "Empty search results"
      return "Empty search results"
    end
  end

  def verify_series_season(sid,rel_year_totest,season_number_totest,episode_number_totest,episode_title_totest_m,log)
    temp_epi_count = 0
    episodes_oz = JSON.parse(RestClient.get($base_url + "/programs/#{(sid)}/episodes?season_number=1", {:authorization => 'Token token=64becbd7666f73e6d825b9f3d9bf270a9fc3c5b2590df3da3d4cb65d77f0b2b0'}))
    if !episodes_oz.empty?
      episodes_oz[0..0].each do |epid|
        #log.info temp_epi_count
        if temp_epi_count < 1
          #log.info "-------------------------------------------------"
          #log.info temp_epi_count
          temp_epi_count = temp_epi_count + 1
          rel = epid["release_year"]
          log.info "release year of S1E1 is #{rel}"
          if rel == nil
            log.info "release year is null for 1st episode, so checking airdate"
            airdate_arr = []
            temp_airdate_arr = []
            temp_airdate_arr.push epid["air_date"]
            if !temp_airdate_arr[0] == nil
              airdate_arr.push epid["air_date"]
              airdate_arr.each do |dt|
                if dt["country"] == "US"
                  rel_ep = dt["date"]
                  log.info "Raw airdate for S1E1 is #{rel_ep}"
                  rel_ep = rel_ep[0,4]
                  log.info "Release year from airdate for S1E1 is #{rel_ep}"
                  rel_ep = rel_ep.to_i
                  if (rel_ep == rel_year_totest) || (rel_ep == rel_year_totest-1) || (rel_ep == rel_year_totest+1)
                    log.info "series got mapped by releaseyear from airdate of S1E1"
                    episodes_sn = JSON.parse(RestClient.get($base_url + "/programs/#{(sid)}/episodes?season_number=#{season_number_totest}", {:authorization => 'Token token=64becbd7666f73e6d825b9f3d9bf270a9fc3c5b2590df3da3d4cb65d77f0b2b0'}))
                    episodes_sn.each do |ro|
                      ep_title = ro["episode_title"]
                      ep_title = mod_title(ep_title);
                      ep_org_title = ro["original_episode_title"]
                      ep_org_title = mod_title(ep_org_title);
                      if (ep_title == episode_title_totest_m) || (ep_org_title == episode_title_totest_m)
                        log.info "Debug1: returnable id is #{ro["id"]}"
                        return ro["id"]
                        break
                      end
                    end
                  end
                end
              end
            else
              log.info "Debug2: release year and airdate are null for season 1 episode 1"
              return "release year and airdate are null for season 1 episode 1"
            end
          else
            log.info "release year is not null"
            #log.info "release year under test from S1E1 is #{rel}"
            #log.info "release year under test from input is #{rel_year_totest}"
            if (rel == rel_year_totest) || (rel == rel_year_totest-1) || (rel == rel_year_totest+1)
              log.info "Junk loop"
              episodes_sn = JSON.parse(RestClient.get($base_url + "/programs/#{(sid)}/episodes?season_number=#{season_number_totest}", {:authorization => 'Token token=64becbd7666f73e6d825b9f3d9bf270a9fc3c5b2590df3da3d4cb65d77f0b2b0'}))
              episodes_sn.each do |ro|
                ep_title = ro["episode_title"]
                ep_title = mod_title(ep_title);
                ep_org_title = mod_title(ep_org_title);
                ep_org_title = ro["original_episode_title"]
                if (ep_title == episode_title_totest_m) || (ep_org_title == episode_title_totest_m)
                  log.info "Debug3: "
                  return ro["id"]
                  break
                end
              end
            else
              log.info "series didn't mapped as release year of series,S1E1,airdate of S1E1 didn't mapped with input release year"
              #log.info ro
              return "series didn't mapped as release year of series,S1E1,airdate of S1E1 didn't mapped with input release year"
            end
          end
        end
      end
    else
      episodes_oz = JSON.parse(RestClient.get($base_url + "/programs/#{(sid)}/episodes", {:authorization => 'Token token=64becbd7666f73e6d825b9f3d9bf270a9fc3c5b2590df3da3d4cb65d77f0b2b0'}))
      log.info "entered all episodes API as seasons api release year is null"
      if !episodes_oz.empty?
        episodes_oz[0..0].each do |epid|
          rel = epid["release_year"]
          log.info "release year from first episode in All episodes API is #{rel}"
          if rel == nil
            airdate_arr = []
            temp_airdate_arr = []
            temp_airdate_arr.push epid["air_date"]
            if !temp_airdate_arr[0] == nil
              airdate_arr.push epid["air_date"]
              airdate_arr.each do |dt|
                if dt["country"] == "US"
                  rel_ep = dt["date"]
                  rel_ep = rel_ep[0,4]
                  rel_ep = rel_ep.to_i
                  if (rel_ep == rel_year_totest) || (rel_ep == rel_year_totest-1) || (rel_ep == rel_year_totest+1)
                    episodes_sn = JSON.parse(RestClient.get($base_url + "/programs/#{(sid)}/episodes?season_number=#{season_number_totest}", {:authorization => 'Token token=64becbd7666f73e6d825b9f3d9bf270a9fc3c5b2590df3da3d4cb65d77f0b2b0'}))
                    episodes_sn.each do |ro|
                      ep_title = ro["episode_title"]
                      ep_title = mod_title(ep_title);
                      ep_org_title = mod_title(ep_org_title);
                      ep_org_title = ro["original_episode_title"]
                      if (ep_title == episode_title_totest_m) || (ep_org_title == episode_title_totest_m)
                        log.info "Debug4: "
                        return ro["id"]
                        break
                      end
                    end
                  end
                end
              end
            else
              log.info "Debug5: release year and airdate are null for season 1 episode 1 of all episodes API"
              return "release year and airdate are null for season 1 episode 1 of all episodes API"
            end
          else
            #log.info "this...."
            if (rel == rel_year_totest) || (rel == rel_year_totest-1) || (rel == rel_year_totest+1)
              log.info "release year from s1e1 in all episodesAPI matched and going to season episode api for episode validation"
              #log.info "#{sid}"
              #log.info "#{season_number_totest}"
              episodes_sn = JSON.parse(RestClient.get($base_url + "/programs/#{(sid)}/episodes?season_number=#{season_number_totest}", {:authorization => 'Token token=64becbd7666f73e6d825b9f3d9bf270a9fc3c5b2590df3da3d4cb65d77f0b2b0'}))
              # may need to remove season_number after checking with manjunath
              episodes_sn.each do |ro|
                ep_title = ro["episode_title"]
                ep_title = mod_title(ep_title);
                ep_org_title = mod_title(ep_org_title);
                ep_org_title = ro["original_episode_title"]
                if (ep_title == episode_title_totest_m) || (ep_org_title == episode_title_totest_m)
                  log.info "Debug6: "
                  return ro["id"]
                  break
                end
              end
            end
          end
        end
      end
    end
    return "wip"
    #log.info "hello"
  end


  def verify_series_episodes(sid,episode_title_totest_m,log)
    episodes_oz = JSON.parse(RestClient.get($base_url + "/programs/#{(sid)}/episodes", {:authorization => 'Token token=64becbd7666f73e6d825b9f3d9bf270a9fc3c5b2590df3da3d4cb65d77f0b2b0'}))
    if !episodes_oz.empty?
      episodes_oz.each do |ro|
        ep_title = ro["episode_title"]
        ep_title = mod_title(ep_title);
        ep_org_title = ro["original_episode_title"]
        ep_org_title = mod_title(ep_org_title);
        if (ep_title == episode_title_totest_m) || (ep_org_title == episode_title_totest_m)
          #log.info ("Murali: Direct series match and episode ID is returned")
          return ro["id"]
          break
        end
        #log.info "episode title under test is #{ep_title}"
        #log.info "All original episode title under test is #{ep_org_title}"
      end
    else
      log.info "All episodes api is Empty"
      #log.info ("Murali: Direct series match, season sequence Not Available")
      return "Series got mapped but All episodes api is Empty"
    end
    #log.info "Series got mapped but episode couldn't get mapped"
    return "Series got mapped but All episodes api is Empty"
  end




end