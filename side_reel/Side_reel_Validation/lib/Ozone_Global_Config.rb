require 'airborne' 
require 'yaml'
require 'json'
require 'Ozone_Automation_Common'
require 'Ozone_Response_Code_Validation_Common'
require 'Ozone_Schema_Validation_Common'
require 'Ozone_Json_Response_Data_Validation_Common'
require 'Ozone_Api_Specific_Functions'
require 'Miscellaneous_Functions'
include OzoneAutomationCommon
include OzoneSchemaValidationCommon
include OzoneJsonResponseDataValidationCommon
include OzoneApiSpecificFunctions
include OzoneResponseCodeValidationCommon
include MiscellaneousFunctions

module OzoneGlobalConfig

    #################Load the yml file which contains the basic configuration data regarding response codes & schemas for various apis########
    $conf = YAML.load_file('config/basic_configurations.yml')

    Airborne.configure do |config|

        #################Setting the environment and creating request headers. This will apply globally for all api tests.########################
        $env = ENV['ENVIRONMENT'] ? ENV['ENVIRONMENT'] : "prod"
        env_url = get_cloud_url($env)
        config.base_url = env_url
        req_headers = $conf['request_headers']
        req_headers["Host"] = env_url.gsub(/http(s)?:\/\//, '')
        #$log.info "Global Config Headers are: #{config.headers}<br>"
        ##########################################################################################################################################

        #Set authorization header by default to directv
        req_headers['Authorization'] = $conf['authorization_request_header']["directv"]
        config.headers = req_headers
        puts "OzoneGlobalConfig::Global Config Headers are: #{config.headers}<br>"

        #################Get the params value#####################################################################################################
        $params = ""
        params = ENV['PARAMS']
        #$log.info "Params for this run is:#{params}<br>"

        case params

        when "all" 
            params_arr_len = $conf['params'].length
            for i in 0..params_arr_len-1
                $params << "&" + $conf['params'][i] + "=true"
            end
            #$log.info "Params to be appended to api: #{$params}<br>"
        when "credits"
            $params = "&credit_summary=true"
        when "ott"
            $params = "&ott=true"
        end

        ##########################################################################################################################################
        #Start a global log file
        timestamp = Time.now.strftime("%d_%m_%Y_%H:%M")

        $log = Logger.new("api_automation_#{$env}_#{timestamp}.log")

        ##################Get the response codes for various Rest API methods#####################################################################
        #Get the expected response code
        $exp_resp = $conf['expected_response']
        $exp_resp_post = $conf['expected_response_post']
        $exp_resp_delete = $conf['expected_response_delete']
        $exp_resp_notmodified = $conf['expected_response_notmodified']
        $exp_resp_notfound = $conf['expected_response_notfound']

        ##################Get the schema for various json response objects and format the schema to meet airborne requirements####################

        #Format the rovi metadata schema
        schema = $conf['rovi_metadata_schema']
        $formatted_rovi_schema = format_schema_hash(schema)

        #Format the device schema
        device_schema = $conf['device_schema']
        $formatted_device_schema = format_schema_hash(device_schema)

        #Format the search schema
        search_schema = $conf['search_schema']
        $formatted_search_schema = format_schema_hash(search_schema)

        #Format the youtube schema
        youtube_schema = $conf['youtube_schema']
        $formatted_youtube_schema = format_schema_hash(youtube_schema)

        #Format the watchlist schema
        watchlist_episode_schema = $conf['watchlist_episode_schema']
        $formatted_wl_ep_schema = schema_formatting(watchlist_episode_schema)

        now_ontv_schema = $conf['now_ontv_schema']
        $formatted_now_ontv_schema = format_schema_hash(now_ontv_schema)

        #Format the headend schema
        headend_schema = $conf['headend_schema']
        $formatted_headend_schema = format_schema_hash(headend_schema)

        #Format the specific airings schema
        spec_airing_schema = $conf['specific_airings_schema']
        $formatted_spec_airing_schema = format_schema_hash(spec_airing_schema)

        #Format the dvr schema
        dvr_schema = $conf['dvr_schema']
        $formatted_dvr_schema = format_schema_hash(dvr_schema)

        #Format the sources schema
        sources_schema = $conf['sources_schema']
        $formatted_sources_schema = format_schema_hash(sources_schema)

        #Format the new search schema
        search_new_schema = $conf['search_new_schema']
        $formatted_search_new_schema = format_schema_hash(search_new_schema)

        #Format the graph db search schema
        graph_db_search_schema = $conf['graph_db_search_schema']
        $formatted_graph_db_search_schema = format_schema_hash(graph_db_search_schema)

        #Format the switches apps/devices schema
        switches_devices_apps_schema = $conf['switches_apps_schema']
        $formatted_switches_devices_apps_schema = format_schema_hash(switches_devices_apps_schema)
        
        ##################Get the mandatory fields for various json response objects and symbolise array elements#################################

        #For Rovi Programs
        mandatory_fields = $conf['program_mandatory_fields']
        $symbolised_program_mandatory_fields = symbolize_array_elements(mandatory_fields)

        #For Rovi Series Episodes(SE)
        mandatory_fields = $conf['episode_mandatory_fields']
        $symbolised_episode_mandatory_fields = symbolize_array_elements(mandatory_fields)

        #For Seasons 
        mandatory_fields = $conf['season_mandatory_fields']
        $symbolised_season_mandatory_fields = symbolize_array_elements(mandatory_fields)

        #For Videos
        mandatory_fields = $conf['video_mandatory_fields']
        $symbolised_video_mandatory_fields = symbolize_array_elements(mandatory_fields)

        #For Devices
        mandatory_fields = $conf['device_mandatory_fields']
        $symbolised_device_mandatory_fields = symbolize_array_elements(mandatory_fields)

        $base_url = env_url
        $Exceptions_Array = Array.new
        $total_count = 0
        $exception_count = 0
        $resp_code_validation_status = false
        $schema_validation_status = false
        $values_matching_validation_status = false
        $failure_string = ""
        $all_ott_services_launch_ids = {"amazon"=>[],"hbogo"=>[],"hulu"=>[],"netflix"=>[],"showtimeanytime"=>[],"showtime"=>[],"hbonow"=>[],"vudu"=>[],"youtube"=>[]}
        $tiny_url = ""
        $etag = ""
        $websetup_pin = ""
        $all_supported_services=["amazon","hbogo","hulu","netflixusa","showtimeanytime","showtime","hbonow","vudu","youtube","itunes"]
        $all_service_providers=["directv","dish","xfinity"]
        $search_api = "/voice_search?q="
        $avail_on_cloud_cnt = 0
        $avail_on_rovi_cnt = 0
        $rovi_ingest_failures_cnt = 0
        $rovi_ingest_success_cnt = 0
        $not_avail_on_rovi_and_gn_cnt = 0        
        $not_avail_on_rovi_but_avail_on_gn_cnt = 0
        $avail_on_gracenote_after_mapping_cnt = 0
        $avail_on_gracenote_and_unable_to_map_cnt = 0
        $real_gn_ingestion_cnt = 0
        $gn_ingest_failures_cnt = 0
        $gn_ingest_success_cnt = 0
        $all_watchlist_hash = {}
    end

    def reset_iteration_variables()
        $failure_string = ""
        #api_url = ""
        $resp_code_validation_status = false
        $schema_validation_status = false
        $values_matching_validation_status = false
    end

    def reset_test_variables()
        $Exceptions_Array = Array.new
        $total_count = 0
        $exception_count = 0
        $all_ott_services_launch_ids = {"amazon"=>[],"hbogo"=>[],"hulu"=>[],"netflix"=>[],"showtimeanytime"=>[],"showtime"=>[],"hbonow"=>[],"vudu"=>[],"youtube"=>[]}
        #$tiny_url = ""
        #$etag = ""
        #$websetup_pin = ""
        $avail_on_cloud_cnt = 0
        $avail_on_rovi_cnt = 0
        $rovi_ingest_failures_cnt = 0
        $rovi_ingest_success_cnt = 0
        $not_avail_on_rovi_and_gn_cnt = 0        
        $not_avail_on_rovi_but_avail_on_gn_cnt = 0
        $avail_on_gracenote_after_mapping_cnt = 0
        $avail_on_gracenote_and_unable_to_map_cnt = 0
        $real_gn_ingestion_cnt = 0
        $gn_ingest_failures_cnt = 0
        $gn_ingest_success_cnt = 0

    end

    def reinitialise_ott_array()
        $all_ott_services_launch_ids = {"amazon"=>[],"hbogo"=>[],"hulu"=>[],"netflix"=>[],"showtimeanytime"=>[],"showtime"=>[],"hbonow"=>[],"vudu"=>[],"youtube"=>[]}      
    end

    def set_auth_token_in_req_header(serv_provider)
        Airborne.configure do |config|
            config.headers['Authorization'] = $conf['authorization_request_header'][serv_provider]
            $log.info "Global Config Headers are: #{config.headers}<br>"
        end
    end
    
end