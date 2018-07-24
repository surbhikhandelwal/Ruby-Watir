require 'active_support/inflector'

module OzoneJsonResponseDataValidationCommon

	def if_empty_json_response_raise_error(json_body)	
	    if json_body == []
	      raise "Empty response received, throwing out an error<br>"
	    end
  	end

	def response_data_validatiion_for_rovi_programs(json_data_filtered_for_mandatory_fields,show_name)
		filtered_final_val = json_data_filtered_for_mandatory_fields
		len = filtered_final_val.length
    for i in 0..len-1
      #images_with_filtered_fields = Array.new
      #images_with_filtered_fields = filtered_final_val[i][:images]
      filtered_final_val[i].delete(:images)
      #$log.info "Going to check program with the expected response values: #{filtered_final_val[i]}<br>"
      expect_json("#{i}", filtered_final_val[i])
      $log.info "Validated object#{i} for all mandatory fields except images<br>"
      # len_img_arr = images_with_filtered_fields.length
      # for j in 0..len_img_arr-1
      #   $log.info "Going to check image with the expected response: #{images_with_filtered_fields[j]}"
      #   expect_json("#{i}.images.?", images_with_filtered_fields[j])
      #   $log.info "image with url '#{images_with_filtered_fields[j][:url]}' validated, moving to next image(if any)"
      # end
      $log.info "Validated object num #{i} completely ,moving to next object(if any)<br>"
    end
  	$log.info "Validated '#{show_name}', proceeding to next dataset(if any<br>"
  end

  def response_data_validation_for_devices(json_data_filtered_for_mandatory_fields)
  	filtered_final_val = json_data_filtered_for_mandatory_fields
  	len = filtered_final_val.length
    for i in 0..len-1
      expect_json("#{i}", filtered_final_val[i])
      $log.info "Device with name '#{filtered_final_val[i][:name]}' validated, proceeding to next dataset(if any)<br>"
    end
  end

  def response_validation_for_original_title_of_first_search_object(json_data_filtered_for_mandatory_fields)
  	filtered_final_val = json_data_filtered_for_mandatory_fields
  	#images_with_filtered_fields = Array.new
      #images_with_filtered_fields = filtered_final_val[0][:images]
      #filtered_final_val[0].delete(:images)  
      #expect_json("0.results.0.object", filtered_final_val[0])
      $log.info "Comparing expected val of program title: #{filtered_final_val[0][:original_title]}<br>"   
      expect_json("0.results.0.object.original_title", filtered_final_val[0][:original_title])
      #$log.info "Validated '#{show_name}' which is the 0th object of the search response, for original title only"
      #$log.info "Validated '#{show_name}' which is the 0th object of the search response, for all mandatory fields except images, now going to check the images"
=begin        
      len_img_arr = images_with_filtered_fields.length
      for i in 0..len_img_arr-1
        expect_json("0.results.0.object.images.?", images_with_filtered_fields[i])
        $log.info "'#{show_name}' image with url '#{images_with_filtered_fields[i][:url]}' validated, moving to next image(if any)"
      end
=end	
  end

  def response_validation_for_first_search_object(json_data_filtered_for_mandatory_fields,json_body,ott_search_index)
    $log.info "OzoneJsonResponseDataValidationCommon :: response_validation_for_first_search_object"
    ott_search_first_index = nil
    filtered_final_val = json_data_filtered_for_mandatory_fields
    results = json_body[ott_search_index][:results]
    res_len = results.length

    for i in 0..res_len-1
      $log.info "Inside FOR loop: i-#{i}"
      watchlist_arr = results[i][:watchlist_availability]
      if watchlist_arr.empty?
        $log.info "Watchlist array empty, proceed to compare titles of the object"
        expect_json("#{ott_search_index}.results.#{i}.object.original_title", filtered_final_val[0][:original_title])
        expect_json("#{ott_search_index}.results.#{i}.object.long_title", filtered_final_val[0][:long_title])
        ott_search_first_index = i
        break
      else
        $log.info "Watchlist array not empty, hence a watchlist search result. Skip to next"
      end
    end
    $log.info "FOR loop >>"
    $log.info "response_validation_for_first_search_object >>"
    ott_search_first_index
  end

  def watchlist_search_response_validation(service,prog_details,json_body,ott_search_index)
    $log.info "OzoneJsonResponseDataValidationCommon :: watchlist_search_response_validation"

    results = json_body[ott_search_index][:results]
    res_len = results.length
    if res_len == 1
      if api.include? "play" or api.include? "watch" or api.include? "resume"
        expect_json("#{ott_search_index}.play",true)
      else
        expect_json("#{ott_search_index}.play",false)
      end
    end
    i = 0

    results.each do |result_obj|

      $log.info "Inside FOR loop: i-#{i}"

      $log.info "Result Object: #{result_obj}"
      result = result_obj[:object]

      show_type = prog_details["show_type"]
      $log.info "show_type: #{show_type}"

      if show_type == "SE"
        res_id = result[:series_id]
        $log.info "Result Series id: #{res_id}"
      elsif show_type == "MO"
        res_id = result[:id]
        $log.info "Result Movie id: #{res_id}"
      end
      res_name = result[:long_title]
      $log.info "Result Prog name #{res_name}"

      prog_id = prog_details["id"] 
      $log.info "prog_id: #{prog_id}"

      prog_name = prog_details["name"]
      $log.info "prog_name: #{prog_name}"

      res_show_type = result[:show_type]
      $log.info "res_show_type: #{res_show_type}"

      if res_id == prog_id and res_name == prog_name and res_show_type == show_type
        $log.info "Match found wrt prog id,name and show type, going to see if its a watchlist object"
        watchlist_arr = result_obj[:watchlist_availability]
        if !watchlist_arr.empty?
          $log.info "It is a watchlist object!!!. Lets go!"
          watchlist_arr.each do |res_wl_obj|
            res_wl_obj_serv = res_wl_obj[:service][:id]
            $log.info "res_wl_obj_serv: #{res_wl_obj_serv}"
            $log.info "service: #{service}"
            if service == "netflix"
              service = "netflixusa"
            end
            if service == res_wl_obj_serv
              $log.info "Service name matching, proceed to check more details"
              
              case show_type

              when "SE"
                $log.info "CASE Prog type: SE"
                # res_episode_title = result[:original_episode_title]
                # $log.info "res_episode_title: #{res_episode_title}"
                # episode_title = prog_details["episode_title"]
                # $log.info "episode_title: #{episode_title}"
                # expect(episode_title).to eq(res_episode_title)
                res_season_num = result[:episode_season_number]
                season_number = prog_details["season_num"]
                expect(season_number).to eq(res_season_num)
                #season_number.eql? res_season_num
                res_episode_num = result[:episode_season_sequence]
                episode_number = prog_details["episode_num"]
                expect(episode_number).to eq(res_episode_num)
                #episode_number.eql? res_episode_num
              when "MO"
                $log.info "CASE Prog type: MO"
                res_rel_year = result[:release_year]
                rel_year = prog_details["rel_year"]
                #!rel_year.eql? res_rel_year
                expect(rel_year).to eq(res_rel_year)
              end
              $log.info "Watchlist search returns result in #{i} index"
              indx = i
              break
            end
          end
          break
        else
          next
        end
      else
        next
      end
      i += 1
    end
    $log.info "FOR loop >>"
  end

  def response_validation_for_first_search_object_for_play_intent(json_data_filtered_for_mandatory_fields,exp_show_type,json_body,ott_search_index)
    $log.info "OzoneJsonResponseDataValidationCommon :: response_validation_for_first_search_object_for_play_intent"
    filtered_final_val = json_data_filtered_for_mandatory_fields
    results = json_body[ott_search_index][:results]
    res_len = results.length

    show_name = filtered_final_val[0][:long_title]
    $log.info "Going to check if play property is true"
    #expect_json("#{ott_search_index}.play", true)
    #$log.info "Going to check if play entity is equal to #{show_name.downcase}"
    #expect_json("#{ott_search_index}.entity", show_name.downcase)

    if res_len == 1
      $log.info "Inside result length must be 1 for play intent"
      watchlist_arr = results[0][:watchlist_availability]
      show_type_resp = results[0][:object][:show_type]
      if watchlist_arr.empty?
        $log.info "Watchlist array empty, proceed to compare titles of the object"
        if show_type_resp == exp_show_type
          $log.info "Show type of first object matching with expected show type: #{exp_show_type}"
          expect_json("#{ott_search_index}.results.0.object.original_title", filtered_final_val[0][:original_title])
          expect_json("#{ott_search_index}.results.0.object.long_title", filtered_final_val[0][:long_title])
          if show_type_resp == "SE"
            $log.info "Show type is SE, hence going to check if this episode of season 1 and episode 1"
            expect_json("#{ott_search_index}.results.0.object.episode_season_number", 1)
            expect_json("#{ott_search_index}.results.0.object.episode_season_sequence", 1)
          end
        else
          $log.info "Show type of first object in response-#{show_type_resp} not matching with expected show type: #{exp_show_type}"
          raise "Show type of first object in response-#{show_type_resp} not matching with expected show type: #{exp_show_type}"
        end
      else
        $log.info "Watchlist array not empty, hence this search query returns watchlist object in search result"
        #raise "Watchlist search coning as part of play search which is not expected"
      end
    end
    $log.info "response_validation_for_first_search_object_for_play_intent >>"
  end

  def response_validation_for_specific_episode_play_or_search(api_url,individual_episode,ott_search_index)
    $log.info "OzoneJsonResponseDataValidationCommon :: response_validation_for_specific_episode_play"
    episode_num = individual_episode[:episode_season_sequence]
    season_num = individual_episode[:episode_season_number]
    show_name = individual_episode[:long_title]
    air_dates = individual_episode[:air_date]
    individual_episode.delete(:air_date)
    $log.info "Going to check if play property is true"
    # if api_url.include? "play"
    #   expect_json("#{ott_search_index}.play", true)
    # else
    #   expect_json("#{ott_search_index}.play", false)
    # end
    show_name = prepare_for_search_comparison(show_name)
    # $log.info "Going to check if entity is equal to #{show_name.downcase}"
    # expect_json("#{ott_search_index}.entity", show_name.downcase)
    $log.info "Going to check entire episode #{episode_num} response values with: #{individual_episode}"
    expect_json("#{ott_search_index}.results.0.object", individual_episode)
    $log.info "Going to check episode #{episode_num} US air date with: #{air_dates[0]}"
    expect_json("#{ott_search_index}.results.0.object.air_date.0",air_dates[0])
    $log.info "Validated '#{show_name}': Season #{season_num} Episode #{episode_num}"
    $log.info "response_validation_for_specific_episode_play >>"
  end

  def response_validation_for_genre_specific_search(json_body,genre_name,show_type,ott_search_index)
    $log.info "OzoneJsonResponseDataValidationCommon :: response_validation_for_genre_specific_search"
    index_of_epg_search_obj = nil
    ott_objects_list = json_body[ott_search_index][:results]
    ott_objects_list.each do |ott_object|
      genres = ott_object[:object][:genres]
      final_genres = Array.new
      genres.each do |ind_genre|
        ind_genre = ind_genre.downcase
        final_genres.push(ind_genre)
      end
      $log.info "Genres after downcase: #{final_genres}"
      if final_genres.include? genre_name
        $log.info "#{genre_name} part of genres of program: #{ott_object[:object][:long_title]}"
      else
        raise "#{genre_name} not part of genres of program: #{ott_object[:object][:long_title]}, genres coming for this program are: #{final_genres}"
      end
    end
    json_arr = json_body.length
    for i in 0..json_arr-1
      $log.info "action type: #{json_body[i][:action_type]}"
      if json_body[i][:action_type] == "epg_search"
        index_of_epg_search_obj = i
        break
      end
    end
    if !index_of_epg_search_obj.nil?
      $log.info "Epg search index present, proceed to check if epg objects are of genre: #{genre_name}"
      epg_objects_list = json_body[index_of_epg_search_obj][:results]
      epg_objects_list.each do |epg_object|
        epg_genres = epg_object[:object][:genres]
        final_epg_genres = Array.new
        epg_genres.each do |ind_epg_genre|
          ind_epg_genre = ind_epg_genre.downcase
          final_epg_genres.push(ind_epg_genre)
        end
        $log.info "Genres after downcase: #{final_epg_genres}"
        if final_epg_genres.include? genre_name
          $log.info "#{genre_name} part of genres of epg program: #{epg_object[:object][:long_title]}"
        else
          raise "#{genre_name} not part of genres of epg program: #{epg_object[:object][:long_title]}, genres coming for this epg program are: #{final_epg_genres}"
        end
      end
    end
    $log.info "response_validation_for_genre_specific_search >>"
  end

  def response_validation_for_credit_specific_search(json_body,credit_name,show_type,ott_search_index)
    $log.info "OzoneJsonResponseDataValidationCommon :: response_validation_for_credit_specific_search"
    index_of_epg_search_obj = nil
    final_credit_name = nil
    movie_title = nil
    ott_objects_list = json_body[ott_search_index][:results]
    $log.info "Length of ott search results: #{ott_objects_list.length}"
    ott_objects_list.each do |ott_object|
      #$log.info "#{ott_object}"
      movie_title = ott_object[:object][:long_title]
      $log.info "Program Name: #{movie_title}, going to check if credit '#{credit_name}' is part of credits for this program"
      credit_available_ott_search = nil
      credits = ott_object[:object][:credits]
      credits.each do |ind_credit|  
        $log.info "Individual credit before transliteration is #{ind_credit}"
        final_credit_name = ActiveSupport::Inflector.transliterate(ind_credit[:full_credit_name]).to_s.downcase 
        $log.info "Final credit name after transliteration is #{final_credit_name}"
        #$log.info "Going to check credit #{ind_credit[:full_credit_name].downcase} with #{credit_name.downcase}"
        #if ind_credit[:full_credit_name].downcase == credit_name.downcase
        if final_credit_name == credit_name.downcase
          $log.info "Match found, break loop"
          credit_available_ott_search = true
          break
        else
          $log.info "Match not found, moving to next credit"
        end
      end
      # next
      if credit_available_ott_search.nil?
        if final_credit_name == "ann-margret"
          $log.info "Special case of movie #{movie_title}: where the celebrity is :#{final_credit_name} and the credits are not available for thie movie.Rovi Issue more than ours!!"
        else
          $log.info "Credit '#{credit_name}' not available in the program with name: #{movie_title}"
          raise "Credit '#{credit_name}' not available in the program with name: #{movie_title}"
        end
      end
    end
    json_arr = json_body.length
    for i in 0..json_arr-1
      $log.info "action type: #{json_body[i][:action_type]}"
      if json_body[i][:action_type] == "epg_search"
        index_of_epg_search_obj = i
        break
      end
    end
    if !index_of_epg_search_obj.nil?
      $log.info "Epg search index present, proceed to check if epg objects are of credit: #{credit_name}"
      epg_objects_list = json_body[index_of_epg_search_obj][:results]
      epg_objects_list.each do |epg_object|
        credit_available_epg_search = nil
        epg_credits = epg_object[:object][:credits]
        epg_credits.each do |ind_epg_credit|
          $log.info "Individual credit before transliteration is #{ind_epg_credit}"
          final_epg_credit_name = ActiveSupport::Inflector.transliterate(ind_epg_credit[:full_credit_name]).to_s.downcase 
          $log.info "Final credit name after transliteration is #{final_epg_credit_name}"
          $log.info "Going to check credit #{final_epg_credit_name} with #{credit_name.downcase}"
          if final_epg_credit_name == credit_name.downcase
            $log.info "Match found of credit in epg search, break loop"
            credit_available_epg_search = true
            break
          else
            $log.info "Match not found, moving to next credit"
          end
        end
        if credit_available_epg_search.nil?
          $log.info "Credit '#{credit_name}' not available in the program with name: #{epg_object[:object][:long_title]}"
          raise "Credit '#{credit_name}' not available in the program with name: #{epg_object[:object][:long_title]}"
        end
      end
    end
    $log.info "response_validation_for_credit_specific_search >>"
  end

  def credit_summary_response_validation(credits_data,json_body)
    if $params.include? "credit_summary"
      $log.info "Inside Credit summary response validation<br>"
      if !credits_data.nil?
        #$log.info "Valid credits data! Lets go!<br>"
        credits_val = prepare_response_data_to_match_airborne_format(credits_data)
        $log.info "Credits value of 3 main characters: #{credits_val}<br>"
        credits_val_len = credits_val.length

        array_of_credit_objects = json_body[0][:results][0][:object][:credits]
        array_of_non_unique_credit_objects = array_of_credit_objects.uniq!

        #$log.info "Array of credits: #{array_of_credit_objects}"
        #$log.info "Array of credits which are not unique: #{array_of_non_unique_credit_objects}"

        if array_of_non_unique_credit_objects.nil?
          $log.info "All credits objects are unique, proceeding to check the credit values"
          for i in 0..credits_val_len-1
            $log.info "Credit going to be checked: #{credits_val[i]}"
            expect_json("0.results.0.object.credits.?", credits_val[i])
          end
          $log.info "Validated first 3 credit values"
        else
          raise "Duplicate credits found, raising exception"
        end
        $log.info "Credit summary response validation done<br>"
      else
        $log.info "Credits data nil. Skipping credits validation<br>"
      end
    end
  end

    def credit_summary_response_validation_new(credits_data,json_body,ott_search_index,first_index)
    if $params.include? "credit_summary"
      $log.info "Inside Credit summary response validation<br>"
      if !credits_data.nil?
        #$log.info "Valid credits data! Lets go!<br>"
        credits_val = prepare_response_data_to_match_airborne_format(credits_data)
        $log.info "Credits value of 3 main characters: #{credits_val}<br>"
        credits_val_len = credits_val.length

        if !first_index.nil?
          $log.info "First index: #{first_index}"
          array_of_credit_objects = json_body[ott_search_index][:results][first_index][:object][:credits]
          array_of_non_unique_credit_objects = array_of_credit_objects.uniq!
          $log.info "Array of credits: #{array_of_credit_objects}"
          $log.info "Array of credits which are not unique: #{array_of_non_unique_credit_objects}"
          if array_of_non_unique_credit_objects.nil?
            $log.info "All credits objects are unique, proceeding to check the credit values"
            for i in 0..credits_val_len-1
              $log.info "Credit going to be checked: #{credits_val[i]}"
              expect_json("#{ott_search_index}.results.#{first_index}.object.credits.?", credits_val[i])
            end
            $log.info "Validated first 3 credit values"       
          else
            raise "Duplicate credits found, raising exception"
          end
          $log.info "Credit summary response validation done<br>"
        end
      else
        $log.info "Credits data nil. Skipping credits validation<br>"
      end
    end
  end

  def response_validation_for_channel_search(final_val)
  	channel_list_len = final_val[1][:results].length
  	$log.info "No of channels to be returned in search : #{channel_list_len}"
  	for i in 0..channel_list_len-1
    	expect_json("1.results.#{i}.object_type", final_val[1][:results][i][:object_type])
    	$log.info "Validation of object type done, proceeding to validation of objects i.e channels<br>"
      final_val[1][:results][i][:object].delete(:images)
      #$log.info "Going to check channel with the expected response values: #{final_val[1][:results][i][:object]}"
      expect_json("1.results.?.object", final_val[1][:results][i][:object])
      $log.info "Channel number: #{final_val[1][:results][i][:object][:channel_number]} with call letter: '#{final_val[1][:results][i][:object][:call_letters]}' & full name:'#{final_val[1][:results][i][:object][:full_name]}' validated, proceeding to next channel validation<br><br>"
  	end
  end

  def response_validation_for_channel_search_version3(final_val,index_runtime,index_expected)
    switch_result = final_val[index_expected][:results]
    channel_list_len = switch_result.length
    $log.info "No of channels to be returned in search : #{channel_list_len}<br>"
    for i in 0..channel_list_len-1
      expect_json("#{index_runtime}.results.#{i}.object_type", switch_result[i][:object_type])
      $log.info "Validation of object type done, proceeding to validation of objects i.e channels<br>"
      switch_result[i][:object].delete(:images)
      #$log.info "Going to check channel with the expected response values: #{final_val[1][:results][i][:object]}"
      expect_json("#{index_runtime}.results.?.object", switch_result[i][:object])
      $log.info "Channel number: #{switch_result[i][:object][:channel_number]} with call letter: '#{switch_result[i][:object][:call_letters]}' & full name:'#{switch_result[i][:object][:full_name]}' validated, proceeding to next channel validation<br><br>"
    end
  end 

  def response_validation_for_channel_search_new(api,final_val,index_runtime,index_expected)
    $log.info "index_expected: #{index_expected}"
    switch_result = final_val[index_expected][:results]
    channel_list_len = switch_result.length
    expect_json("#{index_runtime}.action_type","tune")
    # if api.include? "tune"
    #   expect_json("#{index_runtime}.auto",true)
    # else
    #   expect_json("#{index_runtime}.auto",false)
    # end
    $log.info "No of channels to be returned in search : #{channel_list_len}<br>"
    for i in 0..channel_list_len-1
      expect_json("#{index_runtime}.results.#{i}.object_type", switch_result[i][:object_type])
      $log.info "Validation of object type done, proceeding to validation of objects i.e channels<br>"
      switch_result[i][:object].delete(:images)
      $log.info "Going to check channel with the expected response values: #{switch_result[i][:object]}"
      expect_json("#{index_runtime}.results.?.object", switch_result[i][:object])
      $log.info "Channel number: #{switch_result[i][:object][:channel_number]} with call letter: '#{switch_result[i][:object][:call_letters]}' & full name:'#{switch_result[i][:object][:full_name]}' validated, proceeding to next channel validation<br><br>"
    end
  end

  def populate_hash_of_services(hash_to_populate,json_body)
    array_of_video_objects = json_body[0][:results][0][:object][:videos]
    array_of_video_objects_len = array_of_video_objects.length
    for i in 0..array_of_video_objects_len-1
      service_name = array_of_video_objects[i][:source_id] 
      if $conf['all_services'].include? service_name   
        hash_to_populate[service_name].push(array_of_video_objects[i][:launch_id])
      else
        $log.info "Service #{service_name} not supported by caavo, hence skipping to next object.<br>"
      end
    end
  end

  def populate_hash_of_services_new(hash_to_populate,json_body,ott_search_index,first_index)
    $log.info "OzoneJsonResponseDataValidationCommon :: populate_hash_of_services_new"
    array_of_video_objects = json_body[ott_search_index][:results][first_index][:object][:videos]
    array_of_video_objects_len = array_of_video_objects.length
    for i in 0..array_of_video_objects_len-1
      $log.info "Inside FOR loop: i-#{i}"
      service_name = array_of_video_objects[i][:source_id] 
      if $conf['all_services'].include? service_name   
        $log.info "Service is part of caavo supported services, push to hash of launch ids"
        hash_to_populate[service_name].push(array_of_video_objects[i][:launch_id])
      else
        $log.info "Service #{service_name} not supported by caavo, hence skipping to next object.<br>"
      end
    end
    $log.info "populate_hash_of_services_new >> "
  end

  def all_services_ott_launch_ids_response_capturing(json_body)
    if $params.include? "&ott="
      $log.info "Ott launch ids response capturing<br>"
      populate_hash_of_services($all_ott_services_launch_ids,json_body)
      $log.info "Complete set OTT services associated: #{$all_ott_services_launch_ids}<br>"
    else
      $log.info "all_services_ott_launch_ids_response_capturing: No ott param, skipping<br>"
    end
  end

  def all_services_ott_launch_ids_response_capturing_new(json_body,ott_search_index,first_index)
    if $params.include? "&ott="
      $log.info "Ott launch ids response capturing<br>"
      populate_hash_of_services_new($all_ott_services_launch_ids,json_body,ott_search_index,first_index)
      $log.info "Complete set OTT services associated: #{$all_ott_services_launch_ids}<br>"
    else
      $log.info "all_services_ott_launch_ids_response_capturing: No ott param, skipping<br>"
    end
  end

  def check_if_response_is_subset_of_ott_true_response(json_body,random_service)
    if $params.include? "&ott="
      ott_launch_ids_for_one_random_service = {"amazon"=>[],"hbogo"=>[],"hulu"=>[],"netflix"=>[],"showtimeanytime"=>[],"showtime"=>[],"hbonow"=>[],"vudu"=>[],"youtube"=>[]}
      populate_hash_of_services(ott_launch_ids_for_one_random_service,json_body)
      $log.info "Ott launch ids for only #{random_service} is: #{ott_launch_ids_for_one_random_service}<br>"
      $log.info "Ott launch ids captured with only ott param: #{$all_ott_services_launch_ids}<br>"
      result = (ott_launch_ids_for_one_random_service[random_service]-$all_ott_services_launch_ids[random_service]).empty?
      if result == true
        $log.info "Response is a subset of the main response<br>"
      else
        raise "Response of service=#{random_service} not subset of main response, raising error!"
      end
    else
      $log.info "check_if_ott_launch_ids_subset_of_ott_true_response:: No ott param, skipping<br>"
    end 
  end

  def check_if_response_is_subset_of_ott_true_response_new(json_body,random_service,ott_search_index,first_index)
    $log.info "OzoneJsonResponseDataValidationCommon :: check_if_response_is_subset_of_ott_true_response_new"
    if $params.include? "&ott="
      ott_launch_ids_for_one_random_service = {"amazon"=>[],"hbogo"=>[],"hulu"=>[],"netflix"=>[],"showtimeanytime"=>[],"showtime"=>[],"hbonow"=>[],"vudu"=>[],"youtube"=>[]}
      populate_hash_of_services_new(ott_launch_ids_for_one_random_service,json_body,ott_search_index,first_index)
      $log.info "Ott launch ids for only #{random_service} is: #{ott_launch_ids_for_one_random_service}<br>"
      $log.info "Ott launch ids captured with only ott param: #{$all_ott_services_launch_ids}<br>"
      result = (ott_launch_ids_for_one_random_service[random_service]-$all_ott_services_launch_ids[random_service]).empty?
      if result == true
        $log.info "Response is a subset of the main response<br>"
      else
        raise "Response of service=#{random_service} not subset of main response, raising error!"
      end
    else
      $log.info "check_if_ott_launch_ids_subset_of_ott_true_response:: No ott param, skipping<br>"
    end 
    $log.info "check_if_response_is_subset_of_ott_true_response_new >>"
  end

  def compare_ott_launch_ids_with_ott_true_response(json_body)
    if $params.include? "&ott="
      ott_launch_ids_with_all_combinations_of_services = {"amazon"=>[],"hbogo"=>[],"hulu"=>[],"netflix"=>[],"showtimeanytime"=>[],"showtime"=>[],"hbonow"=>[],"vudu"=>[],"youtube"=>[]}
      populate_hash_of_services(ott_launch_ids_with_all_combinations_of_services,json_body)
      $log.info "Ott launch ids of Combination of services: #{ott_launch_ids_with_all_combinations_of_services}<br>"
      $log.info "Ott launch ids which was captured earlier with only ott param:#{$all_ott_services_launch_ids}"
      if ott_launch_ids_with_all_combinations_of_services == $all_ott_services_launch_ids
        $log.info "Ott launch id test passed for combination of services<br>"
      else
        raise "Combination of services not matching with ott=true launch id,raising error!"
      end
    else
      $log.info "compare_ott_launch_ids_with_ott_true_response:: No ott param, skipping<br>"
    end 
  end 

  def compare_ott_launch_ids_with_ott_true_response_new(json_body,ott_search_index,first_index)
    $log.info "OzoneJsonResponseDataValidationCommon :: compare_ott_launch_ids_with_ott_true_response_new"
    if $params.include? "&ott="
      ott_launch_ids_with_all_combinations_of_services = {"amazon"=>[],"hbogo"=>[],"hulu"=>[],"netflix"=>[],"showtimeanytime"=>[],"showtime"=>[],"hbonow"=>[],"vudu"=>[],"youtube"=>[]}
      populate_hash_of_services_new(ott_launch_ids_with_all_combinations_of_services,json_body,ott_search_index,first_index)
      $log.info "Ott launch ids of Combination of services: #{ott_launch_ids_with_all_combinations_of_services}<br>"
      $log.info "Ott launch ids which was captured earlier with only ott param:#{$all_ott_services_launch_ids}"
      if ott_launch_ids_with_all_combinations_of_services == $all_ott_services_launch_ids
        $log.info "Ott launch id test passed for combination of services<br>"
      else
        raise "Combination of services not matching with ott=true launch id,raising error!"
      end
    else
      $log.info "compare_ott_launch_ids_with_ott_true_response:: No ott param, skipping<br>"
    end 
    $log.info "compare_ott_launch_ids_with_ott_true_response_new >>"
  end 

  def check_if_watchlist_response_has_only_single_ott_service_data(json_body,service_name)
    if $params.include? "&ott=true"
      expect_json("feed.*.videos.*.source_id", service_name)
      expect_json("feed.*.videos.*.link.uri", regex("#{service_name}"))
    else
      $log.info "check_if_watchlist_response_has_only_single_ott_service_data:: No ott param, skipping<br>"
    end 
  end

  def subtract_arrays_to_get_difference(arr1,arr2)
    result = arr1 - arr2
    result
  end

  def response_validation_for_device_search(object_index,api,device_name,device_id,device_brand)
    $log.info "response_validation_for_device_search::Going to validate response for device search"
    # if api.include? "launch"
    #   $log.info "Launch app on device flow, Dont do anything"
    # else
    #   if api.include? "switch"
    #     expect_json("#{object_index}.auto", true)
    #   else
    #     expect_json("#{object_index}.auto", false)
    #   end
    # end
    expect_json("#{object_index}.results.?.object_type", "device")
    expect_json("#{object_index}.results.?.object.name", device_name)
    expect_json("#{object_index}.results.?.object.id", device_id)
    expect_json("#{object_index}.results.?.object.brand", device_brand)
    $log.info "response_validation_for_device_search >>"
  end

  def response_validation_for_app_search(object_index,api,runtime_response,app_name)
    switch_object = runtime_response[object_index]
    switch_results = switch_object[:results]
    search_switch_object_arr_length = switch_results.length

    for i in 0..search_switch_object_arr_length-1
      if switch_results[i][:object_type] == "service"
        $log.info "Service object appears at #{i}th index<br>"
        service_object_index = i
        break
      end
    end
    # if api.include? "launch"
    #   expect_json("#{object_index}.auto",true)
    # else
    #   expect_json("#{object_index}.auto",false)
    # end
    expect_json("#{object_index}.results.#{service_object_index}.object.name",app_name)
  end

  def response_validation_switches_devices(type,devs=nil)
    $log.info "api specs::response_validation_switches_devices"
    devices = $conf["box_devices"]
    devices_by_name = devices.keys
    if type == "single"
      $log.info "if :: seeing single device was added"
      if $dev_port
        $log.info "dev port-#{$dev_port}"
        dev = devs
        dev_id = devices[dev]
        expect_json("?",{:device_name=>dev,:id=>dev_id,:port=>$dev_port1})
      end
    elsif type == "many"
      $log.info "elsif :: many cond- see if devices were posted succesfully"
      devs.each do |dev|
        dev_id = devices[dev]
        if dev == "Roku"
          $log.info "Device: #{dev}"
          expect_json("?",{:device_name=>dev,:id=>dev_id,:port=>$dev_port1})
        else
          $log.info "Device: #{dev}"
          expect_json("?",{:device_name=>dev,:id=>dev_id,:port=>$dev_port2})
        end
      end
    elsif type == "all"
      $log.info "elsif :: see if all devices were posted succesfully"
      ports = [0,1,2,3,4,5,6,8]
      i = 0
      devices_by_name.each do|dev|
        port = ports[i]
        dev_id = devices[dev]
        $log.info "Going to check if device #{dev} with id:#{dev_id} available on port #{port}"
        expect_json("?",{:device_name=>dev,:id=>dev_id,:port=>port})
        i += 1
      end
    elsif type == "none"
      $log.info "elsif ::no devices expected for box."
      expect_json("*",{:name=>"Not Connected",:id=>"not_conn",:device_name=>"",:scan_method=>""})
    else
      $log.info "else::see if specific device-#{type} values are found"
      #if $dev_port
        $log.info "dev port-#{$dev_port}"
        dev = type
        dev_id = devices[dev]
        expect_json("?",{:device_name=>dev,:id=>dev_id,:port=>2})
      #end
    end
    
  end

  def response_validation_switches_apps(type,devs=nil,resp=nil)
    $log.info "api specs::response_validation_switches_apps"
    devices = $conf["box_devices"]
    devices_by_name = devices.keys
    if type == "single"
      $log.info "if :: seeing random device was added"
      dev = devs
      dev_id = devices[dev]
      expect_json("*.devices.*.device",{:name=>dev,:id=>dev_id})
    elsif type == "many"
      $log.info "elsif :: see if the devices were posted succesfully"
      len = resp.length
      for i in 0..len-1
        app_name = resp[i][:name]
        $log.info "FOR loop: #{i}th object, app - #{app_name}"
        devices_having_app = resp[i][:devices]
        no_of_devices = devices_having_app.length
        if app_name == "iTunes Movies" or app_name == "iTunes Shows"
          raise "More than one device seen having iTunes apps, only Apple TV expected for these apps" if no_of_devices != 1
          dev_name_expected = devices_having_app[0][:device][:name] 
          raise "Device not Apple TV for iTunes apps" if dev_name_expected != "Apple TV"
          $log.info "Verified Apple TV is the only device for iTunes apps."
        else
          devices_having_app.each do |dev|
            dev_name = dev[:device][:name]
            $log.info "Device got from response - #{dev_name}"
            if devs.include? dev_name
              $log.info "#{dev_name} part of the expected devices: #{devs} for the app #{app_name}"
            else
              raise "#{dev_name} does not have #{app_name} app.  The expected devices for this app are: #{devs}"
            end 
          end
        end
      end
    elsif type == "all"
      $log.info "elsif :: see if all devices were posted succesfully"
      apps = $conf["apps"]
      $log.info "Apps with all details: #{apps}"
      len = resp.length
      for i in 0..len-1
        app_name = resp[i][:name]
        $log.info "FOR loop: #{i}th object, app - #{app_name}"
        expected_devices = apps[app_name]
        $log.info "Expected devices for app-#{app_name} is :#{expected_devices}"
        sym_exp_devices = transform_keys_to_symbols(expected_devices)
        $log.info "Expected devices for app symbolised-#{app_name} is :#{sym_exp_devices}"
        sym_exp_devices.each do |exp_dev|
          expect_json("#{i}.devices.?",exp_dev)
        end
      end
    else
      $log.info "else::see if specific device-#{type} values are found in all apps"
      #if $dev_port
        $log.info "dev port-#{$dev_port}"
        dev = type
        dev_id = devices[dev]
        expect_json("*.devices.*.device",{:name=>dev,:id=>dev_id})
      #end
    end
  end

end