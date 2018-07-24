module OzoneResponseCodeValidationCommon

	def response_code_validation(method,api=nil)
		retry_cnt = 0
		begin
			$log.info "OzoneResponseCodeValidationCommon :: response_code_validation"

			case method

			when "get","put"
				$log.info "When get/put"
				expect_status($exp_resp)

			when "post"
				$log.info "post"
				expect_status($exp_resp_post)

			when "delete"
				$log.info "When delete"
				expect_status($exp_resp_delete)

			when "notmod"
				$log.info "When not modified"
				expect_status($exp_resp_notmodified)

			when "notfound"
				$log.info "When not modified"
				expect_status($exp_resp_notfound)

			end
			$log.info "response_code_validation >>"
		rescue Exception => exp
			if !api.nil?
		      	$log.info "response_code_validation:: exception caught,retry again"
				if retry_cnt < 3
					if response.nil?
						get api
						retry_cnt += 1
						retry
					else
						raise "Some other exception: #{exp}"
					end
				else
					raise "Getting nil response for api:#{api} on 3 retry attempts"
				end
			end
		end
	end
	
end