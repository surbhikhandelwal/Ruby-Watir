module OzoneAutomationCommon
  
  def transform_keys_to_symbols(value)
    if value.is_a?(Array)
      value.collect {|i| transform_keys_to_symbols i}
	  elsif value.is_a?(Hash)
	    value.inject({}) {|memo,(k,v)| memo[k.to_sym] = transform_keys_to_symbols(v); memo}
	  else
	  value
	  end
  end

  def schema_formatting(str) 
    str.split(',').inject({}) do |memo, i|
      token = i.gsub(/^\s*/, '').gsub(/\s*$/, '')
      tokens = token.split(':')
      memo[tokens.first.to_sym] = tokens.last.to_sym
      memo
    end
  end

  def get_cloud_url(str_env)
    if str_env.downcase == 'prod'
      #puts "Prod env, hence prod_ozone_url<br>"
      env_url = "https://api.caavo.com"
    elsif str_env.downcase == 'preprod'
      #puts "Preprod env, hence fetching preprod_ozone_url<br>"
      env_url = "preprod.caavo.com"
    elsif str_env.downcase == 'dev'
      #puts "Dev env, hence fetching dev_ozone_url<br>"
      env_url = "http://192.168.86.7:8080"
    elsif str_env.downcase == 'test'
      env_url = "http://ec2-52-54-229-99.compute-1.amazonaws.com:8080"  
    end
    env_url
  end

  def format_schema_hash(schema_hash)
    schema_hash_keys = schema_hash.keys
    schema_hash_keys.each do |key|
      val = schema_hash[key]
      formatted_val = schema_formatting(val)
      schema_hash[key] = formatted_val
    end
    schema_hash
  end

    def symbolize_array_elements(arr)
    sym_arr = Array.new
    arr.each do |el|
      sym_arr.push(el.to_sym)
    end
    sym_arr
  end

  # *Method Definition* Filters the complete response to a subset of a hashes which contain only the mandatory fields.
  # *Arg1* Complete response(Array of hashes) of the API
  # *Arg2* Array of symbolised mandatory fields
  def filter_array_of_hashes_based_on_mandatory_fields(complete_arr_response,arr_of_mand_fields)
    $log.info "OzoneAutomationCommon :: filter_array_of_hashes_based_on_mandatory_fields"
    array_of_filtered_hashes = Array.new
    complete_arr_response.collect { |single_hash|
    filtered_hash = Hash.new
      arr_of_mand_fields.each do |el|
        if el == :images
          complete_arr_images_response = Array.new
          complete_arr_images_response = single_hash[el]
          img_arr_mand_fields = [:width,:height,:url]
          filtered_hash[el] = filter_array_of_hashes_based_on_mandatory_fields(complete_arr_images_response,img_arr_mand_fields)
        else
        filtered_hash[el]=single_hash[el]
        end
      end
    $log.info "Filtered hash is ************************ #{filtered_hash}<br>"
    array_of_filtered_hashes.push(filtered_hash) }
    array_of_filtered_hashes
  end

  def prepare_response_data_to_match_airborne_format(exp_json_data)
    $log.info "OzoneAutomationCommon :: prepare_response_data_to_match_airborne_format"
    parsed_hash = JSON.parse(exp_json_data)
    final_val = transform_keys_to_symbols(parsed_hash)
    fin = final_val.to_s
    #$log.info "Expected Response is #{fin}"
    $log.info "prepare_response_data_to_match_airborne_format >>"
    final_val
  end

  def exception_handling(ex,dataset,api_url)
    $log.info "Caught Expectation Error in #{dataset}<br>"
    $log.info "Error!!!: #{ex} <br>"
    $log.info "Backtrace: #{ex.backtrace}<br>"
    if !$resp_code_validation_status
      $failure_string = "Failure validating Response Code" 
    elsif !$schema_validation_status
      $failure_string = "Failure validating Schema"
    elsif !$values_matching_validation_status
      $failure_string = "Failure validating exact values"
    end
    $Exceptions_Array.push(Array.new)
    $Exceptions_Array[$exception_count].push(dataset)
    $Exceptions_Array[$exception_count].push(api_url)
    $Exceptions_Array[$exception_count].push($failure_string)
    $Exceptions_Array[$exception_count].push(exact)
    $exception_count = $exception_count + 1
  end

  def exception_handling_watchlist(ex,service,serv_provider,api_url)
    $log.info "Caught Expectation Error in #{service}<br>"
    $log.info "Error!!!: #{ex} <br>"
    $log.info "Backtrace: #{ex.backtrace}<br>"
    if !$resp_code_validation_status
      $failure_string = "Failure validating Response Code" 
    elsif !$schema_validation_status
      $failure_string = "Failure validating Schema"
    elsif !$values_matching_validation_status
      $failure_string = "Failure validating exact values"
    end
    $Exceptions_Array.push(Array.new)
    $Exceptions_Array[$exception_count].push(api_url)
    $Exceptions_Array[$exception_count].push("service: #{service}")
    $Exceptions_Array[$exception_count].push("serv_provider: #{serv_provider}")
    $Exceptions_Array[$exception_count].push($failure_string)
    $Exceptions_Array[$exception_count].push(ex)
    $exception_count = $exception_count + 1
  end

  def pass_or_fail_test_based_on_exceptions_caught(api_desc)
    $log.info "Done with all datasets, now going to pass or fail test based on exceptions caught.<br>"
    if $exception_count > 0
      $log.info "Exception count greater than 0, hence raise exception"
      raise "#{$exception_count} failures caught out of a total of #{$total_count} iterations.Exceptions are: #{$Exceptions_Array} <br><br>"
    else
      $log.info "Validation of all datasets passed for '#{api_desc}' api<br><br>"
    end
  end

  def get_index_of_ott_search_object(json_body,log)
    index_of_ott_search_obj = nil
    no_of_arr_in_complete_resp = json_body.length
    for i in 0..no_of_arr_in_complete_resp-1
      log.info "action type: #{json_body[i][:action_type]}"
      if json_body[i][:action_type] == "ott_search"
        index_of_ott_search_obj = i
        #puts "Index of ott search object is: #{i}"
        log.info "Index of ott search object is: #{i}"
        break
      end
    end
    index_of_ott_search_obj
  end

  def prepare_for_search_comparison(word)
    word=word.gsub(/^(the|a|an) /, '')
    word=word.gsub(/[!,'";:?@#]/, '')
    word=word.gsub(/[\-]/, '')
    word=word.gsub(/\s+/, "")
    word=word.gsub(/[&]/, 'and')
    word
  end

end