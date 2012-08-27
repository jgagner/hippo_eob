module HippoEob
  class Payment
	attr_accessor :check_number,  :date_of_check,  :trace_number, :method_type,  :amount, :claim_payments
	
    def intialize
		claim_payments = []
    end	
  end
end