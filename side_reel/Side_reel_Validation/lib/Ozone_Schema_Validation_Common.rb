module OzoneSchemaValidationCommon

  def rovi_program_schema_validation()
    expect_json_types(:array)
    expect_json_types('*', $formatted_rovi_schema["expected_program_schema"])
    expect_json_types('*.description.*', optional($formatted_rovi_schema["expected_description_schema"]))
    expect_json_types('*.images.*', $formatted_rovi_schema["expected_images_schema"])
    expect_json_types('*.external_ratings.*', optional($formatted_rovi_schema["expected_external_ratings_schema"]))
    #expect_json_types('*.release_date.*', optional(formatted_rovi_schema["expected_releasedate_or_airdate_schema"]))
  end

  def rovi_program_episode_schema_validation()
    expect_json_types(:array)
    expect_json_types('*', $formatted_rovi_schema["expected_episode_schema"])
    expect_json_types('?.description.*', $formatted_rovi_schema["expected_description_schema"])
    expect_json_types('*.images.*', $formatted_rovi_schema["expected_images_schema"])
  end

  def generic_schema_validation(schema)
    expect_json_types(:array)
    expect_json_types('*', schema) 
  end

  def generic_search_schema_validation()
    expect_json_types(:array)
    expect_json_types('*', $formatted_search_schema["overall_schema"])
    expect_json_types('*.results.*', $formatted_search_schema["results_schema"])
  end

  def device_schema_validation()
    expect_json_types(:array)
    expect_json_types('*', $formatted_device_schema["overall_schema"])
    expect_json_types('?.logos.*', $formatted_device_schema["logos_schema"])
  end

  def program_search_schema_validation(json_body)
    $log.info "inside program search schema validation"
    expect_json_types(:array)
    expect_json_types('*', $formatted_search_schema["overall_schema"])
    expect_json_types('0.results.*', $formatted_search_schema["results_schema"])
    expect_json_types('0.results.*.object', $formatted_rovi_schema["expected_program_schema"])
    expect_json_types('0.results.*.object.images.*', $formatted_rovi_schema["expected_images_schema"])

    show_type = json_body[0][:results][0][:object][:show_type]
    $log.info "Show type: #{show_type}"
    if show_type == "SM"
        $log.info "Not checking schema for videos object, as show_type is SM<br>"
        if $params.include? "credit_summary"
          $log.info "Credits param present in api, hence checking credit schema<br>"
          expect_json_types('0.results.*.object.credits.*', $formatted_rovi_schema["expected_credits_schema"])
        end
    else
      $log.info "Inside program search schema, show_type is non SM"
      if $params.include? "credit_summary" and $params.include? "ott"
        $log.info "Inside both if credits & ott, checking credit summary & ott schema<br>"
        expect_json_types('0.results.*.object.credits.*', $formatted_rovi_schema["expected_credits_schema"])
        expect_json_types('0.results.*.object.videos.*', $formatted_rovi_schema["expected_ott_param_schema"])
      elsif $params.include? "ott"
        $log.info "Inside params include ott, checking ott schema<br>"
        expect_json_types('0.results.*.object.videos.*', $formatted_rovi_schema["expected_ott_param_schema"])
      elsif $params.include? "credit_summary"
        $log.info "Inside params include credtis, checking credit summary<br>"
        expect_json_types('0.results.*.object.credits.*', $formatted_rovi_schema["expected_credits_schema"])
      end  #end of nested if
    end #end of main if
  end

  def program_search_schema_validation_new(api_url,json_body,ott_search_index)
    $log.info "OzoneSchemaValidationCommon :: program_search_schema_validation_new"
    expect_json_types(:array)
    if api_url.include? "season" and api_url.include? "episode"
      $log.info "Episode specific search,check overall schema accordingly"
      expect_json_types('*', $formatted_graph_db_search_schema["specific_episode_overall_schema"])
    elsif api_url.include? "shows" or api_url.include? "movies"
      $log.info "Credit or genre search,check schema accordingly"
      expect_json_types('*', $formatted_graph_db_search_schema["overall_credit_or_genre_schema"])
    else  
      $log.info "Program search,check overall schema accordingly"
      expect_json_types('*', $formatted_graph_db_search_schema["overall_schema"])
    end
    expect_json_types("#{ott_search_index}.results.*", $formatted_graph_db_search_schema["results_schema"])
    #expect_json_types("#{ott_search_index}.results.*", $formatted_graph_db_search_schema["results_schema"])
    expect_json_types("#{ott_search_index}.results.*.object.images.*", $formatted_rovi_schema["expected_images_schema"])
    
    results = json_body[ott_search_index][:results]
    res_len = results.length

    for i in 0..res_len-1
      $log.info "Inside FOR loop: i-#{i}"
      show_type = results[i][:object][:show_type]
      $log.info "show_type: #{show_type}"
      if show_type == "SE"
        $log.info "Inside show_type:#{show_type}"
        expect_json_types("#{ott_search_index}.results.#{i}.object", $formatted_rovi_schema["expected_episode_schema"]) 
      else
        $log.info "Else show_type:#{show_type}"
        expect_json_types("#{ott_search_index}.results.#{i}.object", $formatted_rovi_schema["expected_program_schema"])
      end

      if show_type == "SM"
        $log.info "Not checking schema for videos object, as show_type is SM<br>"
        if api_url.include? "credit_summary"
          $log.info "Credits param present in api, hence checking credit schema<br>"
          expect_json_types("#{ott_search_index}.results.#{i}.object.credits.*", $formatted_rovi_schema["expected_credits_schema"])
        end
      else
        $log.info "Inside program search schema, show_type is non SM hence checking credit summary & ott videos schema<br>"
        if api_url.include? "&credit_summary" and api_url.include? "&ott"
          $log.info "Inside both if credits & ott, checking credit summary & ott schema<br>"
          expect_json_types("#{ott_search_index}.results.*.object.credits.*", $formatted_rovi_schema["expected_credits_schema"])
          expect_json_types("#{ott_search_index}.results.*.object.videos.*", $formatted_rovi_schema["expected_ott_param_schema"])
        elsif api_url.include? "&ott"
          $log.info "Inside params include ott, checking ott schema<br>"
          expect_json_types("#{ott_search_index}.results.*.object.videos.*", $formatted_rovi_schema["expected_ott_param_schema"])
        elsif api_url.include? "&credit_summary"
          $log.info "Inside params include credtis, checking credit summary<br>"
          expect_json_types("#{ott_search_index}.results.*.object.credits.*", $formatted_rovi_schema["expected_credits_schema"])
        end  #end of nested if
      end #end of main if
        
      watchlist_arr = results[i][:watchlist_availability]
      if !watchlist_arr.empty?
        $log.info "Watchlist array not empty, proceed to check schema"
        expect_json_types("#{ott_search_index}.results.#{i}.watchlist_availability.*", $formatted_graph_db_search_schema["watchlist_schema"])
        expect_json_types("#{ott_search_index}.results.#{i}.watchlist_availability.*.service", $formatted_search_schema["service_schema"])
        expect_json_types("#{ott_search_index}.results.#{i}.watchlist_availability.*.videos.*", $formatted_rovi_schema["expected_ott_param_schema"])
      else
        $log.info "Watchlist array empty, skip schema check"
      end
    end
  end

  # def epg_search_schema_validation_version3()
  #   expect_json_types('1.results.*', $formatted_search_new_schema['epg_overall_schema'])
  #   expect_json_types('1.results.*.reasons.*', $formatted_search_new_schema["epg_reasons_schema"])
  #   expect_json_types('1.results.*.reasons.*.airing', $formatted_spec_airing_schema["airing_schema"])
  #   expect_json_types('1.results.*.reasons.*.source', $formatted_search_new_schema["source_schema"])
  #   expect_json_types('1.results.*.reasons.*.headend', $formatted_now_ontv_schema["headend_schema"])
  # end

  def channel_search_by_name_schema_validation()
    expect_json_types(:array)
    expect_json_types('*', $formatted_search_schema["overall_schema"])
    expect_json_types('1.results.*', $formatted_search_schema["results_schema"])
    expect_json_types('1.results.*.object', $formatted_search_schema["channel_schema"])
    expect_json_types('1.results.*.object.images.*', $formatted_search_schema["images_schema"])
  end 

  def channel_search_schema_validation_version3(index)
    expect_json_types(:array)
    expect_json_types('*', $formatted_search_schema["overall_schema_old"])
    #expect_json_types("#{index}.results.*", $formatted_search_new_schema["results_schema"])
    expect_json_types("#{index}.results.*.object", $formatted_search_schema["channel_schema"])
    expect_json_types("#{index}.results.*.object.images.*", $formatted_search_schema["images_schema"])
  end


  def channel_search_new_schema_validation(index)
    expect_json_types(:array)
    expect_json_types("#{index}", $formatted_search_schema["overall_schema_non_ott_search_obj"])
    #expect_json_types("#{index}.results.*", $formatted_search_new_schema["results_schema"])
    expect_json_types("#{index}.results.*.object", $formatted_search_schema["channel_schema"])
    expect_json_types("#{index}.results.*.object.images.*", $formatted_search_schema["images_schema"])
  end

  def youtube_search_schema_validation()
    expect_json_types(:array)
    expect_json_types('*', $formatted_youtube_schema["overall_schema"])
    expect_json_types('*.images.*', $formatted_youtube_schema["images_schema"])
  end 

  def watchlist_schema_validation(api_url)
    expect_json_types($formatted_rovi_schema["expected_watchlist_schema"])    
    expect_json_types('feed.*', $formatted_rovi_schema["expected_program_schema"])
    expect_json_types('feed.?.description.*', optional($formatted_rovi_schema["expected_description_schema"]))
    expect_json_types('feed.*.images.*', $formatted_rovi_schema["expected_images_schema"])

    str_hbogo_watchlist = "hbogo/watchlist"
    str_hbogo_continue_watching = "hbogo/continue_watching"
    str_hbonow_watchlist = "hbonow/watchlist"
    str_hbonow_continue_watching = "hbonow/continue_watching"
    
    case api_url

    when /watchlists_movies/  #Amazon movies watchlist
      #expect_json_types('feed.*.external_ratings.*', $formatted_rovi_schema["expected_external_ratings_schema"])
    
    when /watchlists_tvs/     #Amazon tv watchlist
      expect_json_types('feed.?.tv_rating', $formatted_rovi_schema["expected_tv_rating_schema"])
      #expect_json_types('feed.*.external_ratings.*', $formatted_rovi_schema["expected_external_ratings_schema"])
    
    when /user_history/,/my_activity/      #Hulu user history watchlist   &    Netflix my activity watchlist
      expect_json_types('feed.?.tv_rating', $formatted_rovi_schema["expected_tv_rating_schema"])
      #expect_json_types('feed.*.external_ratings.?', $formatted_rovi_schema["expected_external_ratings_schema"])
      #expect_json_types('feed.?.release_date.*', optional(formatted_schema["expected_releasedate_or_airdate_schema"]))
      #expect_json_types('feed.?.other_episodes.*', $formatted_wl_ep_schema)
      #expect_json_types('feed.?.episodes.*.air_date.*', optional(formatted_schema["expected_releasedate_or_airdate_schema"]))
    
    when /user_queue/,/my_tv/         #Hulu user queue watchlist & Vudu mytv watchlist
      expect_json_types('feed.?.tv_rating', $formatted_rovi_schema["expected_tv_rating_schema"])
      #expect_json_types('feed.*.external_ratings.?', $formatted_rovi_schema["expected_external_ratings_schema"])
      #expect_json_types('feed.?.episodes.*', $formatted_wl_ep_schema)
      #expect_json_types('feed.?.episodes.*.air_date.*', formatted_schema["expected_releasedate_or_airdate_schema"]) 

    # when /my_activity/
    #   expect_json_types('feed.?.tv_rating', formatted_schema["expected_tv_rating_schema"])
    #   expect_json_types('feed.*.external_ratings.*', formatted_schema["expected_external_ratings_schema"])
    #   expect_json_types('feed.?.release_date.*', formatted_schema["expected_releasedate_or_airdate_schema"]) 
    #   expect_json_types('feed.?.other_episodes.*', formatted_wl_ep_schema)

    when /my_list/,/watch_next/           #Netflix my list watchlist
      $log.info "Case: When netflix mylist or amazon watch_next"
      #expect_json_types('feed.*.external_ratings.*', $formatted_rovi_schema["expected_external_ratings_schema"])
      #expect_json_types('feed.?.air_date.*', $formatted_rovi_schema["expected_releasedate_or_airdate_schema"])  
      #expect_json_types('feed.?.release_date.*', $formatted_rovi_schema["expected_releasedate_or_airdate_schema"]) 

    when /my_movies/
      #expect_json_types('feed.*.external_ratings.*', $formatted_rovi_schema["expected_external_ratings_schema"])
      #expect_json_types('feed.?.release_date.*', $formatted_rovi_schema["expected_releasedate_or_airdate_schema"])  

    when /my_wishlist/
      expect_json_types('feed.?.tv_rating', $formatted_rovi_schema["expected_tv_rating_schema"])
      expect_json_types('feed.*.external_ratings.*', $formatted_rovi_schema["expected_external_ratings_schema"])
      # expect_json_types('feed.?.air_date.*', $formatted_rovi_schema["expected_releasedate_or_airdate_schema"])  
      # expect_json_types('feed.?.release_date.*', $formatted_rovi_schema["expected_releasedate_or_airdate_schema"]) 
      # expect_json_types('feed.?.episodes.*', $formatted_rovi_schema["expected_episode_schema"])
      # expect_json_types('feed.?.episodes.*.air_date.*', $formatted_rovi_schema["expected_releasedate_or_airdate_schema"])   
      # expect_json_types('feed.?.episodes.*.external_ratings.*', $formatted_rovi_schema["expected_external_ratings_schema"]) 

    when /#{str_hbogo_watchlist}/,/#{str_hbonow_watchlist}/
      #$log.info "Inside hbo watchlist!!!"
      # expect_json_types('feed.*.external_ratings.*', $formatted_rovi_schema["expected_external_ratings_schema"])   
      # expect_json_types('feed.?.episodes.*', $formatted_wl_ep_schema)    

    when /#{str_hbogo_continue_watching}/,/#{str_hbonow_continue_watching}/
      #$log.info "Inside hbo continue watching!!!"
      # expect_json_types('feed.*.external_ratings.*', $formatted_rovi_schema["expected_external_ratings_schema"])   
      # expect_json_types('feed.?.other_episodes.*', $formatted_wl_ep_schema)          

    end 

    if api_url.include? "credit_summary=true" and api_url.include? "ott=true"
      $log.info "inside if credits & ott"
      expect_json_types('feed.*.credits.*', $formatted_rovi_schema["expected_credits_schema"])  
      expect_json_types('feed.*.videos.*', $formatted_rovi_schema["expected_ott_param_schema"])
    elsif api_url.include? "credit_summary=true"
      $log.info "inside elsif credits"
      expect_json_types('feed.*.credits.*', $formatted_rovi_schema["expected_credits_schema"])
    elsif api_url.include? "ott=true"
      $log.info "inside elsif ott"
      expect_json_types('feed.*.videos.*', $formatted_rovi_schema["expected_ott_param_schema"])
    else
      $log.info "Do nothing bcoz no credit nor ott param"
    end
  end

  def now_ontv_schema_validation()
    expect_json_types('*.program', $formatted_now_ontv_schema["program_schema"])
    expect_json_types('?.program.description.*', $formatted_rovi_schema["expected_description_schema"])
    expect_json_types('*.program.images.*', $formatted_rovi_schema["expected_images_schema"])
    expect_json_types('*.program.external_ratings.*', optional($formatted_rovi_schema["expected_external_ratings_schema"]))
    expect_json_types('*.reasons.*', $formatted_now_ontv_schema["reasons_schema"])
    expect_json_types('*.reasons.*.airing', $formatted_now_ontv_schema["airing_schema"])
    expect_json_types('*.reasons.*.source', $formatted_now_ontv_schema["source_schema"])
    expect_json_types('*.reasons.*.source.images.*', $formatted_now_ontv_schema["images_schema"])
    expect_json_types('*.reasons.*.headend', $formatted_now_ontv_schema["headend_schema"])
  end

  def headend_schema_validation(device)
    expect_json_types(:object)
    if device == ""
      expect_json_types("all_headends.*.headend", $formatted_headend_schema["headend"])
      expect_json_types("all_headends.*.mso", $formatted_headend_schema["mso"])
    else
      expect_json_types("#{device}.*.headend", $formatted_headend_schema["headend"])
      expect_json_types("#{device}.*.mso", $formatted_headend_schema["mso"])
    end
  end

  def dvr_schema_validation()
    expect_json_types(:array)
    expect_json_types('*', $formatted_dvr_schema["schema_without_rovi_mapping"])
    expect_json_types('?', $formatted_dvr_schema["schema_for_rovi_mapped_programs"])
  end

  def dvr_search_schema_validation()
    expect_json_types(:array)
    expect_json_types('*', $formatted_dvr_schema["schema_for_dvr_search"])
    expect_json_types('*.dvr_video', $formatted_dvr_schema["schema_for_dvr_video"])
  end

  def dvr_search_schema_new_validation(dvr_search_indx)
    expect_json_types(:array)
    expect_json_types("#{dvr_search_indx}.results.*.object", $formatted_dvr_schema["schema_for_dvr_search"])
    expect_json_types("#{dvr_search_indx}.results.*.object.dvr_video", $formatted_dvr_schema["schema_for_dvr_video"])
  end

  def generic_search_schema_validation_version3()
    expect_json_types(:array)
    expect_json_types('*', $formatted_search_schema["overall_schema_old"])
    expect_json_types('*.results.*', $formatted_search_schema["results_schema"])
  end

  def generic_search_schema_validation_new()
    expect_json_types(:array)
    expect_json_types('*', $formatted_search_schema["overall_schema"])
    expect_json_types('*.results.*', $formatted_search_schema["results_schema"])
  end

  def service_search_schema_validation(object_index)
    expect_json_types("#{object_index}", $formatted_search_schema["overall_schema_non_ott_search_obj"])
    expect_json_types("#{object_index}.results.?.object", $formatted_search_schema["service_schema"])
  end

  def device_search_schema_validation(object_index)
    expect_json_types("#{object_index}", $formatted_search_schema["overall_schema_non_ott_search_obj"])
    expect_json_types("#{object_index}.results.?.object", $formatted_search_schema["device_schema"])
    expect_json_types("#{object_index}.results.?.object.logos.*", optional($formatted_search_schema["logos_schema"]))
  end

  # def search_version3_schema_validation(json)
  #   json_array_count = json.length
  #   if json[1][":action_type"] == "epg_search"
  #     epg_search_schema_validation_version3()
  #     if json[2][":action_type"] == "switch"
  # end

  def switches_device_schema_validation(type=nil)
    expect_json_types(:array)
    if type == "none"
      expect_json_types('?', $formatted_switches_devices_apps_schema["unconfigured_device_schema"])
    else
      expect_json_types('?', $formatted_switches_devices_apps_schema["unconfigured_device_schema"])
      expect_json_types('?', $formatted_switches_devices_apps_schema["configured_device_schema"])
      expect_json_types('?.logos.*', $formatted_device_schema["logos_schema"])
    end
  end

  def switches_apps_schema_validation()
    expect_json_types(:array)
    expect_json_types('*', $formatted_switches_devices_apps_schema["overall_apps_schema"])
    expect_json_types('*.devices.*', $formatted_switches_devices_apps_schema["apps_device_overall_schema"])
    expect_json_types('*.devices.*.device', $formatted_switches_devices_apps_schema["apps_device_schema"])
    expect_json_types('*.devices.*.device.logos.*', $formatted_device_schema["logos_schema"])
  end

end
