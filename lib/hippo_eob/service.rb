module HippoEob
  class Service 
	attr_accessor  :service_number, :procedure_code, :date_of_service, :place_of_service, :modifier_1, :modifier_2, :modifier_3, :modifier_4, 
	               :charge_amount, :payment_amount, :allowed_amount,  :deductible_amount,  :co_insurance_amount
	
	def initialize
		@adjustments  = []
	end
	
	def allowed_amount
		return @allowed_amount
	end
	
	def deductible_amount
		return @deductible_amount
	end
	
	def coinsurance_amount
		return @coinsurance_amount
	end	
  end	
end