module HippoEob
  class ClaimPayment
    attr_accessor  :patient_number, :insurance_number, :policy_number, :claim_number, :claim_status_code,  :charge_amount,
	               :payment_amount, :patient_reponsibility_amount,  :tracking_number, :cross_over_carrier_name,  
				   :services,  :adjustments
				   
    def initialize
		@services    = []
		@adjustments = []
    end	
				   
  end 
end