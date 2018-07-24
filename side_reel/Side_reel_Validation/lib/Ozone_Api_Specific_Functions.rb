module OzoneApiSpecificFunctions

  temp = ""
  array_of_failed_login_services = nil

  def get_first_prog_from_complete_relevant_search_response(complete_search_response)
    $log.info "OzoneApiSpecificFunctions :: get_first_prog_from_complete_relevant_search_response"
    relevant_program_search_data = complete_search_response[0]
    results_array_of_program_search_data = relevant_program_search_data[:results]
    first_program_in_results_array = results_array_of_program_search_data[0]
    first_program_object = first_program_in_results_array[:object]
    array_with_filtered_program= Array.new
    array_with_filtered_program.push(first_program_object)
    $log.info "get_first_prog_from_complete_relevant_search_response >>"
    array_with_filtered_program
  end

  def create_array_of_parsed_dvr_json_objects()
    array_of_parsed_json_objects = Array.new();
    for i in 1..10
      array_of_parsed_json_objects.push(JSON.parse(IO.read("spec/all_dvr_related_spec/directv_dvr_objects/#{i}")))
    end
    array_of_parsed_json_objects
  end

  def create_dvr_post_request_body(array_of_parsed_json_obj,dev_id)
    req_body = {'dvr_recording_object'=>JSON.dump(array_of_parsed_json_obj),'device_id'=>dev_id}
    req_body
  end

  def check_for_ott_param_and_append_service_name_watchlists(service_name)
    final_params = ""
    if $params.include? "ott=true"
      final_params = $params + "&service=" + service_name
    end
    final_params
  end

  def post_websetup_state(description,post_state)
    it "#{description}" do
      if post_state == 0
        post "/web_setup/state",{"state" => "#{post_state}"}
        response_code_validation("get")
      else
        #$log.info "Original headers: #{Airborne.configuration.headers} <br>"
        temp = Airborne.configuration.headers["Authorization"]
        Airborne.configuration.headers["Authorization"] = "Token token=#{$websetup_pin}"
        post "/web_setup/state",{"state" => "#{post_state}"}
        response_code_validation("get")
        #$log.info "Temp val: #{temp}"
        Airborne.configuration.headers["Authorization"] = temp
        $log.info "Val of header after restoring header to old val is: #{Airborne.configuration.headers} <br>"
      end
    end
  end

  def post_websetup_state_new(description,post_state)
    it "#{description}" do
      if post_state == 0
        post "/web_setup/state",{"state" => "#{post_state}"}
        response_code_validation("get")
      else
        #$log.info "Original headers: #{Airborne.configuration.headers} <br>"
        temp = Airborne.configuration.headers["Authorization"]
        Airborne.configuration.headers.delete("Authorization")
        Airborne.configuration.headers["Cookie"] = "#{$platform_session}"
        post "/web_setup/state",{"state" => "#{post_state}"}
        response_code_validation("get")
        #$log.info "Temp val: #{temp}"
        Airborne.configuration.headers["Authorization"] = temp
        Airborne.configuration.headers.delete("Cookie")
        $log.info "Val of header after restoring header to old val is: #{Airborne.configuration.headers} <br>"
      end
    end
  end


  def get_websetup_state(expected_state)
    it 'get state of web setup' do
      $log.info "Original headers: #{Airborne.configuration.headers} <br>"
      temp = Airborne.configuration.headers["Authorization"]
      Airborne.configuration.headers["Authorization"] = "Token token=#{$websetup_pin}"

      for i in 0..1
        temp_headers = Airborne.configuration.headers
        # $log.info "global_etag: #{global_etag}"
        # etag_val = "#{global_etag}"
        # $log.info "etag_val: #{etag_val}"
        Airborne.configuration.headers["If-None-Match"] = "#{$etag}"
        #$log.info "Val of header is: #{Airborne.configuration.headers} <br>"
        api = '/web_setup/state'
        get api
        if $etag.empty?
          response_code_validation("get",api)
          expect_json('state',"#{expected_state}")
          #$log.info "Json response: #{json_body}"
          #$log.info "#{headers} <br>"
          $etag = headers["etag"]
          $log.info "$etag obtained is: #{$etag} <br>"
        else
          response_code_validation("notmod",api)
          $etag = ""
        end
        Airborne.configuration.headers.delete("If-None-Match")
        $log.info "Val of header after deleting 'if-none-match' is: #{Airborne.configuration.headers} <br>"
      end
      $log.info "Temp val: #{temp}"
      Airborne.configuration.headers["Authorization"] = temp
      #$log.info "Val of header after restoring header to old val is: #{Airborne.configuration.headers} <br>"
    end
  end

  def get_websetup_state_new(expected_state)
    it 'get state of web setup' do
      #$log.info "Original headers: #{Airborne.configuration.headers} <br>"

      temp = Airborne.configuration.headers["Authorization"]
      Airborne.configuration.headers.delete("Authorization")
      Airborne.configuration.headers["Cookie"] = "#{$platform_session}"
      for i in 0..1
        temp_headers = Airborne.configuration.headers
        # $log.info "global_etag: #{global_etag}"
        # etag_val = "#{global_etag}"
        # $log.info "etag_val: #{etag_val}"
        Airborne.configuration.headers["If-None-Match"] = "#{$etag}"
        puts "Val of header is: #{Airborne.configuration.headers} <br>"
        api = '/web_setup/state'
        get api
        if $etag.empty?
          response_code_validation("get",api)
          puts "Json response: #{json_body}"
          puts "#{headers} <br>"
          expect_json('state',"#{expected_state}")
          $etag = headers["etag"]
          puts "$etag obtained is: #{$etag} <br>"
        else
          response_code_validation("notmod",api)
          $etag = ""
        end
        Airborne.configuration.headers.delete("If-None-Match")
        puts "Val of header after deleting 'if-none-match' is: #{Airborne.configuration.headers} <br>"
      end
      #$log.info "Temp val: #{temp}"
      Airborne.configuration.headers["Authorization"] = temp
      Airborne.configuration.headers.delete("Cookie")
      puts "Val of header after restoring header to old val is: #{Airborne.configuration.headers} <br>"
    end
  end

  def get_tinyurl_from_cloud()
    it 'get tinyurl link from cloud(box call)' do
      api = '/switches/pin?shorten_url=true&'
      get api
      response_code_validation("get",api)
      puts "#{json_body} <br>"
      $tiny_url = json_body[:url]
      $websetup_pin = json_body[:pin]
      puts "Tinyurl obtained from cloud is: #{$tiny_url} <br>"
      #$log.info "#{headers} <br>"
    end
  end

  def launch_tinyurl(workflow)
    it 'launching websetup url' do
      if workflow == "negative"
        sleep(180)
        expected_response_code = 404
      else
        expected_response_code = 200
      end
      temp_base_url = Airborne.configuration.base_url
      temp_headers = Airborne.configuration.headers
      #$log.info "Airborne Base url is: #{Airborne.configuration.base_url} is stored temporarily. <br>"
      Airborne.configuration.base_url = nil
      Airborne.configuration.headers = nil
      #$log.info "Airborne Base url overwritten <br>"
      get $tiny_url
      response_code_validation("get", $tiny_url)
      # if workflow == "negative"
      #   expect_status("404")
      # else
      #   response_code_validation("get")
      # end
      Airborne.configuration.base_url = temp_base_url
      Airborne.configuration.headers = temp_headers
      #$log.info "Airborne Base url is restored <br>"
    end
  end

    def launch_setup(workflow)
    it 'launching websetup url' do
      if workflow == "negative"
        sleep(180)
        expected_response_code = 404
      else
        expected_response_code = 200
      end
      temp_base_url = Airborne.configuration.base_url
      temp_headers = Airborne.configuration.headers
      #$log.info "Airborne Base url is: #{Airborne.configuration.base_url} is stored temporarily. <br>"
      Airborne.configuration.base_url = nil
      Airborne.configuration.headers = nil
      #$log.info "Airborne Base url overwritten <br>"
      get $tiny_url
      response_code_validation("get", $tiny_url)
      #expect_status(expected_response_code)
      #puts "#{body}"
      #puts "#{headers}"
      #puts "#{headers["set_cookie"][0]}"
      $platform_session = headers["set_cookie"][0]
      puts "Cookie-Platform Session is: #{$platform_session}"
      #puts "#{json_body}"
      Airborne.configuration.base_url = temp_base_url
      Airborne.configuration.headers = temp_headers
      #$log.info "Airborne Base url is restored <br>"
    end
  end

  def post_pin_during_setup()
    it 'posts pin during websetup' do   
      #temp = Airborne.configuration.headers["Authorization"]
      Airborne.configuration.headers["Cookie"] = "#{$platform_session}"
      req_body = {"pin[pin]" => "#{$websetup_pin}"}
      puts "req body is: #{req_body}"
      post '/setup',req_body
      response_code_validation("get")
      puts "#{response}"
      puts "#{headers}"
      #puts "#{json_body}"
      Airborne.configuration.headers.delete("Cookie")
    end
  end

  def delete_all_extern_accs()
    it "should validate response of '/extern_account/delete_all' api" do
      delete '/extern_account/delete_all',{}

      # 1.Response Code Validation
      response_code_validation("get")
      #$log.info "Completed response code validation<br>"
    end
  end

  def post_services_switch_profile(services)
    it "should post services to switch which were selected during web setup" do
      req_body = ""
      #$log.info "Original headers: #{Airborne.configuration.headers} <br>"
      temp = Airborne.configuration.headers["Authorization"]
      Airborne.configuration.headers["Authorization"] = "Token token=#{$websetup_pin}"
      #Airborne.configuration.headers["Authorization"] = "Token token=da94"
      #$log.info "Val of header after modifying authorization key with the websetup pin' is: #{Airborne.configuration.headers}"
      if services == "all"
        $log.info "inside services=all"
        req_body = {"services" => ['amazon','hbogo','hulu','showtimeanytime','showtime','hbonow','vudu','youtube','netflixusa']}
      else
        req_body = {"services" => [services]}
      end
      post '/switches/profiles', req_body
      response_code_validation("get")
      #Airborne.configuration.headers.delete("Authorization")
      #$log.info "Temp val: #{temp}"
      Airborne.configuration.headers["Authorization"] = temp
      #$log.info "Val of header after restoring header to old val is: #{Airborne.configuration.headers} <br>"
    end
  end

  def post_services_switch_profile_new(services)
    it "should post services to switch which were selected during web setup" do
      req_body = ""
      #$log.info "Original headers: #{Airborne.configuration.headers} <br>"
      # temp = Airborne.configuration.headers["Authorization"]
      # Airborne.configuration.headers.delete("Authorization")
      # #Airborne.configuration.headers["Authorization"] = "Token token=#{$websetup_pin}"
      # Airborne.configuration.headers["Cookie"] = "#{$platform_session}"

      #Airborne.configuration.headers["Authorization"] = "Token token=da94"
      #$log.info "Val of header after modifying authorization key with the websetup pin' is: #{Airborne.configuration.headers}"
      if services == "all"
        $log.info "inside services=all"
        req_body = {"services" => ['amazon','hbogo','hulu','showtimeanytime','showtime','hbonow','vudu','youtube','netflixusa']}
      else
        req_body = {"services" => [services]}
      end
      post '/switches/profiles', req_body
      response_code_validation("get")
     # Airborne.configuration.headers.delete("Cookie")
      #$log.info "Temp val: #{temp}"
     # Airborne.configuration.headers["Authorization"] = temp
      #$log.info "Val of header after restoring header to old val is: #{Airborne.configuration.headers} <br>"
    end
  end

  def get_services_switch_profile(services)
    it "should get services selected during web setup" do
      api = '/switches/profiles'
      get api
      response_code_validation("get",api)
      #$log.info "#{json_body} <br>"
      if services == "all"
        expect_json("services",['amazon','hbogo','hulu','showtimeanytime','showtime','hbonow','vudu','youtube','netflixusa'])
      else
        req_body = {"services" => [services]}
      end
      #services_ = json_body[:services]
    end
  end

  def get_services_switch_profile_new(services)
    it "should get services selected during web setup" do
      get '/switches/profiles'
      response_code_validation("get")
      #$log.info "#{json_body} <br>"
      if services == "all"
        expect_json("services",['amazon','hbogo','hulu','showtimeanytime','showtime','hbonow','vudu','youtube','netflixusa'])
      else
        req_body = {"services" => [services]}
      end
      #services_ = json_body[:services]
    end
  end

  def post_externaccs_old(type)
    it "should post externaccs" do
        #Load the yml file which contains the test data
      test_data = YAML.load_file('spec/all_externacc_creation_spec/post_externaccs_testdata_old.yml')

      #Get the testdata
      completedata = test_data['testdata']

      reset_test_variables()
      datasets = completedata.keys

      if type == "websetup"
        #puts "Original headers: #{Airborne.configuration.headers} <br>"
        temp = Airborne.configuration.headers["Authorization"]
        Airborne.configuration.headers["Authorization"] = "Token token=#{$websetup_pin}"
        #puts "Val of header after modifying authorization key with the websetup pin' is: #{Airborne.configuration.headers}"
      elsif type == "websetup_new"
        temp = Airborne.configuration.headers["Authorization"]
        Airborne.configuration.headers.delete("Authorization")
        Airborne.configuration.headers["Cookie"] = "#{$platform_session}"
      end
      datasets.each do |individual_dataset|
 
        begin

          dataset = completedata[individual_dataset]
          service_name = dataset['service_name']

          #Form the complete api url
          api = dataset['api']
          api_url = $base_url + api

          #Get the request body
          req_body = dataset['request_body']
          req_body_class = req_body.class
          #puts "Request body class : #{req_body_class}<br>"
          #puts "Request body is : #{req_body}<br>"

          $total_count = $total_count + 1
          puts "Total count: #{$total_count}<br>"

          puts "The complete url to be tested is - #{api_url}<br>"
          post api, req_body

          # 1.Response Code Validation
          response_code_validation("post")
          puts "Completed response code validation<br>"
          $resp_code_validation_status = true
 
        rescue Exception => exp_err
            exception_handling(exp_err,dataset,api_url)
        ensure
            reset_iteration_variables()
        end
        pass_or_fail_test_based_on_exceptions_caught(api_url)
      end
      if type == "websetup"
        #puts "Temp val: #{temp}"
        Airborne.configuration.headers["Authorization"] = temp
        #puts "Val of header after restoring header to old val is: #{Airborne.configuration.headers} <br>"
      elsif type == "websetup_new"
        Airborne.configuration.headers.delete("Cookie")
        Airborne.configuration.headers["Authorization"] = temp
      end
    end
  end

  def post_externaccs(type)
    it "should post externaccs" do
        #Load the yml file which contains the test data
      test_data = YAML.load_file('spec/all_externacc_creation_spec/post_externaccs_testdata.yml')

      #Get the testdata
      completedata = test_data['testdata']

      reset_test_variables()
      datasets = completedata.keys

      if type == "websetup"
        #$log.info "Original headers: #{Airborne.configuration.headers} <br>"
        temp = Airborne.configuration.headers["Authorization"]
        Airborne.configuration.headers["Authorization"] = "Token token=#{$websetup_pin}"
        #$log.info "Val of header after modifying authorization key with the websetup pin' is: #{Airborne.configuration.headers}"
      elsif type == "websetup_new"
        temp = Airborne.configuration.headers["Authorization"]
        Airborne.configuration.headers.delete("Authorization")
        Airborne.configuration.headers["Cookie"] = "#{$platform_session}"
      end
      datasets.each do |individual_dataset|
 
        begin

          dataset = completedata[individual_dataset]
          service_name = dataset['service_name']

          #Form the complete api url
          api = dataset['api']
          api_url = $base_url + api

          #Get the request body
          req_body = dataset['request_body']
          req_body_class = req_body.class
          service_providers = req_body.keys

          if  service_providers.length == 1
          #$log.info "Request body class : #{req_body_class}<br>"
          #$log.info "Request body is : #{req_body}<br>"

            $total_count = $total_count + 1
            $log.info "Total count: #{$total_count}<br>"

            $log.info "The complete url to be tested is - #{api_url}<br>"
            post api, req_body

            # 1.Response Code Validation
            response_code_validation("post")
            $log.info "Completed response code validation<br>"
            $resp_code_validation_status = true

          elsif service_providers.length == 3
            service_providers.each do |serv_provider|
              $log.info "Service provider is: #{serv_provider}"
              req_body_individual = req_body[serv_provider]
              set_auth_token_in_req_header(serv_provider)

              $total_count = $total_count + 1
              $log.info "Total count: #{$total_count}<br>"

              $log.info "The complete url to be tested is - #{api_url}<br>"
              post api, req_body_individual

              # 1.Response Code Validation
              response_code_validation("post")
              $log.info "Completed response code validation<br>"
              $resp_code_validation_status = true
            end
            set_auth_token_in_req_header("directv")
          end
 
        rescue Exception => exp_err
            exception_handling(exp_err,dataset,api_url)
        ensure
            reset_iteration_variables()
        end
        pass_or_fail_test_based_on_exceptions_caught(api_url)
      end
      if type == "websetup"
        #$log.info "Temp val: #{temp}"
        Airborne.configuration.headers["Authorization"] = temp
        #$log.info "Val of header after restoring header to old val is: #{Airborne.configuration.headers} <br>"
      elsif type == "websetup_new"
        Airborne.configuration.headers.delete("Cookie")
        Airborne.configuration.headers["Authorization"] = temp
      end
    end
  end

  def retry_post_extern_acc_old(array_of_failed_login_attempts)
   # it 'retry posting extern account which failed previously' do
      #Load the yml file which contains the test data
      puts "Inside retry post, loading yaml file"
      test_data = YAML.load_file('spec/all_externacc_creation_spec/post_externaccs_testdata.yml')

      puts "Array of failed services login: #{array_of_failed_login_attempts}   "
      #Get the testdata
      completedata = test_data['testdata']

      reset_test_variables()
      datasets = completedata.keys
 
      datasets.each do |individual_dataset|
        puts "Inside each do loop"
        dataset = completedata[individual_dataset]
        service_name = dataset['service_name']
        puts "Current service to be posted is: #{service_name}"                                        

        if !array_of_failed_login_attempts.include? service_name
          puts "#{service_name} has been successfully logged into, hence going to next service without posting account once again"
          next
        else
          puts "#{service_name} had login failed status, hence going to post credentials once again"
        end

        #begin

 
        #Form the complete api url
        api = dataset['api']
        api_url = $base_url + api

        #Get the request body
        req_body = dataset['request_body']
        req_body_class = req_body.class
        #puts "Request body class : #{req_body_class}<br>"
        #puts "Request body is : #{req_body}<br>"

        $total_count = $total_count + 1
        puts "Total count: #{$total_count}<br>"

        puts "The complete url to be tested is - #{api_url}<br>"
        post api, req_body

        # 1.Response Code Validation
        response_code_validation("post")
        puts "Completed response code validation<br>"
        $resp_code_validation_status = true
 
        # rescue Exception => exp_err
        #     exception_handling(exp_err,dataset,api_url)
        # ensure
        #     reset_iteration_variables()
        # end
        # pass_or_fail_test_based_on_exceptions_caught(api_url)
      end
    #end
  end

  def retry_post_extern_acc(array_of_failed_login_attempts)
   # it 'retry posting extern account which failed previously' do
      #Load the yml file which contains the test data
      $log.info "Inside retry post, loading yaml file"
      test_data = YAML.load_file('spec/all_externacc_creation_spec/post_externaccs_testdata.yml')

      $log.info "Array of failed services login: #{array_of_failed_login_attempts}"

      #Get the testdata
      completedata = test_data['testdata']

      reset_test_variables()
      datasets = completedata.keys
 
      datasets.each do |individual_dataset|
        $log.info "Inside each do loop"
        dataset = completedata[individual_dataset]
        service_name = dataset['service_name']
        $log.info "Current service to be posted is: #{service_name}"                                        

        array_of_failed_login_attempts.each do |ind_hash|
          serv_prov = ind_hash.keys[0]
          arr_of_failed_logins = ind_hash[serv_prov]
          if !arr_of_failed_logins.include? service_name
            $log.info "#{service_name} has been successfully logged into, hence going to next service without posting account once again"
            next
          else
            $log.info "#{service_name} had login failed status, hence going to post credentials once again"
          end

          #begin

          $log.info "Service provider is: #{serv_prov}"
          req_body = dataset['request_body']
          req_body_individual = req_body[serv_provider]
          set_auth_token_in_req_header(serv_provider)

          #Form the complete api url
          api = dataset['api']
          api_url = $base_url + api

          $total_count = $total_count + 1
          $log.info "Total count: #{$total_count}<br>"

          $log.info "The complete url to be tested is - #{api_url}<br>"
          post api, req_body_individual

          # 1.Response Code Validation
          response_code_validation("post")
          $log.info "Completed response code validation<br>"
          $resp_code_validation_status = true

        end
        set_auth_token_in_req_header("directv")
        # rescue Exception => exp_err
        #     exception_handling(exp_err,dataset,api_url)
        # ensure
        #     reset_iteration_variables()
        # end
        # pass_or_fail_test_based_on_exceptions_caught(api_url)
      end
    #end
  end

  #   def retry_post_extern_acc(array_of_failed_login_attempts)
  #  # it 'retry posting extern account which failed previously' do
  #     #Load the yml file which contains the test data
  #     $log.info "Inside retry post, loading yaml file"
  #     test_data = YAML.load_file('spec/all_externacc_creation_spec/post_externaccs_testdata.yml')

  #     $log.info "Array of failed services login: #{array_of_failed_login_attempts}"

  #     #Get the testdata
  #     completedata = test_data['testdata']

  #     reset_test_variables()
  #     datasets = completedata.keys
 
  #     datasets.each do |individual_dataset|
  #       $log.info "Inside each do loop"
  #       dataset = completedata[individual_dataset]
  #       service_name = dataset['service_name']
  #       $log.info "Current service to be posted is: #{service_name}"                                        

  #       array_of_failed_login_attempts.each do |ind_hash|
  #         serv_prov = ind_hash.keys[0]
  #         arr_of_failed_logins = ind_hash[serv_prov]
  #         if !arr_of_failed_logins.include? service_name
  #           $log.info "#{service_name} has been successfully logged into, hence going to next service without posting account once again"
  #           next
  #         else
  #           $log.info "#{service_name} had login failed status, hence going to post credentials once again"
  #         end

  #         #begin

  #         $log.info "Service provider is: #{serv_prov}"
  #         req_body = dataset['request_body']
  #         req_body_individual = req_body[serv_provider]
  #         set_auth_token_in_req_header(serv_provider)

  #         #Form the complete api url
  #         api = dataset['api']
  #         api_url = $base_url + api

  #         $total_count = $total_count + 1
  #         $log.info "Total count: #{$total_count}<br>"

  #         $log.info "The complete url to be tested is - #{api_url}<br>"
  #         post api, req_body_individual

  #         # 1.Response Code Validation
  #         response_code_validation("post")
  #         $log.info "Completed response code validation<br>"
  #         $resp_code_validation_status = true

  #       end
  #       set_auth_token_in_req_header("directv")
  #       # rescue Exception => exp_err
  #       #     exception_handling(exp_err,dataset,api_url)
  #       # ensure
  #       #     reset_iteration_variables()
  #       # end
  #       # pass_or_fail_test_based_on_exceptions_caught(api_url)
  #     end
  #   #end
  # end

  def get_externacc_login_status_old()
    retry_attempt = 0
    it "should validate the login status of various services" do
      begin
        timestamp = Time.now.strftime("%d_%m_%Y_%H:%M")
        puts "#{timestamp}: Sleeping for 3 mins for login crawlers to complete<br>"
        sleep(180)
        api = '/extern_account'
        get api
        response_code_validation("get",api)
        puts "JSON response is: #{json_body} <br><br>"
        resp = json_body
        expect_json("*.login_status", "login_success")
      rescue Exception => exp
        puts "Increment of retry attempt"
        retry_attempt = retry_attempt + 1
        array_to_retry_extern_acc_post = populate_array_of_failed_services(resp)
        puts "Services to retry posting: #{array_to_retry_extern_acc_post}"
        retry_post_extern_acc(array_to_retry_extern_acc_post)
        sleep(20)
        if retry_attempt < 3
          puts "Retry attempt is lt 3, retrying again"
          retry
        else
          retry_attempt = 0
          raise "Extern acc login failure for the following services : #{array_to_retry_extern_acc_post}"
        end
      end
    end
  end

  def get_externacc_login_status()
    it "should validate the login status of various services" do
      timestamp = Time.now.strftime("%d_%m_%Y_%H:%M")
      array_to_retry_extern_acc_post = Array.new
      resp = nil
      wait_time = false
      (1..3).each do |i|
        $log.info "i try: #{i}"
        $all_service_providers.each do |serv_prov|
          begin
            if !wait_time
              $log.info "#{timestamp}: Sleeping for 3 mins for login crawlers to complete<br>"
              sleep(180)
              wait_time = true
            end
            set_auth_token_in_req_header(serv_prov)
            get '/extern_account'
            response_code_validation("get",'/extern_account')
            $log.info "JSON response is: #{json_body} <br><br>"
            resp = json_body
            expect_json("*.login_status", "login_success")
          rescue Exception => exp
            $log.info "Increment of retry attempt"
            populated_hash = populate_hash_of_failed_services(serv_prov,resp)
            if !populated_hash.empty?
              array_to_retry_extern_acc_post.push(populated_hash)
            end
          end
          $log.info "array_to_retry_extern_acc_post inside second loop: #{array_to_retry_extern_acc_post}"
          next
        end
        $log.info "array_to_retry_extern_acc_post inside first loop: #{array_to_retry_extern_acc_post}"
        if !array_to_retry_extern_acc_post.empty?
          retry_post_extern_acc(array_to_retry_extern_acc_post)
          $log.info "Services to retry posting: #{array_to_retry_extern_acc_post}"
          sleep(5)
          if i < 3
            $log.info "Retry attempt is lt 3, retrying again"
            wait_time = false
            timestamp = Time.now.strftime("%d_%m_%Y_%H:%M")
            array_to_retry_extern_acc_post = Array.new
            next
          else
            raise "Extern acc login failure for the following services : #{array_to_retry_extern_acc_post}"
          end
        else
          $log.info "Done with test"
          set_auth_token_in_req_header("directv")
          break
        end
      end
    end
  end

  def populate_hash_of_failed_services(serv_provider=nil,response)
    hash_of_failed_login_services = {}
    array_of_failed_login_services = Array.new
    resp_length = response.length
    for i in 0..resp_length-1
      status = response[i][:login_status]
      if status != "login_success"
        if status == "login_failed" or status == "captcha_asked"
          serv_name = response[i][:service]
          $log.info "Login status #{response[i][:login_status]} is seen for: #{serv_name} app with service provider #{serv_provider}"
          array_of_failed_login_services.push(serv_name)
        end
      end
    end
    if !array_of_failed_login_services.empty?
      hash_of_failed_login_services[serv_provider] = array_of_failed_login_services
    end
    hash_of_failed_login_services
  end

  def delete_tinyurl()
    it 'delete tinyurl link' do
     # $log.info "Original headers: #{Airborne.configuration.headers} <br>"
      temp = Airborne.configuration.headers["Authorization"]
      Airborne.configuration.headers["Authorization"] = "Token token=#{$websetup_pin}"
      #$log.info "Val of header after modifying authorization key with the websetup pin' is: #{Airborne.configuration.headers}"
      delete '/switches/pin'
      response_code_validation("get")
     # $log.info "Temp val: #{temp}"
      Airborne.configuration.headers["Authorization"] = temp
      #$log.info "Val of header after restoring header to old val is: #{Airborne.configuration.headers} <br>"
    end
  end

  def search_for_program_and_return_prog_id(program_name,log)
    begin
      search_api = "/voice_command?version=3&query=" + program_name
      get search_api
      #$log.info "Response is: #{json_body}"
      ott_search_index = get_index_of_ott_search_object(json_body)
      ott_search_resp = json_body[ott_search_index][:results]
      resp_len = ott_search_resp.length
      for i in 0..resp_len-1
        prog_obj = ott_search_resp[i][:object]
        if prog_obj[:long_title].casecmp(program_name).zero? and prog_obj[:show_type] == "SM"
          $log.info "Search successful and this series is available in cloud"
          prog_id = prog_obj[:id]
          break
        elsif i == resp_len-1
          $log.info "Program not available in cloud"
          prog_id = nil
        end
      end
      prog_id
    rescue Exception => ex
      #$log.info "Error!!!: #{ex} <br>"
      #log.error "Exception caught in iteration #{iter}!!!: #{ex} <br>"
      $log.info "Backtrace: #{ex.backtrace}<br>"
      log.error "Exception!!!: #{ex} <br"

    rescue Error => err
      #$log.info "Error!!!: #{ex} <br>"
      #log.error "Error in iteration #{iter}!!!: #{err} <br>"
      #$log.info "Backtrace: #{ex.backtrace}<br>"
      log.error "Error!!!: #{err} <br"
    end
  end

  def comprehensive_search_for_series_and_return_prog_id(program_name,service_name,year,seasons_on_portal,log)
    arr_matching_progs = Array.new
    search_term = program_name
    search_term=search_term.gsub(/[&]/, 'and')
    search_term=search_term.gsub(" ", '%20')
    search_term=search_term.gsub("'","%27")
    search_api = "/voice_search?q=" + search_term
    get search_api
    response_code_validation("get",search_api)
    program_name=program_name.downcase
    program_name = prepare_for_search_comparison(program_name)
    log.info "program_name after processing: #{program_name}"
 
    if !json_body.empty?
      log.info "Response is: #{json_body}"
      ott_search_index = get_index_of_ott_search_object(json_body,log)
      ott_search_resp = json_body[ott_search_index][:results]
      progids = Array.new
      resp_len = ott_search_resp.length
      for i in 0..resp_len-1
        log.info "For loop: To find matching programs by title"
        prog_obj = ott_search_resp[i][:object]

        long_title=prog_obj[:long_title].downcase
        long_title = prepare_for_search_comparison(long_title)
        log.info "long_title after processing: #{long_title}"

        original_title=prog_obj[:original_title].downcase
        original_title = prepare_for_search_comparison(original_title)
        log.info "original_title after processing: #{original_title}"
 
        alias_title=prog_obj[:alias_title].downcase
        alias_title = prepare_for_search_comparison(alias_title)
        log.info "alias_title after processing: #{alias_title}"
 
        show_type = prog_obj[:show_type]
        if (long_title.include? program_name or original_title.include? program_name or alias_title.include? program_name) and (show_type == "SM" or show_type == "SE")
          log.info "Search successful and this series is available in cloud"
          if show_type == "SM"
            prog_id = prog_obj[:id]
            rel_year = prog_obj[:release_year]
            seas_cnt = prog_obj[:season_cnt]
          elsif show_type == "SE"
            prog_id = prog_obj[:series_id]
            if progids.include? prog_id
              next
            end
            prog_api = "/programs/#{prog_id}"
            get prog_api
            response_code_validation("get",prog_api)
            rel_year = json_body[0][:release_year]
            seas_cnt = json_body[0][:season_cnt]
          end
          progids.push(prog_id)

          arr_matching_progs.push([prog_id,rel_year,seas_cnt])
          # if !arr_matching_progs.include? [prog_id,rel_year,seas_cnt]
          #   arr_matching_progs.push([prog_id,rel_year,seas_cnt])
          #   #break
          # end

        # elsif i == resp_len-1
        #   $log.info "Program not available in cloud"
        #   prog_id = nil
        end
      end
      log.info "END OF For loop: To find matching programs by title"
      matches_len = arr_matching_progs.length
      if matches_len == 0
        log.info "No matches found, prog id - nil"
        prog_id = nil
      elsif matches_len == 1
        log.info "Exactly 1 match found, program id to be returned is :#{arr_matching_progs[0][0]}"
        prog_id = arr_matching_progs[0][0]
      else
        log.info "More than one matching program by title, go deeper to find match"
        arr_matching_progs_after_rel_year_comp = Array.new
        for i in 0..matches_len-1
          log.info "For loop: To find matching programs by release year"
          # service_name
          # if series_name.include? "netflix"
          #   approx_release_year = year.to_i - seasons_on_portal.to_i + 1
          # elsif series_name =="showtime"
          #   approx_release_year = year.to_i
          # end
          if !service_name.nil? and service_name.include? "netflix"
            approx_release_year = year.to_i - seasons_on_portal.to_i + 1
          elsif !service_name.nil? and service_name =="showtime"
            approx_release_year = year.to_i
          else
            approx_release_year = year.to_i
          end
          approx_release_year_range = Array.new
          approx_release_year_range.push(approx_release_year)
          approx_release_year_range.push(approx_release_year+1)
          approx_release_year_range.push(approx_release_year-1)

          rel_year_of_match = arr_matching_progs[i][1]
          if approx_release_year_range.include? rel_year_of_match
            log.info "Approx release year match, push to array of programs matched by approx release year"
            arr_matching_progs_after_rel_year_comp.push(arr_matching_progs[i])
          end
        end
        log.info "END OF For loop: To find matching programs by release year"
        matches_after_rel_year_comp_len = arr_matching_progs_after_rel_year_comp.length
        if matches_after_rel_year_comp_len == 1
          log.info "1 program got after approx release year match, return prog if as #{arr_matching_progs_after_rel_year_comp[0][0]}"
          prog_id = arr_matching_progs_after_rel_year_comp[0][0]
        else
          if matches_after_rel_year_comp_len == 0
            log.info "No matches found by approx release year, proceed to approx season count check atleast"
            arr_matching_progs_after_seas_cnt_comp = Array.new
            approx_seas_cnt_range = Array.new
            for i in 0..matches_len-1
              #$log.info "For loop: To find matching programs by season count, if release year matches were not found"
              log.info "For loop: To find matching programs by season count, if release year matches were not found"
              sn_cnt = seasons_on_portal.to_i
              approx_seas_cnt_range.push(sn_cnt)
              approx_seas_cnt_range.push(sn_cnt+1)
              approx_seas_cnt_range.push(sn_cnt-1)

              seas_cnt_of_match = arr_matching_progs[i][2]
              if approx_seas_cnt_range.include? seas_cnt_of_match
                #$log.info "Approx season count match, push to array of programs matched by approx season count"
                log.info "Approx season count match, push to array of programs matched by approx season count"
                arr_matching_progs_after_seas_cnt_comp.push(arr_matching_progs[i])
              end
            end
            #$log.info "END OF For loop: To find matching programs by season count, if release year matches were not found"
            log.info "END OF For loop: To find matching programs by season count, if release year matches were not found"
            if arr_matching_progs_after_seas_cnt_comp.length > 0
              #$log.info "Programs matched by approx season count is 1 or more, take the first object as program id"
              log.info "Programs matched by approx season count is 1 or more, take the first object as program id"
              prog_id = arr_matching_progs_after_seas_cnt_comp[0][0]
            else
              #$log.info "Could match by season count too, even after no match was found by approx release year, return prog id as nil"
              log.info "Could'nt match by season count too, even after no match was found by approx release year, return prog id as nil"
              prog_id = nil
            end
          else
            log.info "More than 1 matches found by approx release year check, proceed to approx season count check."
            final_matching_progs = Array.new
            approx_seas_cnt_range = Array.new
            for i in 0..matches_after_rel_year_comp_len-1
              log.info "For loop: To find matching programs by season count, when more than 1 release year matches were found"
              sn_cnt = seasons_on_portal.to_i
              approx_seas_cnt_range.push(sn_cnt)
              approx_seas_cnt_range.push(sn_cnt+1)
              approx_seas_cnt_range.push(sn_cnt-1)

              seas_cnt_of_match = arr_matching_progs_after_rel_year_comp[i][2]
              if approx_seas_cnt_range.include? seas_cnt_of_match
                #$log.info "Match found with approx season count, push to array of final matching progs"
                log.info "Match found with approx season count, push to array of final matching progs"
                final_matching_progs.push(arr_matching_progs_after_rel_year_comp[i])
              end
            end
            #$log.info "END OF For loop: To find matching programs by season count, when more than 1 release year matches were found"
            log.info "END OF For loop: To find matching programs by season count, when more than 1 release year matches were found"
            if final_matching_progs.length > 0
              #$log.info "Final matching progs is 1 or more, take the first object as program id"
              log.info "Final matching progs is 1 or more, take the first object as program id"
              prog_id = final_matching_progs[0][0]
            else
              #$log.info "Take the first program which was matched with approx release year"
              log.info "Take the first program which was matched with approx release year"
              prog_id = arr_matching_progs_after_rel_year_comp[0][0]
            end
          end
        end
      end
    else
      $log.info "json body is empty, therefore return prog id-nil"
      log.info "json body is empty, therefore return prog id-nil"
      prog_id = nil
    end
    prog_id
  end

  def search_for_movie_and_return_prog_id(program_name,release_year,log)
    program_name=program_name.gsub(/[&]/, 'and')
    search_term=program_name
    search_term=search_term.gsub(" ","%20")
    search_term=search_term.gsub("'","%27")
    search_api = "/voice_command?version=3&query=" + search_term
    get search_api
    #$log.info "Response is: #{json_body}"
    log.info "Response is: #{json_body}"
    program_name = program_name.downcase
    program_name = prepare_for_search_comparison(program_name)

    #$log.info "program_name after processing: #{program_name}"
    log.info "program_name after processing: #{program_name}"

    ott_search_index = get_index_of_ott_search_object(json_body)
    ott_search_resp = json_body[ott_search_index][:results]
    resp_len = ott_search_resp.length
    release_year_range = Array.new
    release_year_range.push(release_year)
    release_year_range.push(release_year+1)
    release_year_range.push(release_year-1)
    for i in 0..resp_len-1
      prog_obj = ott_search_resp[i][:object]


      long_title=prog_obj[:long_title].downcase
      long_title = prepare_for_search_comparison(long_title)

     # $log.info "long_title after processing: #{long_title}"
      log.info "long_title after processing: #{long_title}"

      original_title=prog_obj[:original_title].downcase
      original_title = prepare_for_search_comparison(original_title)

     # $log.info "original_title after processing: #{original_title}"
      log.info "original_title after processing: #{original_title}"
 
      alias_title=prog_obj[:alias_title].downcase
      alias_title = prepare_for_search_comparison(alias_title)
      #$log.info "alias_title after processing: #{alias_title}"
      log.info "alias_title after processing: #{alias_title}"


     # if prog_obj[:long_title].casecmp(program_name).zero? and prog_obj[:show_type] == "MO" and release_year_range.include? prog_obj[:release_year]
      #if (program_name == long_title or program_name == original_title or program_name == alias_title) and prog_obj[:show_type] == "MO" and release_year_range.include? prog_obj[:release_year]
      if (long_title.include? program_name or original_title.include? program_name or alias_title.include? program_name) and prog_obj[:show_type] == "MO" and release_year_range.include? prog_obj[:release_year]
        #$log.info "Search successful and this movie is available in cloud"
        log.info "Search successful and this movie is available in cloud"
        prog_id = prog_obj[:id]
        break
      elsif i == resp_len-1
       # $log.info "Movie not available in cloud"
        log.info "Movie not available in cloud"
        prog_id = nil
      end
    end
    prog_id
  end

  def get_program_id_of_episode(prog_id,season_no,episode_no,log)
    begin
      api = "/programs/" + prog_id.to_s + "/episodes?season_number=" + season_no
      get api
      $log.info "Episode response is: #{json_body}"
      episode_obj_count = json_body.length
      for i in 0..episode_obj_count-1
        ep_obj = json_body[i]
        ep_no = episode_no.to_i
        #$log.info "Going to compare #{ep_obj[:episode_season_sequence]} and #{ep_no}"
        if ep_obj[:episode_season_sequence] == ep_no
          episode_program_id = ep_obj[:id]
          break
        else
          episode_program_id = nil
        end
      end
      episode_program_id
    rescue Exception => ex
      #$log.info "Error!!!: #{ex} <br>"
      #log.error "Exception caught in iteration #{iter}!!!: #{ex} <br>"
      #$log.info "Backtrace: #{ex.backtrace}<br>"
      log.error "Exception!!!: #{ex} <br"
      log.error "Backtrace: #{ex.backtrace}<br>"

    rescue Error => err
      #$log.info "Error!!!: #{ex} <br>"
      #log.error "Error in iteration #{iter}!!!: #{err} <br>"
      #$log.info "Backtrace: #{ex.backtrace}<br>"
      log.error "Error!!!: #{err} <br"
    end
  end

  def get_series_season_and_episode_number(prog_id,log)
    api = "/programs/" + prog_id.to_s
    get api
    expect_status('200')
    if !json_body.empty?
      resp = json_body[0]
      $log.info "Program response is: #{resp}"
      log.info "Program response is: #{resp}"
      show_type = resp[:show_type]
      if show_type == "SE"
        series_name = resp[:long_title]
        se_no = resp[:episode_season_number]
        ep_no = resp[:episode_season_sequence]
        ep_title = resp[:episode_title]
        arr = Array.new
        arr.push(series_name)
        arr.push(se_no)
        arr.push(ep_no)
        arr.push(ep_title)
        $log.info "Array of series name,se no & episode no is: #{arr}"
        log.info "Array of series name,se no & episode no is: #{arr}"
      else
        $log.info "Program not of type SE, but of type #{show_type}, hence give out an empty array"
        log.error "Program not of type SE, but of type #{show_type}, hence give out an empty array"
        arr = Array.new
      end
    else
      $log.info "Program not available in cloud!!"
      arr = Array.new
    end

    arr
  end

  def get_ott_links_from_mongo_db(client,prog,log)
    #$log.info "Ozone Api Spec Functions::get_ott_links_from_mongo_db"
    log.info "Ozone Api Spec Functions::get_ott_links_from_mongo_db"
    index_pc_platform = nil
    complete_video_list = nil
    videos_list_got_from_rovi_dump = nil
    dump_date = get_latest_rovi_ott_dump_date(client,log)
    res_cnt = 0
    collection = client[:rovi_ott_links]
    prog_id_query = prog.to_s
    res = collection.find({:rovi_id => prog_id_query,:rovi_dump_date => { '$eq' => dump_date }}, {'availability' => 1}).limit(1).each do |doc|
      res_cnt = res_cnt + 1
    
        doc_json = doc.to_json
        #$log.info doc_json
        parsed_doc = JSON.parse(doc_json)
        program_id = parsed_doc['rovi_id']
 
        #$log.info "Rovi Program id is: #{program_id}<br>"
        log.info "Rovi Program id is: #{program_id}<br>"
        videos = parsed_doc["availability"]["platform_availabilities"]
        
        for i in 0..videos.length
          platform = videos[i]["platform_id"]
          if platform == "pc"
            #$log.info "PC platform videos appear in #{i}th index <br>"
            log.info "PC platform videos appear in #{i}th index "
            index_pc_platform = i
            break
          end
        end

        next if index_pc_platform.nil?
 
        if index_pc_platform && videos[index_pc_platform]["platform_id"] == "pc"
          videos_list_got_from_rovi_dump = Array.new
          complete_video_list = videos[index_pc_platform]['source_availabilities']
          #$log.info "Complete video list is: #{complete_video_list} <br>"
          for i in 0..complete_video_list.length-1
            video_obj = complete_video_list[i]
            content_type = video_obj['content_form']
            service_name = video_obj['source_id']
            #$log.info content_type
            if content_type == 'full' && service_name == $serv_name
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

              if($serv_name == "netflixusa")
                  if !video_obj["link"]["uri"].include? "netflix"
                  next
                end
              end

              if($serv_name == "showtime")
                if video_obj["link"]["uri"].include? "showtimeanytime"
                  next
              end
              
              if !video_obj["link"]["uri"].include? $serv_name
                next
              end

              
            end
              
              #$log.info "Video obj to be pushed is :#{video_obj}"
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
          videos_list_got_from_rovi_dump = transform_keys_to_symbols(videos_list_got_from_rovi_dump)
          #$log.info "Videos extracted from rovi dump: #{videos_list_got_from_rovi_dump} <br><br>"
          log.info "Videos extracted from rovi dump: #{videos_list_got_from_rovi_dump}"
        end
      end
    #end
    if res_cnt == 0
      #$log.info "Program with rovi id #{prog} not available in rovi ott dump"
      log.info "Program with rovi id #{prog} not available in rovi ott dump"
      log.info "**************************************************************************************************************************************************************************************************************************************************************************"
      videos_list_got_from_rovi_dump = Array.new
    end
    videos_list_got_from_rovi_dump
  end

  def get_rovi_ind_service_ott_links_from_mongo_db(client,prog,service_nm,log)
    #$log.info "Ozone Api Spec Functions::get_ott_links_of_ind_services_from_mongo_db"
    log.info "Ozone Api Spec Functions::get_ott_links_of_ind_services_from_mongo_db"
    index_pc_platform = nil
    complete_video_list = nil
    dump_date = nil
    ind_service_videos_list_got_from_rovi_dump = nil

    prog_id = prog.to_s

    coll_dump_date = client[:rovi_ott_links_dump_date]
    query_dump_date = coll_dump_date.find({},{ "sort" =>{ "$natural" => -1}}).limit(1)

    query_dump_date.each do |dt|
      du_dt = dt.to_json
      #$log.info du_dt
      pars_dt = JSON.parse(du_dt)
      date_str = pars_dt['ott_dump_date']
      dump_date = Date.parse date_str
      #$log.info dump_date.class
      #$log.info "Last added dump date is: #{dump_date}<br>"
      log.info "Last added dump date is: #{dump_date}<br>"
    end

    collection = client[:rovi_ott_links]

    cnt = collection.count({:rovi_id => prog_id,:rovi_dump_date => { '$eq' => dump_date }}, {'availability' => 1})

    if cnt == 0
      #$log.info "Program with rovi id #{prog} not available in rovi ott dump"
      log.info "Program with rovi id #{prog} not available in rovi ott dump"
      log.info "**************************************************************************************************************************************************************************************************************************************************************************"
      log.info "**************************************************************************************************************************************************************************************************************************************************************************"
    else

      collection.find({:rovi_id => prog_id,:rovi_dump_date => { '$eq' => dump_date }}, {'availability' => 1}).each do |doc|


        #=> Yields a BSON::Document.
        #$log.info doc
        doc_json = doc.to_json
        #$log.info doc_json
        parsed_doc = JSON.parse(doc_json)
        program_id = parsed_doc['rovi_id']
 
        #$log.info "Rovi Program id is: #{program_id}<br>"
        log.info "Rovi Program id is: #{program_id}<br>"
        videos = parsed_doc["availability"]["platform_availabilities"]
        #$log.info videos
        #$log.info videos.class

        for i in 0..videos.length
          platform = videos[i]["platform_id"]
          if platform == "pc"
            #$log.info "PC platform videos appear in #{i}th index <br>"
            log.info "PC platform videos appear in #{i}th index "
            index_pc_platform = i
            break
          end
        end

        next if index_pc_platform.nil?
 
        if index_pc_platform && videos[index_pc_platform]["platform_id"] == "pc"
          ind_service_videos_list_got_from_rovi_dump = Array.new
          complete_video_list = videos[index_pc_platform]['source_availabilities']
          #$log.info "Complete video list is: #{complete_video_list} <br>"
          for i in 0..complete_video_list.length-1
            video_obj = complete_video_list[i]
            content_type = video_obj['content_form']
            service_name = video_obj['source_id']
            #$log.info content_type
            #$log.info service_name
            if content_type == 'full' and $all_supported_services.include? service_name
              if service_nm == service_name
                #$log.info "Service match found for #{service_nm}"
                log.info "Service match found for #{service_nm}"
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
                if video_obj["link"]["uri"].include? "showtimeanytime"
                  video_obj["source_id"] = "showtimeanytime"
                end
                if video_obj["link"]["uri"].include? "hbonow"
                  video_obj["source_id"] = "hbonow"
                end
                #$log.info "Video obj to be pushed is :#{video_obj}"
                ind_service_videos_list_got_from_rovi_dump.push(video_obj)
              else
                  #$log.info "#{service_name} is not of type #{service_nm}, moving to next"
                  log.info "#{service_name} is not of type #{service_nm}, moving to next"
                  next
              end
            end
          end
          ind_service_videos_list_got_from_rovi_dump = transform_keys_to_symbols(ind_service_videos_list_got_from_rovi_dump)
          #$log.info "Videos extracted from rovi dump: #{videos_list_got_from_rovi_dump} <br><br>"
          log.info "Videos extracted from rovi dump: #{ind_service_videos_list_got_from_rovi_dump}"
        end
      end
    end
    ind_service_videos_list_got_from_rovi_dump
  end

  def get_rovi_ott_links_from_cloud(prog_id,log)
    #$log.info "Ozone Api Spec Functions::get_rovi_ott_links_from_cloud"
    log.info "Ozone Api Spec Functions::get_rovi_ott_links_from_cloud"
    rovi_videos_list_got_from_cloud = Array.new
    get "/programs/#{prog_id}/videos"
    expect_status('200')
    #$log.info json_body
    len = json_body.length
    if len > 0
      #$log.info "Inside if len > O"
      log.info "Inside if len > O"
      for i in 0..len-1
        video_obj_from_cloud = json_body[i]
        if video_obj_from_cloud[:fetched_from].nil?
            video_obj_from_cloud.delete(:platform)
            video_obj_from_cloud.delete(:last_refreshed_timestamp)
            video_obj_from_cloud.delete(:content_expiry_timestamp)
            video_obj_from_cloud.delete(:cache_expiry_timestamp)
            video_obj_from_cloud.delete(:launch_id)
            video_obj_from_cloud.delete(:created_at)
            video_obj_from_cloud.delete(:updated_at)
            video_obj_from_cloud.delete(:refreshed_at)
            video_obj_from_cloud.delete(:with_subscription)
            video_obj_from_cloud.delete(:subscription_type)
            video_obj_from_cloud.delete(:audio_languages)
            if video_obj_from_cloud[:run_time].nil?
              video_obj_from_cloud.delete(:run_time)
            else
              video_obj_from_cloud[:content_runtime_s] = video_obj_from_cloud[:run_time]
              video_obj_from_cloud.delete(:run_time)
            end
            if video_obj_from_cloud[:constraints].empty?
              video_obj_from_cloud.delete(:constraints)
            end
            if video_obj_from_cloud[:quality].nil?
              video_obj_from_cloud.delete(:quality)
            end
            if video_obj_from_cloud[:purchase_type] == ""
              video_obj_from_cloud.delete(:purchase_type)
            end
            if video_obj_from_cloud[:source_id] == "hulu"
              video_obj_from_cloud.delete(:source_program_id)
            end
            rovi_videos_list_got_from_cloud.push(video_obj_from_cloud)
          end
      end
    else
   #   $log.info "Inside else, empty cloud response"
      log.info "Inside else, empty cloud response"
    end
    #$log.info "Rovi Videos got from cloud: #{rovi_videos_list_got_from_cloud}"
    log.info "Rovi Videos got from cloud: #{rovi_videos_list_got_from_cloud}"
    rovi_videos_list_got_from_cloud
  end

  def get_gracenote_ott_links_from_cloud(prog_id,log)
    gn_videos_list_got_from_cloud = nil
    begin
     # $log.info "Ozone Api Spec Functions::get_gracenote_ott_links_from_cloud"
      log.info "Ozone Api Spec Functions::get_gracenote_ott_links_from_cloud"
      gn_videos_list_got_from_cloud = Array.new
      get "/programs/#{prog_id}/videos"
      expect_status('200')
      #$log.info json_body
      len = json_body.length
      if len > 0
     #   $log.info "Inside if len > O"
        log.info "Inside if len > O"
        for i in 0..len-1
          video_obj_from_cloud = json_body[i]
          if video_obj_from_cloud[:fetched_from] == 'gracenote'
              video_obj_from_cloud.delete(:platform)
              video_obj_from_cloud.delete(:last_refreshed_timestamp)
              video_obj_from_cloud.delete(:content_expiry_timestamp)
              video_obj_from_cloud.delete(:cache_expiry_timestamp)
              video_obj_from_cloud.delete(:launch_id)
              video_obj_from_cloud.delete(:created_at)
              video_obj_from_cloud.delete(:updated_at)
              video_obj_from_cloud.delete(:refreshed_at)
              video_obj_from_cloud.delete(:with_subscription)
              video_obj_from_cloud.delete(:subscription_type)
              video_obj_from_cloud.delete(:audio_languages)
              if video_obj_from_cloud[:run_time].nil?
                video_obj_from_cloud.delete(:run_time)
              else
                video_obj_from_cloud[:content_runtime_s] = video_obj_from_cloud[:run_time]
                video_obj_from_cloud.delete(:run_time)
              end
              if video_obj_from_cloud[:constraints].empty?
                video_obj_from_cloud.delete(:constraints)
              end
              if video_obj_from_cloud[:quality].nil?
                video_obj_from_cloud.delete(:quality)
              end
              if video_obj_from_cloud[:purchase_type] == ""
                video_obj_from_cloud.delete(:purchase_type)
              end
              if video_obj_from_cloud[:source_id] == "hulu"
                video_obj_from_cloud.delete(:source_program_id)
              end
              gn_videos_list_got_from_cloud.push(video_obj_from_cloud)
            end
        end
      else
        #$log.info "Inside else, empty cloud response"
        log.info "Inside else, empty cloud response"
      end
      #$log.info "GN Videos got from cloud: #{gn_videos_list_got_from_cloud}"
      log.info "GN Videos got from cloud: #{gn_videos_list_got_from_cloud}"
 
    rescue Exception => ex
      #$log.info "Error!!!: #{ex} <br>"
      #log.error "Exception caught in iteration #{iter}!!!: #{ex} <br>"
      #$log.info "Backtrace: #{ex.backtrace}<br>"
      log.error "Exception!!!: #{ex} <br"
      gn_videos_list_got_from_cloud = []
    rescue Error => err
      #$log.info "Error!!!: #{ex} <br>"
      #log.error "Error in iteration #{iter}!!!: #{err} <br>"
      #$log.info "Backtrace: #{ex.backtrace}<br>"
      log.error "Error!!!: #{err} <br"
      gn_videos_list_got_from_cloud = []
    end
    gn_videos_list_got_from_cloud
  end

  def get_ott_links_from_cloud(prog_id,log)
    log.info "Ozone Api Spec Functions::get_ott_links_from_cloud"
    rovi_videos_list_got_from_cloud = Array.new
    gracenote_videos_list_got_from_cloud = Array.new
    hulu_videos_list_got_from_cloud = Array.new
    vudu_videos_list_got_from_cloud = Array.new
    crawler_videos_list_got_from_cloud = Array.new
    all_videos_list_got_from_cloud = Array.new
    videos_got_from_cloud = {"Rovi Videos"=> [],"Gracenote Videos"=> [],"Hulu Videos"=> [],"Vudu Videos"=> [],"Crawler Videos"=>[],"All Videos" => []}
    #videos_got_from_cloud = nil
    #rovi_videos_list_got_from_cloud = nil
    #gracenote_videos_list_got_from_cloud = nil
    api = "/programs/#{prog_id}/videos"+ "?service="+ $serv_name
    get api
    response_code_validation("get",api)
    log.info "json_body: #{json_body}"
    len = json_body.length
    if len > 0
      #$log.info "Inside if len > O"
      log.info "Inside if len > O"
 
      for i in 0..len-1
        video_obj_from_cloud = json_body[i]
        log.info "video_obj_from_cloud:: #{video_obj_from_cloud}"
        video_obj_from_cloud.delete(:platform)
        video_obj_from_cloud.delete(:last_refreshed_timestamp)
        video_obj_from_cloud.delete(:content_expiry_timestamp)
        video_obj_from_cloud.delete(:cache_expiry_timestamp)
        video_obj_from_cloud.delete(:launch_id)
        video_obj_from_cloud.delete(:created_at)
        video_obj_from_cloud.delete(:updated_at)
        video_obj_from_cloud.delete(:refreshed_at)
        video_obj_from_cloud.delete(:with_subscription)
        video_obj_from_cloud.delete(:subscription_type)
        video_obj_from_cloud.delete(:audio_languages)
        if video_obj_from_cloud[:run_time].nil?
          video_obj_from_cloud.delete(:run_time)
        else
          video_obj_from_cloud[:content_runtime_s] = video_obj_from_cloud[:run_time]
          video_obj_from_cloud.delete(:run_time)
        end
        if video_obj_from_cloud[:constraints].nil? or video_obj_from_cloud[:constraints].empty?
          video_obj_from_cloud.delete(:constraints)
        end
        if video_obj_from_cloud[:quality].nil?
          video_obj_from_cloud.delete(:quality)
        end
        if video_obj_from_cloud[:purchase_type] == ""
          video_obj_from_cloud.delete(:purchase_type)
        end
        if video_obj_from_cloud[:source_id] == "hulu"
          video_obj_from_cloud.delete(:source_program_id)
        end

        if video_obj_from_cloud[:fetched_from].nil?
          rovi_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "gracenote"
          # gn_url = video_obj_from_cloud[:link][:uri]
          # gracenote_videos_list_got_from_cloud.push(gn_url)
          gracenote_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "hulu"
          hulu_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "vudu"
          vudu_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "crawler"
          crawler_videos_list_got_from_cloud.push(video_obj_from_cloud)
        end
        all_videos_list_got_from_cloud.push(video_obj_from_cloud)
      end
    else
      #$log.info "Inside else, empty cloud response"
      log.info "Inside else, empty cloud response"
    end

    videos_got_from_cloud = {"Rovi Videos"=> rovi_videos_list_got_from_cloud,"Gracenote Videos"=> gracenote_videos_list_got_from_cloud,"Hulu Videos"=> hulu_videos_list_got_from_cloud,"Vudu Videos"=> vudu_videos_list_got_from_cloud,"Crawler Videos"=>crawler_videos_list_got_from_cloud,"All Videos"=> all_videos_list_got_from_cloud}
     log.info "Videos got from Rovi cloud: #{rovi_videos_list_got_from_cloud}"
     log.info "Videos got from Gn cloud: #{gracenote_videos_list_got_from_cloud}"
    #$log.info "Videos got from cloud: #{videos_got_from_cloud}"
    log.info "Videos got from cloud: #{videos_got_from_cloud}"
    videos_got_from_cloud
  end

  def get_ott_links_of_individual_service_from_cloud(prog_id,service,log)
    #$log.info "Ozone Api Spec Functions::get_ott_links_of_individual_service_from_cloud"
    log.info "Ozone Api Spec Functions::get_ott_links_of_individual_service_from_cloud"
    videos_got_from_cloud = {"Rovi Videos"=> [],"Gracenote Videos"=> []}
    rovi_videos_list_got_from_cloud = Array.new
    gracenote_videos_list_got_from_cloud = Array.new
    get "/programs/#{prog_id}/videos"
    expect_status('200')
    #$log.info json_body
    len = json_body.length
    if len > 0
      #$log.info "Inside if len > O"
      log.info "Inside if len > O"
 
      for i in 0..len-1
        video_obj_from_cloud = json_body[i]
        ind_service_name = video_obj_from_cloud[:source_id]
        if service == ind_service_name
          #$log.info "#{ind_service_name} is of type #{service}, going to process"
          log.info "#{ind_service_name} is of type #{service}, going to process"
          if video_obj_from_cloud[:fetched_from].nil?
            #$log.info "Rovi object, hence remove all dynamic key-value pairs"
            log.info "Rovi object, hence remove all dynamic key-value pairs"
            video_obj_from_cloud.delete(:platform)
            video_obj_from_cloud.delete(:last_refreshed_timestamp)
            video_obj_from_cloud.delete(:content_expiry_timestamp)
            video_obj_from_cloud.delete(:cache_expiry_timestamp)
            video_obj_from_cloud.delete(:launch_id)
            video_obj_from_cloud.delete(:created_at)
            video_obj_from_cloud.delete(:updated_at)
            video_obj_from_cloud.delete(:refreshed_at)
            video_obj_from_cloud.delete(:with_subscription)
            video_obj_from_cloud.delete(:subscription_type)
            video_obj_from_cloud.delete(:audio_languages)
            if video_obj_from_cloud[:run_time].nil?
              video_obj_from_cloud.delete(:run_time)
            else
              video_obj_from_cloud[:content_runtime_s] = video_obj_from_cloud[:run_time]
              video_obj_from_cloud.delete(:run_time)
            end
            if video_obj_from_cloud[:constraints].empty?
              video_obj_from_cloud.delete(:constraints)
            end
            if video_obj_from_cloud[:quality].nil?
              video_obj_from_cloud.delete(:quality)
            end
            if video_obj_from_cloud[:purchase_type] == ""
              video_obj_from_cloud.delete(:purchase_type)
            end
            if video_obj_from_cloud[:source_id] == "hulu"
              video_obj_from_cloud.delete(:source_program_id)
            end

            rovi_videos_list_got_from_cloud.push(video_obj_from_cloud)

          elsif video_obj_from_cloud[:fetched_from] == "gracenote"
            #$log.info "GN object, hence adding only url to array"
            log.info "GN object, hence adding only url to array"
            gn_url = video_obj_from_cloud[:link][:uri]
            gracenote_videos_list_got_from_cloud.push(gn_url)
          end

        else
          #$log.info "#{ind_service_name} is not of type #{service}, moving to next"
          log.info "#{ind_service_name} is not of type #{service}, moving to next"
          next
        end
      end
    else
      #$log.info "Inside else, empty cloud response"
      log.info "Inside else, empty cloud response"
    end

    videos_got_from_cloud = {"Rovi Videos"=> rovi_videos_list_got_from_cloud,"Gracenote Videos"=> gracenote_videos_list_got_from_cloud}
 
    #$log.info "Videos got from cloud for the service #{service}: #{videos_got_from_cloud}"
    log.info "Videos got from cloud for the service #{service}: #{videos_got_from_cloud}"
    videos_got_from_cloud
  end

  def check_for_index_of_array_element(arr_of_airdate_programs,series_nm,se_num,ep_num,log)
    indx = nil
    arr_len = arr_of_airdate_programs.length
    for i in 0..arr_len-1
      array_elem = arr_of_airdate_programs[i]
      #$log.info "Going to compare csv value(series name):#{array_elem[0]} with #{series_nm},csv value(season num): #{array_elem[1]} with #{se_num} & csv value(episode num): #{array_elem[2]} with #{ep_num}"
      log.info "Going to compare csv value(series name):#{array_elem[0]} with #{series_nm},csv value(season num): #{array_elem[1]} with #{se_num} & csv value(episode num): #{array_elem[2]} with #{ep_num}"
 
      if array_elem[0].casecmp(series_nm).zero? and array_elem[1].to_i == se_num and array_elem[2].to_i == ep_num
        #$log.info "We've found a match return index #{i}"
        log.info "We've found a match return index #{i}"
        indx = i
        break
      end
    end
    indx
  end


  def categorise_video_links(ott_links_from_cloud,log)
    #$log.info "Api_spec_functions:: categorise_video_links"
    log.info "Api_spec_functions:: categorise_video_links"
    amazon = Array.new
    hulu = Array.new
    vudu = Array.new
    netflixusa = Array.new
    showtimeanytime = Array.new
    showtime = Array.new
    hbogo = Array.new
    hbonow = Array.new
    youtube = Array.new
    itunes = Array.new

    if !ott_links_from_cloud.empty?
      no_of_ott_links = ott_links_from_cloud.length
      for i in 0..no_of_ott_links-1
        video_obj = ott_links_from_cloud[i]

        ind_service_name = video_obj[:source_id]
        ind_service_url = video_obj[:link][:uri]
        case ind_service_name

        when "amazon"
        amazon.push(ind_service_url)

        when "hulu"
        hulu.push(ind_service_url)

        when "vudu"
        vudu.push(ind_service_url)

        when "netflixusa"
        netflixusa.push(ind_service_url)

        when "showtimeanytime"
        showtimeanytime.push(ind_service_url)

        when "showtime"
        showtime.push(ind_service_url)

        when "hbogo"
        hbogo.push(ind_service_url)

        when "hbonow"
        hbonow.push(ind_service_url)

        when "youtube"
        youtube.push(ind_service_url)

        when "itunes"
        itunes.push(ind_service_url)

        end
      end
    end
    ott_links_by_category = {"amazon" => amazon,"hbogo" => hbogo,"hulu" => hulu,"netflixusa" => netflixusa,"showtimeanytime" => showtimeanytime,"showtime" => showtime,"hbonow" => hbonow,"vudu" => vudu,"youtube" => youtube,"itunes" => itunes}
    #$log.info "Links got from cloud: #{ott_links_by_category}"
    log.info "Links got from cloud: #{ott_links_by_category}"
    ott_links_by_category
  end

  def categorise_launch_ids_based_on_service(ott_links_from_cloud,show_type,log)
    #$log.info "Api_spec_functions:: categorise_video_links"
    log.info "Api_spec_functions:: categorise_video_links"
    amazon = Array.new
    hulu = Array.new
    vudu = Array.new
    netflixusa = Array.new
    showtimeanytime = Array.new
    showtime = Array.new
    hbogo = Array.new
    hbonow = Array.new
    youtube = Array.new
    itunes = Array.new
    launch_id = nil

    if !ott_links_from_cloud.empty?
      no_of_ott_links = ott_links_from_cloud.length
      for i in 0..no_of_ott_links-1
        video_obj = ott_links_from_cloud[i]

       # ind_service_name = video_obj[:source_id] serv_name
       ind_service_name = video_obj[:source_id]
        ind_service_url = video_obj[:link][:uri]
        case ind_service_name

        when "amazon"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?amazon\.com\/([a-zA-Z\/]*)\/([A-Za-z0-9]+)/)[3]
        amazon.push(launch_id)

        when "hulu"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?hulu\.com\/watch\/([A-Za-z0-9]+)/)[2]
        hulu.push(launch_id)

        when "vudu"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?vudu\.com\/movies\/#!content\/([A-Za-z0-9]+)/)[2]
        vudu.push(launch_id)

        when "netflixusa"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?netflix\.com\/([a-zA-Z]+)\/([0-9]+)/)[3]
        netflixusa.push(launch_id)

        when "showtimeanytime"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?showtime(anytime)?\.com\/#\/([a-zA-Z]+)\/([A-Za-z0-9]+)/)[4]
          showtimeanytime.push(launch_id)

        when "showtime"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?showtime(anytime)?\.com\/#\/([a-zA-Z]+)\/([A-Za-z0-9]+)/)[4]
          showtime.push(launch_id)

        when "hbogo"
          #launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?hbogo\.com\/#home\/([a-zA-Z&]+)=([A-Za-z0-9]+)/)[3]
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?hbogo\.com\/#([a-z]+)\/([a-zA-Z&;]+)=([A-Za-z0-9]+)/)[4]
          hbogo.push(launch_id)

        when "hbonow"
          #launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?hbogo\.com\/#home\/([a-zA-Z&;]+)=([A-Za-z0-9]+)/)[3]
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?hbonow\.com\/(.+)\/(.+)\/(.+)\/(.+)/)[5]
          hbonow.push(launch_id)

        when "youtube"
          #launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?youtube\.com\/([a-zA-Z]+)\?v=([A-Za-z0-9]+)/)[3]
          #                            match(/http[s]?:\/\/(www.)?youtube\.com\/([a-zA-Z]+)\?v=([A-Za-z0-9]+)/)[3]
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?youtube\.com\/([a-zA-Z]+)\?v=(.+)+/)[3]
          youtube.push(launch_id)

        when "itunes"
          if show_type == "MO"
            log.info "Show type - MO"
            launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?itunes\.apple\.com\/us\/([a-zA-Z0-9\-\/]*)([a-zA-Z0-9\/\-\.]*)\/id([0-9]+)(\?i=)?([0-9]*)/)[4]
          else
            log.info "Show type - SE"
            launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?itunes\.apple\.com\/us\/([a-zA-Z0-9\-\/]*)([a-zA-Z0-9\/\-\.]*)\/id([0-9]+)(\?i=)?([0-9]*)/)[6]
          end
          itunes.push(launch_id)

        end
      end
    end
    ott_links_by_category = {"amazon" => amazon,"hbogo" => hbogo,"hulu" => hulu,"netflixusa" => netflixusa,"showtimeanytime" => showtimeanytime,"showtime" => showtime,"hbonow" => hbonow,"vudu" => vudu,"youtube" => youtube,"itunes" => itunes}
    #$log.info "Links got from cloud: #{ott_links_by_category}"
    log.info "Links got from cloud: #{ott_links_by_category}"
    ott_links_by_category
  end

  def categorise_ozone_launch_ids_based_on_service(ott_links_from_cloud,show_type,log)
    log.info "Api_spec_functions:: categorise_ozone_launch_ids_based_on_service"
    amazon = Array.new
    hulu = Array.new
    vudu = Array.new
    netflixusa = Array.new
    showtimeanytime = Array.new
    showtime = Array.new
    hbogo = Array.new
    hbonow = Array.new
    youtube = Array.new
    itunes = Array.new
    launch_id = nil

    if !ott_links_from_cloud.empty?
      no_of_ott_links = ott_links_from_cloud.length
      for i in 0..no_of_ott_links-1
        video_obj = ott_links_from_cloud[i]

        #ind_service_name = $serv_name
        ind_service_name = video_obj[:source_id]
        log.info "Service name: #{ind_service_name}"
        ind_service_url = video_obj[:link][:uri]
        log.info "Service url: #{ind_service_url}"
        case ind_service_name

        when "amazon"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?amazon\.com\/([a-zA-Z\/]*)\/([A-Za-z0-9]+)/)[3]
        amazon.push(launch_id)

        when "hulu"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?hulu\.com\/watch\/([A-Za-z0-9]+)/)[2]
        hulu.push(launch_id)

        when "vudu"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?vudu\.com\/movies\/#!content\/([A-Za-z0-9]+)/)[2]
        vudu.push(launch_id)

        when "netflixusa"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?netflix\.com\/([a-zA-Z]+)\/([0-9]+)/)[3]
        netflixusa.push(launch_id)

     # Service url: http://www.netflix.com/WiPlayer?movieid=70274108


        when "showtimeanytime"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?showtime(anytime)?\.com\/#\/([a-zA-Z]+)\/([A-Za-z0-9]+)/)[4]
          showtimeanytime.push(launch_id)

        when "showtime"
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?showtime(anytime)?\.com\/#\/([a-zA-Z]+)\/([A-Za-z0-9]+)/)[4]
          showtime.push(launch_id)

        when "hbogo"
          #launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?hbogo\.com\/#home\/([a-zA-Z&;]+)=([A-Za-z0-9]+)/)[3]
          if ind_service_url.include?"play"
          log.info "The URL has play in it"   
          launch_id = ind_service_url.gsub("https://play.hbogo.com/episode/urn:hbo:episode:","")
          else
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?hbogo\.com\/#([a-z]+)\/([a-zA-Z&;]+)=([A-Za-z0-9]+)/)[4]
          end  
          log.info "Launch id: #{launch_id}"
          hbogo.push(launch_id)

        when "hbonow"
          #launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?hbogo\.com\/#home\/([a-zA-Z&;]+)=([A-Za-z0-9]+)/)[3]
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?hbonow\.com\/(.+)\/(.+)\/(.+)\/(.+)/)[5]
          hbonow.push(launch_id)

        when "youtube"
          #launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?youtube\.com\/([a-zA-Z]+)\?v=([A-Za-z0-9]+)/)[3]
          launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?youtube\.com\/([a-zA-Z]+)\?v=(.+)+/)[3]
          youtube.push(launch_id)

        when "itunes"
          if show_type == "MO"
            launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?itunes\.apple\.com\/us\/([a-zA-Z0-9\-\/]*)([a-zA-Z0-9\/\-\.]*)\/id([0-9]+)(\?i=)?([0-9]*)/)[4]
          else
            launch_id = ind_service_url.match(/http[s]?:\/\/(www.)?itunes\.apple\.com\/us\/([a-zA-Z0-9\-\/]*)([a-zA-Z0-9\/\-\.]*)\/id([0-9]+)(\?i=)?([0-9]*)/)[6]
          end
          itunes.push(launch_id)
          #Service url: https://itunes.apple.com/us/tv-season/season-3-episode-1-no-m%C3%A1s/id940287472?i=942691590

        end
      end
    end
    ott_links_by_category = {"amazon" => amazon,"hbogo" => hbogo,"hulu" => hulu,"netflixusa" => netflixusa,"showtimeanytime" => showtimeanytime,"showtime" => showtime,"hbonow" => hbonow,"vudu" => vudu,"youtube" => youtube,"itunes" => itunes}
    #$log.info "Links got from cloud: #{ott_links_by_category}"
    log.info "Links got from cloud: #{ott_links_by_category}"
    ott_links_by_category
  end

  def make_one_single_array(arr_of_arr)
    single_arr = Array.new
    len = arr_of_arr.length
    for i in 0..len-1
      if !arr_of_arr[i].empty?
        arr_of_arr[i].each do |arr_elem|
          single_arr.push(arr_elem)
        end
      end
    end
    single_arr
  end

  def get_categorised_gn_launch_ids(hash_of_gn_links,show_type,log)
    log.info "API Specs::get_categorised_gn_launch_ids"
    gn_categorised_launch_id_hash = {}
    links = nil
    arr_launch_ids = nil
    gn_services = hash_of_gn_links.keys
    gn_services.each do |service|
      links = hash_of_gn_links[service]
      arr_launch_ids = Array.new

      case service

        when "amazon"
          links.each do |link|
            launch_id = link.match(/http[s]?:\/\/(www.)?amazon\.com\/([a-zA-Z\/]*)\/([A-Za-z0-9]+)/)[3]
            arr_launch_ids.push(launch_id)
          end

        when "hulu"
          links.each do |link|
            launch_id = link.match(/http[s]?:\/\/(www.)?hulu\.com\/watch\/([A-Za-z0-9]+)/)[2]
            arr_launch_ids.push(launch_id)
          end

        when "vudu"
          links.each do |link|
            launch_id = link.match(/http[s]?:\/\/(www.)?vudu\.com\/movies\/#!content\/([A-Za-z0-9]+)/)[2]
            arr_launch_ids.push(launch_id)
          end

        when "netflixusa"
          links.each do |link|
            launch_id = link.match(/http[s]?:\/\/(www.)?netflix\.com\/([a-zA-Z]+)\/([0-9]+)/)[3]
            arr_launch_ids.push(launch_id)
          end

        when "showtimeanytime"
          links.each do |link|
            launch_id = link.match(/http[s]?:\/\/(www.)?showtime(anytime)?\.com\/#\/([a-zA-Z]+)\/([A-Za-z0-9]+)/)[4]
            arr_launch_ids.push(launch_id)
          end

        when "showtime"
          links.each do |link|
            launch_id = link.match(/http[s]?:\/\/(www.)?showtime(anytime)?\.com\/#\/([a-zA-Z]+)\/([A-Za-z0-9]+)/)[4]
            arr_launch_ids.push(launch_id)
          end

        when "hbo"
          links.each do |link|
            #launch_id = link.match(/http[s]?:\/\/(www.)?hbogo\.com\/#home\/([a-zA-Z&;]+)=([A-Za-z0-9]+)/)[3]
            launch_id = link.match(/http[s]?:\/\/(www.)?hbogo\.com\/#([a-z]+)\/([a-zA-Z&;]+)=([A-Za-z0-9]+)/)[4]
            arr_launch_ids.push(launch_id)
          end

        when "hbonow"
          links.each do |link|
            #launch_id = link.match(/http[s]?:\/\/(www.)?hbonow\.com\/([a-zA-Z0-9]+)\/(.+)+\/0\/(.+)/)[4]
            launch_id = link.match(/http[s]?:\/\/(www.)?hbonow\.com\/(.+)\/(.+)\/(.+)\/(.+)/)[5]
            arr_launch_ids.push(launch_id)
          end

        when "youtube"
          links.each do |link|
            #launch_id = link.match(/http[s]?:\/\/(www.)?youtube\.com\/([a-zA-Z]+)\?v=([A-Za-z0-9]+)/)[3]
            launch_id = link.match(/http[s]?:\/\/(www.)?youtube\.com\/([a-zA-Z]+)\?v=(.+)+/)[3]
            arr_launch_ids.push(launch_id)
          end

        when "itunes"
          links.each do |link|
            if show_type == "MO"
              log.info "Show type - MO"
              launch_id = link.match(/http[s]?:\/\/(www.)?itunes\.apple\.com\/us\/([a-zA-Z0-9\-\/]*)([a-zA-Z0-9\/\-\.]*)\/id([0-9]+)(\?i=)?([0-9]*)/)[4]
            else
              log.info "Show type - SE"
              launch_id = link.match(/http[s]?:\/\/(www.)?itunes\.apple\.com\/us\/([a-zA-Z0-9\-\/]*)([a-zA-Z0-9\/\-\.]*)\/id([0-9]+)(\?i=)?([0-9]*)/)[6]
            end
            # launch_id = link.match(/http[s]?:\/\/(www.)?itunes\.apple\.com\/us\/([a-zA-Z0-9\-\/]*)([a-zA-Z0-9\/\-\.]*)\/id([0-9]+)(\?i=)?([0-9]*)/)[4]
            arr_launch_ids.push(launch_id)
          end

        end

        gn_categorised_launch_id_hash[service] = arr_launch_ids
        log.info "Launch ids for #{service}: arr_launch_ids"
    end
    log.info "gn_categorised_launch_id_hash: #{gn_categorised_launch_id_hash}"
    gn_categorised_launch_id_hash
  end

  def query_gn_dump_and_check_for_availability_of_movie_for_a_particular_service(client,movie_name,release_year,serv_name,log)
    gn_coll = client[:GN_ott_episodes_ott]
    dump_date = Date.today - 1
    gn_mongo = nil
    cnt = gn_coll.count({"title" => /#{movie_name}/i,"release_year" => release_year,"show_type" => "MO","gn_dump_date" => dump_date})
    if cnt == 0
      #$log.info "Can't find movie: #{movie_name} in GN dump with release_year: #{release_year}"
      log.info "Can't find movie: #{movie_name} in GN dump with release_year: #{release_year}"
      $arr_prog_ids.push([movie_name,release_year,"Movie not available on Rovi","Movie not available on Gracenote","FAIL"])
      $not_avail_on_rovi_and_gn_cnt = $not_avail_on_rovi_and_gn_cnt + 1
      #$log.info "$not_avail_on_rovi_and_gn_cnt: #{$not_avail_on_rovi_and_gn_cnt}"
      log.info "$not_avail_on_rovi_and_gn_cnt: #{$not_avail_on_rovi_and_gn_cnt}"
    else
      gn_coll.find({"title" => /#{movie_name}/i,"release_year" => release_year,"show_type" => "MO","gn_dump_date" => dump_date}).limit(1).each do |doc|
        gn_mongo = nil
        doc_json = doc.to_json
              #log.info "Value from mongo: #{doc_json} before processing"
 
        parsed_doc = JSON.parse(doc_json)
        #$log.info parsed_doc
        log.info "Resp from GN dump: #{parsed_doc}"
        #array_elem.push(parsed_doc)
        gn_links_from_mongo = parsed_doc["Videos"]
        if !gn_links_from_mongo.empty?
          services_from_mongo = gn_links_from_mongo.keys

          #$log.info "Filter out the GN Mongo response to contain only supported services"
          log.info "Filter out the GN Mongo response to contain only supported services"
          services_from_mongo.each do |key|
            if key.downcase == serv_name
                next
              else
                gn_links_from_mongo.delete(key)
            end
          end
          #$log.info "gn_links_from_mongo for movie-#{movie_name} for service-#{serv_name}: #{gn_links_from_mongo}"
          log.info "gn_links_from_mongo for movie-#{movie_name} for service-#{serv_name}: #{gn_links_from_mongo}"
          gn_links_from_mongo_final = gn_links_from_mongo.values
          gn_mongo = make_one_single_array(gn_links_from_mongo_final)
          #$log.info "Main: gn_mongo for movie-#{movie_name}: #{gn_mongo}"
 
        else
            gn_mongo = []
            #$log.info "Main: GN Metadata available, but no valid gn links for program in dump"
            log.info "Main: GN Metadata available, but no valid gn links for program in dump"
        end
      end
      if !gn_mongo.empty?
        log.info "Main: gn_mongo for movie-#{movie_name}: #{gn_mongo}"
        $not_avail_on_rovi_but_avail_on_gn_cnt = $not_avail_on_rovi_but_avail_on_gn_cnt + 1
        #$log.info "not_avail_on_rovi_but_avail_on_gn_cnt: #{not_avail_on_rovi_but_avail_on_gn_cnt}"
        log.info "$not_avail_on_rovi_but_avail_on_gn_cnt: #{$not_avail_on_rovi_but_avail_on_gn_cnt}"
        $arr_prog_ids.push([movie_name,"MO",release_year,"Movie not available on Rovi","But movie available on GN.","GN links: #{gn_mongo}"])
      else
        $not_avail_on_rovi_and_gn_cnt = $not_avail_on_rovi_and_gn_cnt + 1
        #$log.info "$not_avail_on_rovi_and_gn_cnt: #{$not_avail_on_rovi_and_gn_cnt}"
        log.info "$not_avail_on_rovi_and_gn_cnt: #{$not_avail_on_rovi_and_gn_cnt}"
        $arr_prog_ids.push([movie_name,"MO",release_year,"Movie not available on Rovi","Movie not available on Gracenote","FAIL"])
      end
    end
  end

  def check_for_ingestion_of_particular_service_rovi_or_gn_ott_links_in_movie(ott_links_cloud,client,prog_id,movie_name,release_year,serv_name,log)
    dump_date = Date.today - 1
    rovi_vids_cloud = ott_links_cloud["Rovi Videos"]
    gn_vids_cloud = ott_links_cloud["Gracenote Videos"]
    #$log.info rovi_vids_cloud
    log.info "#{rovi_vids_cloud}"
    if !rovi_vids_cloud.empty?
      rovi_vids_mongo = get_rovi_ind_service_ott_links_from_mongo_db(client,prog_id,serv_name,log)
      diff1 = rovi_vids_mongo - rovi_vids_cloud
      #$log.info "Few Mongo vids are missing in cloud :#{diff1}"
      log.info "Few Mongo vids are missing in cloud :#{diff1}"
      diff2 = rovi_vids_cloud - rovi_vids_mongo
      #$log.info "Extra vids in cloud which were not there in rovi dump :#{diff2}"
      log.info "Extra vids in cloud which were not there in rovi dump :#{diff2}"
      if diff1.empty? and diff2.empty?
        #$log.info "Rovi Ingestion Status for movie-#{movie_name}: PASS"
        log.info "Rovi Ingestion Status for movie-#{movie_name}: PASS"
        $rovi_ingestion_status = "Rovi Ingestion Status: PASS"
        $rovi_ingest_success_cnt = $rovi_ingest_success_cnt + 1
        #$log.info "Rovi Ingesion-PASS count: #{$rovi_ingest_success_cnt}"
        log.info "Rovi Ingesion-PASS count: #{$rovi_ingest_success_cnt}"
      else
        #$log.info "Rovi Ingestion Status for movie-#{movie_name}: FAIL"
        log.info "Rovi Ingestion Status for movie-#{movie_name}: FAIL"
        $rovi_ingestion_status = "Rovi Ingestion Status: FAIL"
        $rovi_ingest_failures_cnt = $rovi_ingest_failures_cnt + 1
        #$log.info "Rovi Ingesion-FAIL count: #{$rovi_ingest_failures_cnt}"
        log.info "Rovi Ingesion-FAIL count: #{$rovi_ingest_failures_cnt}"
      end
      $arr_prog_ids.push([movie_name,"MO",release_year,prog_id,"Rovi Video Links available on cloud",$rovi_ingestion_status])
      $avail_on_rovi_cnt = $avail_on_rovi_cnt + 1
      #$log.info "avail_on_rovi_cnt: #{$avail_on_rovi_cnt}"
      log.info "avail_on_rovi_cnt: #{$avail_on_rovi_cnt}"
    elsif !gn_vids_cloud.empty?
      #$log.info "avail_on_gracenote_after_mapping_cnt: #{$avail_on_gracenote_after_mapping_cnt}"
      log.info "avail_on_gracenote_after_mapping_cnt: #{$avail_on_gracenote_after_mapping_cnt}"
      #gn_vids_cloud = ott_links_cloud["Gracenote Videos"]
      # $log.info gn_vids_cloud
      # log.info gn_vids_cloud
      gn_coll = client[:GN_ott_episodes_ott]
      cnt = gn_coll.count({"title" => /#{movie_name}/i,"release_year" => release_year,"show_type" => "MO","gn_dump_date" => dump_date})
      if cnt == 0
        #$log.info "Can't find movie: #{movie_name} in GN dump with release_year: #{release_year}"
        log.info "Can't find movie: #{movie_name} in GN dump with release_year: #{release_year}"
        $arr_prog_ids.push([movie_name,"MO",release_year,"GN Video Links available in cloud","Unable to map with Gracenote dump,hence cannot check ingestion status"])
        $avail_on_gracenote_and_unable_to_map_cnt = $avail_on_gracenote_and_unable_to_map_cnt + 1
        #$log.info "avail_on_gracenote_and_unable_to_map_cnt: #{$avail_on_gracenote_and_unable_to_map_cnt}"
        log.info "avail_on_gracenote_and_unable_to_map_cnt: #{$avail_on_gracenote_and_unable_to_map_cnt}"
      else
        gn_coll.find({"title" => /#{movie_name}/i,"release_year" => release_year,"show_type" => "MO","gn_dump_date" => dump_date}).limit(1).each do |doc|
          gn_vids_mongo = nil
          doc_json = doc.to_json
          #log.info "Value from mongo: #{doc_json} before processing"
 
          parsed_doc = JSON.parse(doc_json)
          #$log.info parsed_doc
          log.info "Resp from GN dump: #{parsed_doc}"
          #array_elem.push(parsed_doc)
          gn_links_from_mongo = parsed_doc["Videos"]
          if !gn_links_from_mongo.empty?
            services_from_mongo = gn_links_from_mongo.keys

            #$log.info "Filter out the GN Mongo response to contain only #{serv_name} service"
            log.info "Filter out the GN Mongo response to contain only #{serv_name} service"
            services_from_mongo.each do |key|
              if key.downcase == serv_name or serv_name.include? key.downcase
                next
              else
                gn_links_from_mongo.delete(key)
              end
            end
          else
            gn_vids_mongo = []
            #$log.info "Main: GN Metadata available, but no valid gn links for program in dump"
            log.info "Main: GN Metadata available, but no valid gn links for program in dump"
          end
          #$log.info "gn_links_from_mongo for movie-#{movie_name}: #{gn_links_from_mongo}"
          log.info "gn_links_from_mongo for movie-#{movie_name}: #{gn_links_from_mongo}"
          gn_links_from_mongo_final = gn_links_from_mongo.values
          gn_vids_mongo = make_one_single_array(gn_links_from_mongo_final)
          #$log.info "Main: gn_vids_mongofor movie-#{movie_name}: #{gn_vids_mongo}"
          log.info "Main: gn_vids_mongo for movie-#{movie_name}: #{gn_vids_mongo}"

          if !gn_vids_mongo.empty? and !gn_vids_cloud.empty?
            $avail_on_gracenote_after_mapping_cnt = $avail_on_gracenote_after_mapping_cnt + 1
            #$log.info "inside if both gn_vids_mongo and gn_vids_cloud are not empty, proceed to ingestion validation"
            log.info "inside if both gn_vids_mongo and gn_vids_cloud are not empty, proceed to ingestion validation"
            #$log.info "gn_vids_cloud: #{gn_vids_cloud}"
            log.info "gn_vids_cloud: #{gn_vids_cloud}"

            diff1 = gn_vids_mongo - gn_vids_cloud
            #$log.info "Few GN Mongo vids are missing in cloud :#{diff1}"
            log.info "Few GN Mongo vids are missing in cloud :#{diff1}"
            diff2 = gn_vids_cloud - gn_vids_mongo
            #$log.info "Extra GN vids in cloud which were not there in rovi dump :#{diff2}"
            log.info "Extra GN vids in cloud which were not there in rovi dump :#{diff2}"
            if diff1.empty? and diff2.empty?
              #$log.info "GN Ingestion Status for movie-#{movie_name}: PASS"
              log.info "GN Ingestion Status for movie-#{movie_name}: PASS"
              $gn_ingestion_status = "GN Ingestion Status: PASS"
              $gn_ingest_success_cnt = $gn_ingest_success_cnt + 1
              #$log.info "GN Ingestion Status: PASS count: #{$gn_ingest_success_cnt}"
              log.info "GN Ingestion Status: PASS count: #{$gn_ingest_success_cnt}"
            else
              #$log.info "GN Ingestion Status for movie-#{movie_name}: FAIL"
              log.info "GN Ingestion Status for movie-#{movie_name}: FAIL"
              $gn_ingestion_status = "GN Ingestion Status: FAIL"
              $gn_ingest_failures_cnt = $gn_ingest_failures_cnt + 1
              #$log.info "GN Ingestion Status: FAIL count: #{$gn_ingest_failures_cnt}"
              log.info "GN Ingestion Status: FAIL count: #{$gn_ingest_failures_cnt}"
            end
            $arr_prog_ids.push([movie_name,"MO",release_year,"GN Video Links available in cloud",$gn_ingestion_status])
          else
            if gn_vids_mongo.empty? and gn_vids_cloud.empty?
              #$log.info "inside if both gn_vids_mongo and gn_vids_cloud are empty"
              log.info "inside if both gn_vids_mongo and gn_vids_cloud are empty"
              $arr_prog_ids.push([movie_name,"MO",release_year,"Not available for Movie in Rovi & GN Dumps","Overall Status: FAIL"])
              $not_avail_on_rovi_and_gn_cnt = $not_avail_on_rovi_and_gn_cnt + 1
              #$log.info "$not_avail_on_rovi_and_gn_cnt: #{$not_avail_on_rovi_and_gn_cnt}"
              log.info "$not_avail_on_rovi_and_gn_cnt: #{$not_avail_on_rovi_and_gn_cnt}"
            elsif gn_vids_mongo.empty? or gn_vids_cloud.empty?
              $avail_on_gracenote_after_mapping_cnt = $avail_on_gracenote_after_mapping_cnt + 1
              #$log.info "One of gn_vids_mongo and gn_vids_cloud are empty, gn ingestion error"
              log.info "One of gn_vids_mongo and gn_vids_cloud are empty, gn ingestion error"
              $gn_ingestion_status = "GN Ingestion Status: FAIL"
              $gn_ingest_failures_cnt = $gn_ingest_failures_cnt + 1
              #$log.info "GN Ingestion Status: FAIL count: #{$gn_ingest_failures_cnt}"
              log.info "GN Ingestion Status: FAIL count: #{$gn_ingest_failures_cnt}"
              $arr_prog_ids.push([movie_name,"MO",release_year,"GN Video Links available in cloud",$gn_ingestion_status])
            end
          end
        end
      end
      $real_gn_ingestion_cnt = $avail_on_gracenote_after_mapping_cnt - $avail_on_gracenote_and_unable_to_map_cnt
    else
      $arr_prog_ids.push([movie_name,"MO",release_year,prog_id,"No Video Links Available in Cloud,though metadata is available","Rovi Video not Links available on cloud","GN Video Links not available in cloud","FAIL"])
    end
  end

  def check_for_ingestion_of_particular_service_rovi_or_gn_ott_links_in_series_episode(ott_links_from_cloud,client,prog_id,serv_name,series_name,season_no,episode_no,episode_title,log)
    ###################################
    ###################################
    #$log.info "API Spec Functions:: check_for_ingestion_of_particular_service_rovi_or_gn_ott_links_in_series_episode"
    log.info "API Spec Functions:: check_for_ingestion_of_particular_service_rovi_or_gn_ott_links_in_series_episode"
    dump_date = Date.today - 1
    rovi_vids_cloud = ott_links_from_cloud["Rovi Videos"]
    gn_vids_cloud = ott_links_from_cloud["Gracenote Videos"]
    crawler_vids_cloud = ott_links_from_cloud["Crawlers"]

    if !rovi_vids_cloud.empty?
      #$log.info "Episode has ott links from Rovi, proceed to validate rovi ingestion"
      log.info "Episode has ott links from Rovi, proceed to validate rovi ingestion"
      rovi_vids_mongo = get_rovi_ind_service_ott_links_from_mongo_db(client,prog_id,serv_name,log)
      diff1 = rovi_vids_mongo - rovi_vids_cloud
      #$log.info "Few Mongo vids are missing in cloud :#{diff1}"
      log.info "Few Mongo vids are missing in cloud :#{diff1}"
      diff2 = rovi_vids_cloud - rovi_vids_mongo
      #$log.info "Extra vids in cloud which were not there in rovi dump :#{diff2}"
      log.info "Extra vids in cloud which were not there in rovi dump :#{diff2}"
      if diff1.empty? and diff2.empty?
        #$log.info "Rovi Ingestion Status for #{series_name}, Se #{season_no}, Ep #{episode_no}: PASS"
        log.info "Rovi Ingestion Status for #{series_name}, Se #{season_no}, Ep #{episode_no}: PASS"
        $rovi_ingestion_status = "Rovi Ingestion Status: PASS"
        $rovi_ingest_success_cnt = $rovi_ingest_success_cnt + 1
        #$log.info "Rovi Ingesion-PASS count: #{$rovi_ingest_success_cnt}"
        log.info "Rovi Ingesion-PASS count: #{$rovi_ingest_success_cnt}"
      else
        #$log.info "Rovi Ingestion Status for #{series_name}, Se #{season_no}, Ep #{episode_no}: FAIL"
        log.info "Rovi Ingestion Status for #{series_name}, Se #{season_no}, Ep #{episode_no}: FAIL"
        $rovi_ingestion_status = "Rovi Ingestion Status: FAIL"
        $rovi_ingest_failures_cnt = $rovi_ingest_failures_cnt + 1
        $episodes_with_ott_errors_cnt = $episodes_with_ott_errors_cnt + 1
        #$log.info "Rovi Ingesion-FAIL count: #{$rovi_ingest_failures_cnt}"
        log.info "Rovi Ingesion-FAIL count: #{$rovi_ingest_failures_cnt}"
      end
      $arr_episode_prog_ids.push([series_name,season_no,episode_no,prog_id,"Rovi Video Links available on cloud",$rovi_ingestion_status])
      $avail_on_rovi_cnt = $avail_on_rovi_cnt + 1
      #$log.info "avail_on_rovi_cnt: #{avail_on_rovi_cnt}"
      log.info "avail_on_rovi_cnt: #{$avail_on_rovi_cnt}"
    elsif !gn_vids_cloud.empty?
      #$log.info "Episode has ott links from GN, proceed to validate gracenote ingestion"
      log.info "Episode has ott links from GN, proceed to validate gracenote ingestion"
      $avail_on_gracenote_after_mapping_cnt = $avail_on_gracenote_after_mapping_cnt + 1
      #$log.info "avail_on_gracenote_after_mapping_cnt: #{$avail_on_gracenote_after_mapping_cnt}"
      log.info "avail_on_gracenote_after_mapping_cnt: #{$avail_on_gracenote_after_mapping_cnt}"
      #gn_vids_cloud = ott_links_from_cloud["Gracenote Videos"]
      # $log.info gn_vids_cloud
      # log.info gn_vids_cloud
      gn_coll = client[:GN_ott_episodes_ott]
      cnt = gn_coll.count({"title" => /#{series_name}/i,"season_number" => "#{season_no}","episode_number" => "#{episode_no}","episode_title" => "#{episode_title}","gn_dump_date" => dump_date})
      if cnt == 0
        #$log.info "Can't find #{series_name}, Se #{season_no}, Ep #{episode_no} in GN dump"
        log.info "Can't find #{series_name}, Se #{season_no}, Ep #{episode_no} in GN dump"
        $arr_episode_prog_ids.push([series_name,season_no,episode_no,prog_id,"GN Video Links are shown in cloud","Unable to map, cannot check ingestion status"])
        $avail_on_gracenote_and_unable_to_map_cnt = $avail_on_gracenote_and_unable_to_map_cnt + 1
        #$log.info "avail_on_gracenote_and_unable_to_map_cnt: #{avail_on_gracenote_and_unable_to_map_cnt}"
        log.info "avail_on_gracenote_and_unable_to_map_cnt: #{$avail_on_gracenote_and_unable_to_map_cnt}"
      else
        gn_coll.find({"title" => /#{series_name}/i,"season_number" => "#{season_no}","episode_number" => "#{episode_no}","episode_title" => "#{episode_title}","gn_dump_date" => dump_date}).limit(1).each do |doc|
        gn_vids_mongo = nil
        doc_json = doc.to_json
        #log.info "Value from mongo: #{doc_json} before processing"
 
        parsed_doc = JSON.parse(doc_json)
        #$log.info parsed_doc
        log.info "Resp from GN dump: #{parsed_doc}"
        #array_elem.push(parsed_doc)
        gn_links_from_mongo = parsed_doc["Videos"]
        if !gn_links_from_mongo.empty?
          services_from_mongo = gn_links_from_mongo.keys

          #$log.info "Filter out the GN Mongo response to contain only #{serv_name} service"
          log.info "Filter out the GN Mongo response to contain only #{serv_name} service"
          services_from_mongo.each do |key|
            if key.downcase == serv_name or serv_name.include? key.downcase
              next
            else
              gn_links_from_mongo.delete(key)
            end
          end
        else
          gn_vids_mongo = []
          #$log.info "Main: GN Metadata available, but no valid gn links for program in dump"
          log.info "Main: GN Metadata available, but no valid gn links for program in dump"
        end
        #$log.info "gn_links_from_mongo for #{series_name}, Se #{season_no}, Ep #{episode_no}: #{gn_links_from_mongo}"
        log.info "gn_links_from_mongo for #{series_name}, Se #{season_no}, Ep #{episode_no}: #{gn_links_from_mongo}"
        gn_links_from_mongo_final = gn_links_from_mongo.values
        gn_vids_mongo = make_one_single_array(gn_links_from_mongo_final)
        #$log.info "Main: gn_vids_mongofor #{series_name}, Se #{season_no}, Ep #{episode_no}: #{gn_vids_mongo}"
        log.info "Main: gn_vids_mongo for #{series_name}, Se #{season_no}, Ep #{episode_no}: #{gn_vids_mongo}"

        #$log.info "gn_vids_cloud: #{gn_vids_cloud}"
        log.info "gn_vids_cloud: #{gn_vids_cloud}"

        diff1 = gn_vids_mongo - gn_vids_cloud
        #$log.info "Few GN Mongo vids are missing in cloud :#{diff1}"
        log.info "Few GN Mongo vids are missing in cloud :#{diff1}"
        diff2 = gn_vids_cloud - gn_vids_mongo
        #$log.info "Extra GN vids in cloud which were not there in rovi dump :#{diff2}"
        log.info "Extra GN vids in cloud which were not there in rovi dump :#{diff2}"
        if diff1.empty? and diff2.empty?
          #$log.info "GN Ingestion Status for #{series_name}, Se #{season_no}, Ep #{episode_no}: PASS"
          log.info "GN Ingestion Status for #{series_name}, Se #{season_no}, Ep #{episode_no}: PASS"
          $gn_ingestion_status = "GN Ingestion Status: PASS"
          $gn_ingest_success_cnt = $gn_ingest_success_cnt + 1
          #$log.info "GN Ingestion Status: PASS count: #{$gn_ingest_success_cnt}"
          log.info "GN Ingestion Status: PASS count: #{$gn_ingest_success_cnt}"
        else
          #$log.info "GN Ingestion Status for #{series_name}, Se #{season_no}, Ep #{episode_no}: FAIL"
          log.info "GN Ingestion Status for #{series_name}, Se #{season_no}, Ep #{episode_no}: FAIL"
          $gn_ingestion_status = "GN Ingestion Status: FAIL"
          $gn_ingest_failures_cnt = $gn_ingest_failures_cnt + 1
          $episodes_with_ott_errors_cnt = $episodes_with_ott_errors_cnt + 1
          #$log.info "GN Ingestion Status: FAIL count: #{$gn_ingest_failures_cnt}"
          log.info "GN Ingestion Status: FAIL count: #{$gn_ingest_failures_cnt}"
        end
        $arr_episode_prog_ids.push([series_name,season_no,episode_no,"GN Video Links available in cloud",$gn_ingestion_status])
      end
    end
    elsif !crawler_vids_cloud.empty?
      $episodes_with_ott_links_from_crawler = $episodes_with_ott_links_from_crawler + 1
      $arr_episode_prog_ids.push([series_name,season_no,episode_no,"Video Links available in cloud got from crawler"])
    end
    $real_gn_ingestion_cnt = $avail_on_gracenote_after_mapping_cnt - $avail_on_gracenote_and_unable_to_map_cnt
          ###################################
          ###################################
  end

  def validate_individual_service_links_in_all_series_episodes(client,series_name,prog_id,serv_name,netflix_no_of_seasons,log)
    #$log.info "Ozone_Api_Specific_Functions::validate_individual_service_links_in_all_series_episodes"
    log.info "Ozone_Api_Specific_Functions::validate_individual_service_links_in_all_series_episodes"
    videos_got_from_cloud = {"Rovi Videos" => [],"Gracenote Videos" => [],"Crawlers" => []}
    $episodes_without_ott_links_cnt = 0
    $episodes_cnt = 0
    $episodes_with_ott_errors_cnt = 0
    $episodes_with_ott_links_from_crawler = 0
    $rovi_ingest_success_cnt = 0
    $rovi_ingest_failures_cnt = 0
    $gn_ingest_failures_cnt = 0
    $gn_ingest_success_cnt = 0
    episodes_api = "/programs/#{prog_id}/episodes?ott=true&service=" + $serv_name
    get episodes_api
    response_code_validation("get",episodes_api)
    resp = json_body
    resp_len = resp.length
    for i in 0..resp_len-1
      #$log.info "For loop: #{i}th episode object"
      log.info "For loop: #{i}th episode object"
      #$log.info "Object: #{resp[i]}"
      log.info "Object: #{resp[i]}"
      ott_links_from_cloud_for_ind_service = resp[i][:videos]
      episode_title = resp[i][:original_episode_title]
      #$log.info "Episode title: #{episode_title}"
      log.info "Episode title: #{episode_title}"
      ser_name = resp[i][:long_title]
      #$log.info "Series: #{ser_name}"
      log.info "Series: #{ser_name}"
      seas_no = resp[i][:episode_season_number]
      #$log.info "Season no: #{seas_no}"
      log.info "Season no: #{seas_no}"
      episode_no = resp[i][:episode_season_sequence]
      #$log.info "Episode no: #{episode_no}"
      log.info "Episode no: #{episode_no}"
      ep_prog_id = resp[i][:id]
      #$log.info "Episode prog id: #{ep_prog_id}"
      log.info "Episode prog id: #{ep_prog_id}"
      #$log.info "Seas_no type: #{seas_no.class}"
      log.info "Seas_no type: #{seas_no.class}"
      #$log.info "netflix_no_of_seasons type: #{netflix_no_of_seasons.class}"
      log.info "netflix_no_of_seasonstype: #{netflix_no_of_seasons.class}"
      if seas_no <= netflix_no_of_seasons.to_i
        $episodes_cnt = $episodes_cnt + 1
        len = ott_links_from_cloud_for_ind_service.length
        rovi_videos_list_got_from_cloud = Array.new
        gracenote_videos_list_got_from_cloud = Array.new
        crawler_videos_list_got_from_cloud = Array.new
        if len > 0
          ##$log.info "Inside if len > O"
          log.info "Inside if len > O"
 
          for i in 0..len-1
            #$log.info "FOR Loop: To iterate through all #{serv_name} ott objects of a single episode"
            log.info "FOR Loop: To iterate through all #{serv_name} ott objects of a single episode"
            video_obj_from_cloud = ott_links_from_cloud_for_ind_service[i]
            ind_service_name = video_obj_from_cloud[:source_id]
            if $serv_name == ind_service_name
              #$log.info "#{ind_service_name} is of type #{serv_name}, going to process"
              log.info "#{ind_service_name} is of type #{serv_name}, going to process"
              if video_obj_from_cloud[:fetched_from].nil?
                #$log.info "Rovi object, hence remove all dynamic key-value pairs"
                log.info "Rovi object, hence remove all dynamic key-value pairs"
                video_obj_from_cloud.delete(:platform)
                video_obj_from_cloud.delete(:last_refreshed_timestamp)
                video_obj_from_cloud.delete(:content_expiry_timestamp)
                video_obj_from_cloud.delete(:cache_expiry_timestamp)
                video_obj_from_cloud.delete(:launch_id)
                video_obj_from_cloud.delete(:created_at)
                video_obj_from_cloud.delete(:updated_at)
                video_obj_from_cloud.delete(:refreshed_at)
                video_obj_from_cloud.delete(:with_subscription)
                video_obj_from_cloud.delete(:subscription_type)
                video_obj_from_cloud.delete(:audio_languages)
                if video_obj_from_cloud[:run_time].nil?
                  video_obj_from_cloud.delete(:run_time)
                else
                  video_obj_from_cloud[:content_runtime_s] = video_obj_from_cloud[:run_time]
                  video_obj_from_cloud.delete(:run_time)
                end
                if video_obj_from_cloud[:constraints].empty?
                  video_obj_from_cloud.delete(:constraints)
                end
                if video_obj_from_cloud[:quality].nil?
                  video_obj_from_cloud.delete(:quality)
                end
                if video_obj_from_cloud[:purchase_type] == ""
                  video_obj_from_cloud.delete(:purchase_type)
                end
                if video_obj_from_cloud[:source_id] == "hulu"
                  video_obj_from_cloud.delete(:source_program_id)
                end

                rovi_videos_list_got_from_cloud.push(video_obj_from_cloud)

              elsif video_obj_from_cloud[:fetched_from] == "gracenote"
                #$log.info "GN object, hence adding only url to array"
                log.info "GN object, hence adding only url to array"
                gn_url = video_obj_from_cloud[:link][:uri]
                gracenote_videos_list_got_from_cloud.push(gn_url)
              elsif video_obj_from_cloud[:fetched_from] == "crawler"
                #$log.info "Got from crawler, hence adding only url to array"
                log.info "Got from crawler, hence adding only url to array"
                crawler_url = video_obj_from_cloud[:link][:uri]
                crawler_videos_list_got_from_cloud.push(crawler_url)
              end

              videos_got_from_cloud = {"Rovi Videos" => rovi_videos_list_got_from_cloud,"Gracenote Videos" => gracenote_videos_list_got_from_cloud,"Crawlers" => crawler_videos_list_got_from_cloud}
    
              #$log.info "Videos got from cloud for the service #{serv_name}: #{videos_got_from_cloud}"
              log.info "Videos got from cloud for the service #{serv_name}: #{videos_got_from_cloud}"
              #videos_got_from_cloud

              #Addition of ingestion logic here
              check_for_ingestion_of_particular_service_rovi_or_gn_ott_links_in_series_episode(videos_got_from_cloud,client,ep_prog_id,serv_name,ser_name,seas_no,episode_no,episode_title,log)

            else
              #$log.info "#{ind_service_name} is not of type #{serv_name}, moving to next"
              log.info "#{ind_service_name} is not of type #{serv_name}, moving to next"
     
            end
          end
          #$log.info "END OF FOR Loop: To iterate through all #{serv_name} ott objects of a single episode"
          log.info "END OF FOR Loop: To iterate through all #{serv_name} ott objects of a single episode"
        else
          #$log.info "Inside else, empty cloud response"
          log.info "Inside else, empty cloud response"
          #episodes_without_ott_links_cnt = episodes_without_ott_links_cnt + 1
          query_rovi_and_gn_dump_and_check_for_availability_of_episode_for_a_particular_service(client,ser_name,seas_no,episode_no,episode_title,ep_prog_id,serv_name,log)
          #$arr_episode_prog_ids.push([ser_name,seas_no,episode_no,ep_prog_id,"No Video Links Available in Cloud"])
        end
      else
        #$log.info "Exiting validation as #{netflix_no_of_seasons} is less than #{seas_no}"
        log.info "Exiting validation as #{netflix_no_of_seasons} is less than #{seas_no}"
      end
 
    end
    #$log.info "END OF For loop which iterates across all episodes"
    log.info "END OF For loop which iterates across all episodes"

    if $episodes_without_ott_links_cnt > 0
      if $episodes_without_ott_links_cnt == $episodes_cnt
        $arr_prog_ids.push([series_name,"SM",prog_id,"OTT Links not available on cloud for all episodes","Not available in Rovi Dump","Not available in GN dump","FAIL"])
        #$log.info "#{$episodes_without_ott_links_cnt} episodes of Series #{ser_name} do not have #{serv_name} ott links at all."
        log.info "#{$episodes_without_ott_links_cnt} episodes of Series #{ser_name} do not have #{serv_name} ott links at all."
      else
        $arr_prog_ids.push([series_name,"SM",prog_id,"OTT Links not available on cloud for some episodes","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors","FAIL"])
        #$log.info "#{$episodes_without_ott_links_cnt} episodes of Series #{ser_name} do not have #{serv_name} ott links at all."
        log.info "#{$episodes_without_ott_links_cnt} episodes of Series #{ser_name} do not have #{serv_name} ott links for some episodes."
      end
    else
      if $rovi_ingest_failures_cnt == 0 and $gn_ingest_failures_cnt == 0
        if $rovi_ingest_success_cnt > 0 and $gn_ingest_success_cnt == 0
          $arr_prog_ids.push([series_name,"SM",prog_id,"OTT Links available on cloud for all episodes","Rovi Ingestion Status - PASS"])
          #$log.info "#{$rovi_ingest_success_cnt} out of #{$episodes_cnt} have been ingested succesfully from rovi dump,hence ingestion -PASS"
          log.info "#{$rovi_ingest_success_cnt} out of #{$episodes_cnt} have been ingested succesfully from rovi dump,hence Rovi Ingestion Status -PASS"
        elsif $gn_ingest_success_cnt > 0 and $rovi_ingest_success_cnt == 0
          $arr_prog_ids.push([series_name,"SM",prog_id,"OTT Links available on cloud for all episodes","GN Ingestion Status - PASS"])
          #$log.info "#{$gn_ingest_success_cnt} out of #{$episodes_cnt} have been ingested succesfully from gn dump,hence ingestion -PASS"
          log.info "#{$gn_ingest_success_cnt} out of #{$episodes_cnt} have been ingested succesfully from gn dump,hence GN Ingestion Status -PASS"
        else
          $arr_prog_ids.push([series_name,"SM",prog_id,"OTT Links available on cloud for all episodes","Ingestion status from both Rovi & GN - PASS"])
          #$log.info "#{$gn_ingest_success_cnt} out of #{$episodes_cnt} have been ingested succesfully from gn dump,hence ingestion -PASS"
          log.info "#{$gn_ingest_success_cnt} out of #{$episodes_cnt} have been ingested succesfully from gn dump,hence GN Ingestion Status -PASS"
        end
      else
        $arr_prog_ids.push([series_name,"SM",prog_id,"OTT Links available on cloud for all episodes,but there ingestion failures","#{$episodes_with_ott_errors_cnt} out of #{$episodes_cnt} episodes have ott errors","FAIL"])
         #$log.info "#{$rovi_ingest_failures_cnt} out of #{$episodes_cnt} have ingestion failures,hence ingestion status -FAIL"
        log.info "#{$rovi_ingest_failures_cnt} out of #{$episodes_cnt} have ingestion failures,hence ingestion status -FAIL"
        #$log.info "#{$gn_ingest_failures_cnt} out of #{$episodes_cnt} have ingestion failures,hence ingestion status -FAIL"
        log.info "#{$gn_ingest_failures_cnt} out of #{$episodes_cnt} have ingestion failures,hence ingestion status -FAIL"
      end
    end
  end

  def query_gn_dump_and_check_for_availability_of_series_for_a_particular_service(client,series_name,serv_name,netflix_year,netflix_no_of_seasons,log)
    #$log.info "API Spec Functions::query_gn_dump_and_check_for_availability_of_series_for_a_particular_service"
    log.info "API Spec Functions::query_gn_dump_and_check_for_availability_of_series_for_a_particular_service"
    series_avail_on_gn_flag = false
    dump_date = Date.today - 1
    gn_coll = client[:GN_ott_episodes_ott]
    cnt = gn_coll.count({"title" => /#{series_name}/i,"show_type" => "SM","gn_dump_date" => dump_date})
    if cnt == 0
      #$log.info "Can't find series: #{series_name} in GN dump"
      log.info "Can't find series: #{series_name} in GN dump"
      $arr_prog_ids.push([series_name,"SM",netflix_year,netflix_no_of_seasons,"Series not available on Rovi","Series not available on Gracenote","FAIL"])
      $not_avail_on_rovi_and_gn_cnt = $not_avail_on_rovi_and_gn_cnt + 1
      #$log.info "not_avail_on_rovi_and_gn_cnt: #{$not_avail_on_rovi_and_gn_cnt}"
      log.info "not_avail_on_rovi_and_gn_cnt: #{$not_avail_on_rovi_and_gn_cnt}"
    else
      #$log.info "There are #{cnt} docs returned by mongo db when querying #{series_name}, let's see more details"
      log.info "There are #{cnt} docs returned by mongo db when querying #{series_name}, let's see more details"
      gn_coll.find({"title" => /#{series_name}/i,"show_type" => "SM","gn_dump_date" => dump_date}).limit(1).each do |doc|
        gn_mongo = nil
        doc_json = doc.to_json

        parsed_doc = JSON.parse(doc_json)
        #$log.info parsed_doc
        log.info "Resp from GN dump: #{parsed_doc}"
        #array_elem.push(parsed_doc)
        gn_links_from_mongo = parsed_doc["Videos"]
        episode_title = parsed_doc["episode_title"]
        season_number = parsed_doc["season_number"]
        episode_number = parsed_doc["episode_number"]

        if !gn_links_from_mongo.empty?
          services_from_mongo = gn_links_from_mongo.keys

          #$log.info "Filter out the GN Mongo response to contain only supported services"
          log.info "Filter out the GN Mongo response to contain only supported services"
          services_from_mongo.each do |key|
            if key.downcase == serv_name or serv_name.include? key.downcase
              next
            else
              gn_links_from_mongo.delete(key)
            end
          end
          series_avail_on_gn_flag = true
          #$log.info "gn_links_from_mongo for series-#{series_name}: #{gn_links_from_mongo}"
          log.info "gn_links_from_mongo for series-#{series_name}: #{gn_links_from_mongo}"
          gn_links_from_mongo_final = gn_links_from_mongo.values
          gn_mongo = make_one_single_array(gn_links_from_mongo_final)
          #$log.info "Main: gn mongo for movie-#{series_name}: #{gn_mongo}"
          log.info "Main: gn mongo for series-#{series_name}: #{gn_mongo}"
          $arr_episode_prog_ids.push([series_name,season_number,episode_number,episode_title,"Available on GN dump but not available in cloud","Links:#{gn_mongo}"])
 
        else
          gn_mongo = []
          #$log.info "Main: GN Metadata available, but no valid gn links for program in dump"
          log.info "Main: GN Metadata available, but no valid gn links for program in dump"
          $not_avail_on_rovi_and_gn_cnt = $not_avail_on_rovi_and_gn_cnt + 1
        end
      end
      if series_avail_on_gn_flag
        $not_avail_on_rovi_but_avail_on_gn_cnt = $not_avail_on_rovi_but_avail_on_gn_cnt + 1
        #$log.info "not_avail_on_rovi_but_avail_on_gn_cnt: #{$not_avail_on_rovi_but_avail_on_gn_cnt}"
        log.info "not_avail_on_rovi_but_avail_on_gn_cnt: #{$not_avail_on_rovi_but_avail_on_gn_cnt}"
        $arr_prog_ids.push([series_name,"SM",netflix_year,netflix_no_of_seasons,"Series not available on Rovi","Series available on GN."])
      end
    end
 
  end

  def query_rovi_and_gn_dump_and_check_for_availability_of_episode_for_a_particular_service(client,ser_name,seas_no,episode_no,episode_title,ep_prog_id,serv_name,log)
    #$log.info "API spec: query_rovi_and_gn_dump_and_check_for_availability_of_episode_for_a_particular_service"
    log.info "API spec: query_rovi_and_gn_dump_and_check_for_availability_of_episode_for_a_particular_service"
    rovi_vids_mongo = get_rovi_ind_service_ott_links_from_mongo_db(client,ep_prog_id,serv_name,log)
    if !rovi_vids_mongo.nil?
      log.info "!rovi_vids_mongo.nil?"
      if rovi_vids_mongo.empty?
        log.info "rovi_vids_mongo.empty?"
        rovi_vids_mongo = nil
      end
    end
    gn_vids_mongo = query_gn_dump_for_availability_of_episode_and_return_links_if_any(client,ser_name,seas_no,episode_no,episode_title,serv_name,log)

    if rovi_vids_mongo.nil? and gn_vids_mongo.nil?
      log.info "rovi_vids_mongo.nil? and gn_vids_mongo.nil?"
      rovi_vids_mongo = get_rovi_ind_service_ott_links_from_mongo_db(client,ep_prog_id,serv_name,log)
      $episodes_without_ott_links_cnt = $episodes_without_ott_links_cnt + 1
      log.info "$episodes_without_ott_links_cnt up: #{$episodes_without_ott_links_cnt}"
      $episodes_with_ott_errors_cnt = $episodes_with_ott_errors_cnt + 1
      log.info "$episodes_with_ott_errors_cnt up: #{$episodes_with_ott_errors_cnt}"
      $arr_episode_prog_ids.push([ser_name,seas_no,episode_no,ep_prog_id,"No Video Links Available in Cloud,though metadata is available","No links available in Rovi Dump","No links available in GN Dump","FAIL"])
    elsif !rovi_vids_mongo.nil? and !gn_vids_mongo.nil?
      log.info "!rovi_vids_mongo.nil? and !gn_vids_mongo.nil?"
      $episodes_with_ott_errors_cnt = $episodes_with_ott_errors_cnt + 1
      log.info "$episodes_with_ott_errors_cnt up: #{$episodes_with_ott_errors_cnt}"
      $arr_episode_prog_ids.push([ser_name,seas_no,episode_no,ep_prog_id,"No Video Links Available in Cloud,though metadata is available","Links available in Rovi Dump","Links available in GN Dump","FAIL"])
    elsif !rovi_vids_mongo.nil?
      log.info "!rovi_vids_mongo.nil?"
      $episodes_with_ott_errors_cnt = $episodes_with_ott_errors_cnt + 1
      log.info "$episodes_with_ott_errors_cnt up: #{$episodes_with_ott_errors_cnt}"
      $rovi_ingest_failures_cnt = $rovi_ingest_failures_cnt + 1
      log.info "$rovi_ingest_failures_cnt up: #{$rovi_ingest_failures_cnt}"
      $arr_episode_prog_ids.push([ser_name,seas_no,episode_no,ep_prog_id,"No Video Links Available in Cloud,though metadata is available","Links available in Rovi Dump","FAIL"])
    elsif !gn_vids_mongo.nil?
      log.info " !gn_vids_mongo.nil?"
      $episodes_with_ott_errors_cnt = $episodes_with_ott_errors_cnt + 1
      log.info "$episodes_with_ott_errors_cnt up: #{$episodes_with_ott_errors_cnt}"
      $gn_ingest_failures_cnt = $gn_ingest_failures_cnt + 1
      log.info "$gn_ingest_failures_cnt up: #{$gn_ingest_failures_cnt}"
      $arr_episode_prog_ids.push([ser_name,seas_no,episode_no,ep_prog_id,"No Video Links Available in Cloud,though metadata is available","Links available in GN Dump","FAIL"])
    end
 
  end


  def query_gn_dump_for_availability_of_episode_and_return_links_if_any(client,series_name,season_no,episode_no,episode_title,serv_name,log)
    gn_coll = client[:GN_ott_episodes_ott]
    dump_date = Date.today - 1
    gn_vids_mongo = nil
    cnt = gn_coll.count({"title" => /#{series_name}/i,"season_number" => "#{season_no}","episode_number" => "#{episode_no}","episode_title" => "#{episode_title}","gn_dump_date" => dump_date})
    if cnt == 0
      #$log.info "Can't find #{series_name}, Se #{season_no}, Ep #{episode_no} in GN dump"
      log.info "Can't find #{series_name}, Se #{season_no}, Ep #{episode_no}, #{episode_title} in GN dump"
    else
      gn_coll.find({"title" => /#{series_name}/i,"season_number" => "#{season_no}","episode_number" => "#{episode_no}","episode_title" => "#{episode_title}","gn_dump_date" => dump_date}).limit(1).each do |doc|
        doc_json = doc.to_json
        #log.info "Value from mongo: #{doc_json} before processing"
        parsed_doc = JSON.parse(doc_json)
        #$log.info parsed_doc
        log.info "Resp from GN dump: #{parsed_doc}"
        #array_elem.push(parsed_doc)
        gn_links_from_mongo = parsed_doc["Videos"]
        if !gn_links_from_mongo.empty?
          services_from_mongo = gn_links_from_mongo.keys

          #$log.info "Filter out the GN Mongo response to contain only #{serv_name} service"
          log.info "Filter out the GN Mongo response to contain only #{serv_name} service"
          services_from_mongo.each do |key|
            if key.downcase == serv_name or serv_name.include? key.downcase
              next
            else
              gn_links_from_mongo.delete(key)
            end
          end
          #$log.info "gn_links_from_mongo for #{series_name}, Se #{season_no}, Ep #{episode_no}: #{gn_links_from_mongo}"
          log.info "gn_links_from_mongo for #{series_name}, Se #{season_no}, Ep #{episode_no}: #{gn_links_from_mongo}"
          gn_links_from_mongo_final = gn_links_from_mongo.values
          gn_vids_mongo = make_one_single_array(gn_links_from_mongo_final)
          #$log.info "Main: gn_vids_mongofor #{series_name}, Se #{season_no}, Ep #{episode_no}: #{gn_vids_mongo}"
          log.info "Main: gn_vids_mongo for #{series_name}, Se #{season_no}, Ep #{episode_no}: #{gn_vids_mongo}"
        else
          gn_vids_mongo = []
          #$log.info "Main: GN Metadata available, but no valid gn links for program in dump"
          log.info "Main: GN Metadata available, but no valid gn links for program in dump"
        end
      end
    end
    if !gn_vids_mongo.nil?
      if gn_vids_mongo.empty?
        gn_vids_mongo = nil
      end
    end
    gn_vids_mongo
  end

  def get_program_details(wl_obj)
    prog_details = {}
    prog_details["id"] = nil
    prog_name = wl_obj[:long_title]
    prog_details["name"] = prog_name
    $log.info "prog_name: #{prog_name}"
    show_type = wl_obj[:show_type]
    prog_details["show_type"] = show_type
    $log.info "show_type: #{show_type}"

    case show_type

    when "SE"
      prog_id = wl_obj[:series_id]
      prog_details["id"] = prog_id
      $log.info "Series id: #{prog_id}"
      # episode_title = wl_obj[:original_episode_title]
      # prog_details["episode_title"] = episode_title
      # $log.info "episode_title: #{episode_title}"
      season_number = wl_obj[:episode_season_number]
      prog_details["season_num"] = season_number
      $log.info "season_number: #{season_number}"
      episode_number = wl_obj[:episode_season_sequence]
      prog_details["episode_num"] = episode_number
      $log.info "episode_number: #{episode_number}"
    when "SN"
      prog_id = wl_obj[:series_id]
      prog_details["id"] = prog_id
      $log.info "Series id: #{prog_id}"
      season_number = wl_obj[:season_number]
      prog_details["season_num"] = season_number
      $log.info "season_number: #{season_number}"
      prog_details["episode_num"] = 1
      $log.info "Setting episode number to 1"
      prog_details["show_type"] = "SE"
    when "MO"
      prog_id = wl_obj[:id]
      prog_details["id"] = prog_id
      $log.info "Movie id: #{prog_id}"
      rel_year = wl_obj[:release_year]
      prog_details["rel_year"] = rel_year
      $log.info "rel_year: #{rel_year}"
    end
    $log.info "prog_details!!!: #{prog_details}"
  prog_details
  end


  def watchlist_test(serv,serv_feed)
    intent_arr = ["","play","watch","resume"]
    for i in 0..2
      iteration = i+1
      $log.info "Iteration: #{iteration}, Service: #{serv}"
      intent = intent_arr.sample
      wl_obj = serv_feed.sample
      prog_details = get_program_details(wl_obj)
      prog_name = prog_details["name"]

      api_part1 = "/voice_search?q="

      api = api_part1 + intent + "%20" + prog_name
      api_url = $base_url + api
      $current_url = api_url

      $log.info "The complete url to be tested is - #{api_url}<br>"

      #Run the get api
      get api

      # 1.Response Code Validation
      response_code_validation("get",api)
      $log.info "Completed response code validation<br>"
      $resp_code_validation_status = true

      ott_search_index = get_index_of_ott_search_object(json_body)
      $log.info "ott_search_index: #{ott_search_index}"

      # 2.Schema Validation
      program_search_schema_validation_new(api_url,json_body,ott_search_index)
      $log.info  "Completed schema validation, proceeding to complete response validation for mandatory fields<br>"
      $schema_validation_status = true

      # 3. JSON response validation
      watchlist_search_response_validation(serv,prog_details,json_body,ott_search_index)
      $log.info  "Completed response validation"
      $values_matching_validation_status = true
    end
  end

  def post_device_details(type)
    it 'posts device with details' do
      $log.info "API Specs::post_device_details"
      api = "/switches/devices"
      devices = $conf["box_devices"]
      devices_by_name = devices.keys
      devices_by_id = devices.values
      $log.info "Devices: #{devices}"
      if type == "random"
        $log.info "if :: random device to post"
        rand_dev = devices_by_name.sample
        rand_dev_id = devices[rand_dev]
        rand_port = ports.sample
        $random_device = {"port"=>rand_port, "device_id"=>rand_dev_id, "device_name"=>rand_dev}
        $log.info "if :: random device-#{rand_dev}, id-#{rand_dev_id}"
        req_body = { "port"=>rand_port, "device_id"=>rand_dev_id, "device_name"=>rand_dev, "scan_method"=>"" }
        post api, req_body
        response_code_validation("get")
      elsif type == "all"
        $log.info "elsif :: post all devices"
        ports = [0,1,2,3,4,5,6,8]
        i = 0
        devices_by_name.each do|dev|
          dev_id = devices[dev]
          port = ports[i]
          req_body = { "port"=>port, "device_id"=>dev_id, "device_name"=>dev, "scan_method"=>"" }
          $log.info "Req body to be posted is: #{req_body}"
          retry_cnt = 0
          begin
            post api, req_body
            expect_status(200)
          rescue Exception => exp_err
            $log.info "Caught exception-'#{exp_err}' while trying to post data. Going to retry"
            if retry_cnt < 3
              $log.info "Retry - #{retry_cnt}"
              retry_cnt += 1
              retry
            else
              raise "Getting nil response for api:#{api} on 3 retry attempts"
            end
          end
          i += 1
          sleep 0.5
        end
      else
        $log.info "else :: post specific device-#{type}"
        if type == "Roku"
          ports = [0,2,4,6]
          port = ports.sample
          $dev_port1 = port
        else
          ports = [1,3,5,7]
          port = ports.sample
          $dev_port2 = port
        end
        dev = type
        dev_id = devices[dev]

        $log.info "Port on which #{type} is posted: #{$dev_port}"
        req_body = { "port"=>port, "device_id"=>dev_id, "device_name"=>dev, "scan_method"=>"" }
        $log.info "Req body to be posted is: #{req_body}"
        post api, req_body
        retry_cnt = 0
        begin
          post api, req_body
          expect_status(200)
        rescue Exception => exp_err
          $log.info "Caught exception-'#{exp_err}' while trying to post data. Going to retry"
          if retry_cnt < 3
            $log.info "Retry - #{retry_cnt}"
            retry_cnt += 1
            retry
          else
            raise "Getting nil response for api:#{api} on 3 retry attempts"
          end
        end
      end
    end
  end

  def delete_all_devices_from_switch()
    it 'deletes devices associated with switch' do
      $log.info "API Specs::delete_all_devices_from_switch"
      ports = [0,1,2,3,4,5,6,7,8]
      api = "/switches/devices"
      ports.each do |port|
        $log.info "Deleting device at Port: #{port}"
        req_body = { "port"=>port, "device_id"=>"not_conn", "device_name"=>"", "scan_method"=>"" }
        retry_cnt = 0
        begin
          post api, req_body
          expect_status(200)
        rescue Exception => exp_err
          $log.info "Caught exception-'#{exp_err}' while trying to post data. Going to retry"
          if retry_cnt < 3
            $log.info "Retry - #{retry_cnt}"
            retry_cnt += 1
            retry
          else
            raise "Getting nil response for api:#{api} on 3 retry attempts"
          end
        end
      end
    end
  end

  def get_device_details(type,devs=nil)
    it 'gets device details' do
      $log.info "API Specs::get_device_details"
      api = "/switches/devices"
      devices = $conf["box_devices"]
      devices_by_name = devices.keys
      devices_by_id = devices.values
      $log.info "Devices: #{devices}"
      if type == "single"
        $log.info "if :: seeing single device was added"
        get api
        response_code_validation("get",api)
        $log.info "response - #{json_body}"
        switches_device_schema_validation()
        response_validation_switches_devices(type,devs)
      elsif type == "many"
        $log.info "elsif :: many cond - seeing the devices added"
        get api
        response_code_validation("get",api)
        $log.info "response - #{json_body}"
        switches_device_schema_validation()
        response_validation_switches_devices(type,devs)
      elsif type == "all"
        $log.info "elsif :: see if all devices were posted succesfully"
        get api
        response_code_validation("get",api)
        $log.info "response - #{json_body}"
        switches_device_schema_validation(type)
        response_validation_switches_devices(type,devs)
      elsif type == "none"
        $log.info "elsif :: see if no devices are available for box"
        get api
        response_code_validation("get",api)
        $log.info "response - #{json_body}"
        switches_device_schema_validation(type)
        response_validation_switches_devices(type,devs)
      else
        $log.info "else::see if specific device-#{type} was posted"
        get api
        response_code_validation("get",api)
        $log.info "response - #{json_body}"
        switches_device_schema_validation()
        response_validation_switches_devices(type)
      end
    end
  end 

  def get_app_details_for_devices(type,devs=nil)
    it 'gets app details of a switch based on devices connected to it' do
      $log.info "API Specs::get_app_details"
      api = "/switches/apps"
      devices = $conf["box_devices"]
      devices_by_name = devices.keys
      devices_by_id = devices.values
      $log.info "Devices: #{devices}"
      if type == "single"
        $log.info "if :: single device case:"
        dev_id = devices[devs]
        get api
        response_code_validation("get",api)
        $log.info "response - #{json_body}"
        switches_apps_schema_validation()
        response_validation_switches_apps(type,devs)
      elsif type == "many"
        $log.info "if :: many devices case"
        get api
        response_code_validation("get",api)
        $log.info "response - #{json_body}"
        switches_apps_schema_validation()
        response_validation_switches_apps(type,devs,json_body)
      elsif type == "all"
        $log.info "elsif :: see if all devices were posted succesfully"
        get api
        response_code_validation("get",api)
        $log.info "response - #{json_body}"
        switches_apps_schema_validation()
        response_validation_switches_apps(type,devs,json_body)
      else
        $log.info "else::see if specific device-#{type} is available for apps in response"
        dev = type
        dev_id = devices[dev]
        get api
        response_code_validation("get",api)
        $log.info "response - #{json_body}"
        switches_apps_schema_validation()
        response_validation_switches_apps(type)
      end
    end
  end   

  def select_apps_and_post()
    it 'Select apps and post the ids to cloud - switches/profiles/apps' do
      $log.info "API Specs :: select_apps_and_post"
      api = "/switches/profiles/apps"
      apps_selected = $conf["apps_selected_in_box"]
      req_body = { "apps"=> apps_selected}
      retry_cnt = 0
      begin
        post api, req_body
        expect_status(200)
      rescue Exception => exp_err
        $log.info "Caught exception-'#{exp_err}' while trying to post data. Going to retry"
        if retry_cnt < 3
          $log.info "Retry - #{retry_cnt}"
          retry_cnt += 1
          retry
        else
          raise "Getting nil response for api:#{api} on 3 retry attempts"
        end
      end
    end
  end

  def post_corresponding_services_and_post()
    it 'Post corresponding services to cloud - switches/profiles/profiles' do
      $log.info "API Specs :: post_corresponding_services_and_post"
      api = "/switches/profiles/services"
      services_selected = $conf["services_selected_in_box"]
      req_body = { "services" => services_selected }
      retry_cnt = 0
      begin
        post api, req_body
        expect_status(200)
      rescue Exception => exp_err
        $log.info "Caught exception-'#{exp_err}' while trying to post data. Going to retry"
        if retry_cnt < 3
          $log.info "Retry - #{retry_cnt}"
          retry_cnt += 1
          retry
        else
          raise "Getting nil response for api:#{api} on 3 retry attempts"
        end
      end
    end
  end

  def delete_switches_profiles_apps()
    it "Deletes apps from switches/profiles" do
      $log.info "API Specs :: delete_switches_profiles_apps"
      api = "/switches/profiles/apps"
      retry_cnt = 0
      begin
        delete api
        expect_status(200)
      rescue Exception => exp_err
        $log.info "Caught exception-'#{exp_err}' while trying to post data. Going to retry"
        if retry_cnt < 3
          $log.info "Retry - #{retry_cnt}"
          retry_cnt += 1
          retry
        else
          raise "Getting nil response for api:#{api} on 3 retry attempts"
        end
      end
    end
  end

  def delete_switches_profiles_services()
    it "Deletes services from switches/profiles" do
      $log.info "API Specs :: delete_switches_profiles_services"
      api = "/switches/profiles/services"
      retry_cnt = 0
      begin
        delete api
        expect_status(200)
      rescue Exception => exp_err
        $log.info "Caught exception-'#{exp_err}' while trying to post data. Going to retry"
        if retry_cnt < 3
          $log.info "Retry - #{retry_cnt}"
          retry_cnt += 1
          retry
        else
          raise "Getting nil response for api:#{api} on 3 retry attempts"
        end
      end
    end
  end

  def check_switches_profiles_updated_with_apps_and_services()
    it "Checks switches/profiles is updated" do
      $log.info "API Specs :: see_switches_profiles_updated_with_apps_and_services"
      api = "/switches/profiles"
      retry_cnt = 0
      apps_selected = $conf["apps_selected_in_box"]
      services_selected = $conf["services_selected_in_box"]
      get api
      response_code_validation("get",api)
      expect_json("apps",apps_selected)
      expect_json("services",services_selected)
    end
  end


  def arrange_ottlinks_from_cloud(json_body,log)
    log.info "Ozone Api Spec Functions::arrange_ottlinks_from_cloud"
    rovi_videos_list_got_from_cloud = Array.new
    gracenote_videos_list_got_from_cloud = Array.new
    hulu_videos_list_got_from_cloud = Array.new
    vudu_videos_list_got_from_cloud = Array.new
    crawler_videos_list_got_from_cloud = Array.new
    all_videos_list_got_from_cloud = Array.new
    videos_got_from_cloud = {"Rovi Videos"=> [],"Gracenote Videos"=> [],"Hulu Videos"=> [],"Vudu Videos"=> [],"Crawler Videos"=>[],"All Videos" => []}
    
    len = json_body.length
    if len > 0
      #$log.info "Inside if len > O"
      log.info "videos count from cloud for the episode: #{json_body.length}"
 
      for i in 0..len-1
        video_obj_from_cloud = json_body[i]
        log.info "video_obj_from_cloud:: #{video_obj_from_cloud}"
        video_obj_from_cloud.delete(:platform)
        video_obj_from_cloud.delete(:last_refreshed_timestamp)
        video_obj_from_cloud.delete(:content_expiry_timestamp)
        video_obj_from_cloud.delete(:cache_expiry_timestamp)
        video_obj_from_cloud.delete(:launch_id)
        video_obj_from_cloud.delete(:created_at)
        video_obj_from_cloud.delete(:updated_at)
        video_obj_from_cloud.delete(:refreshed_at)
        video_obj_from_cloud.delete(:with_subscription)
        video_obj_from_cloud.delete(:subscription_type)
        video_obj_from_cloud.delete(:audio_languages)
        if video_obj_from_cloud[:run_time].nil?
          video_obj_from_cloud.delete(:run_time)
        else
          video_obj_from_cloud[:content_runtime_s] = video_obj_from_cloud[:run_time]
          video_obj_from_cloud.delete(:run_time)
        end
        if video_obj_from_cloud[:constraints].nil? or video_obj_from_cloud[:constraints].empty?
          video_obj_from_cloud.delete(:constraints)
        end
        if video_obj_from_cloud[:quality].nil?
          video_obj_from_cloud.delete(:quality)
        end
        if video_obj_from_cloud[:purchase_type] == ""
          video_obj_from_cloud.delete(:purchase_type)
        end
        if video_obj_from_cloud[:source_id] == "hulu"
          video_obj_from_cloud.delete(:source_program_id)
        end

        if video_obj_from_cloud[:fetched_from].nil?
          rovi_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "gracenote"
          # gn_url = video_obj_from_cloud[:link][:uri]
          # gracenote_videos_list_got_from_cloud.push(gn_url)
          gracenote_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "hulu"
          hulu_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "vudu"
          vudu_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "crawler"
          crawler_videos_list_got_from_cloud.push(video_obj_from_cloud)
        end
        all_videos_list_got_from_cloud.push(video_obj_from_cloud)
      end
    else
      #$log.info "Inside else, empty cloud response"
      log.info "Inside else, empty cloud response"
    end

    videos_got_from_cloud = {"Rovi Videos"=> rovi_videos_list_got_from_cloud,"Gracenote Videos"=> gracenote_videos_list_got_from_cloud,"Hulu Videos"=> hulu_videos_list_got_from_cloud,"Vudu Videos"=> vudu_videos_list_got_from_cloud,"Crawler Videos"=>crawler_videos_list_got_from_cloud,"All Videos"=> all_videos_list_got_from_cloud}
     log.info "Videos got from Rovi cloud: #{rovi_videos_list_got_from_cloud}"
     log.info "Videos got from Gn cloud: #{gracenote_videos_list_got_from_cloud}"
    #$log.info "Videos got from cloud: #{videos_got_from_cloud}"
    log.info "Videos got from cloud: #{videos_got_from_cloud}"
    videos_got_from_cloud
  end


 def get_all_ottlinks_from_cloud(prog_id,log)
    log.info "Ozone Api Spec Functions::get_all_ottlinks_from_cloud"
    rovi_videos_list_got_from_cloud = Array.new
    gracenote_videos_list_got_from_cloud = Array.new
    hulu_videos_list_got_from_cloud = Array.new
    vudu_videos_list_got_from_cloud = Array.new
    crawler_videos_list_got_from_cloud = Array.new
    all_videos_list_got_from_cloud = Array.new
    videos_got_from_cloud = {"Rovi Videos"=> [],"Gracenote Videos"=> [],"Hulu Videos"=> [],"Vudu Videos"=> [],"Crawler Videos"=>[],"All Videos" => []}
    
    get "/programs/#{prog_id}/videos"
    expect_status('200')
    #$log.info json_body

    len = json_body.length
    if len > 0
      #$log.info "Inside if len > O"
      log.info "videos count from cloud for the episode: #{json_body.length}"
 
      for i in 0..len-1
        video_obj_from_cloud = json_body[i]
        log.info "video_obj_from_cloud:: #{video_obj_from_cloud}"
        video_obj_from_cloud.delete(:platform)
        video_obj_from_cloud.delete(:last_refreshed_timestamp)
        video_obj_from_cloud.delete(:content_expiry_timestamp)
        video_obj_from_cloud.delete(:cache_expiry_timestamp)
        video_obj_from_cloud.delete(:launch_id)
        video_obj_from_cloud.delete(:created_at)
        video_obj_from_cloud.delete(:updated_at)
        video_obj_from_cloud.delete(:refreshed_at)
        video_obj_from_cloud.delete(:with_subscription)
        video_obj_from_cloud.delete(:subscription_type)
        video_obj_from_cloud.delete(:audio_languages)
        if video_obj_from_cloud[:run_time].nil?
          video_obj_from_cloud.delete(:run_time)
        else
          video_obj_from_cloud[:content_runtime_s] = video_obj_from_cloud[:run_time]
          video_obj_from_cloud.delete(:run_time)
        end
        if video_obj_from_cloud[:constraints].nil? or video_obj_from_cloud[:constraints].empty?
          video_obj_from_cloud.delete(:constraints)
        end
        if video_obj_from_cloud[:quality].nil?
          video_obj_from_cloud.delete(:quality)
        end
        if video_obj_from_cloud[:purchase_type] == ""
          video_obj_from_cloud.delete(:purchase_type)
        end
        if video_obj_from_cloud[:source_id] == "hulu"
          video_obj_from_cloud.delete(:source_program_id)
        end

        if video_obj_from_cloud[:fetched_from].nil?
          rovi_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "gracenote"
          # gn_url = video_obj_from_cloud[:link][:uri]
          # gracenote_videos_list_got_from_cloud.push(gn_url)
          gracenote_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "hulu"
          hulu_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "vudu"
          vudu_videos_list_got_from_cloud.push(video_obj_from_cloud)
        elsif video_obj_from_cloud[:fetched_from] == "crawler"
          crawler_videos_list_got_from_cloud.push(video_obj_from_cloud)
        end
        all_videos_list_got_from_cloud.push(video_obj_from_cloud)
      end
    else
      #$log.info "Inside else, empty cloud response"
      log.info "Inside else, empty cloud response"
    end

    videos_got_from_cloud = {"Rovi Videos"=> rovi_videos_list_got_from_cloud,"Gracenote Videos"=> gracenote_videos_list_got_from_cloud,"Hulu Videos"=> hulu_videos_list_got_from_cloud,"Vudu Videos"=> vudu_videos_list_got_from_cloud,"Crawler Videos"=>crawler_videos_list_got_from_cloud,"All Videos"=> all_videos_list_got_from_cloud}
     log.info "Videos got from Rovi cloud: #{rovi_videos_list_got_from_cloud}"
     log.info "Videos got from Gn cloud: #{gracenote_videos_list_got_from_cloud}"
    #$log.info "Videos got from cloud: #{videos_got_from_cloud}"
    log.info "Videos got from cloud: #{videos_got_from_cloud}"
    videos_got_from_cloud
  end

 

end