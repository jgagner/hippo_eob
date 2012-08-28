module HippoEob
  class ClaimPayment
    attr_accessor :patient_number, :insurance_number, :policy_number, :claim_number, :claim_status_code,  :charge_amount,
	                :payment_amount, :patient_reponsibility_amount,  :tracking_number, :cross_over_carrier_name,
				          :services,  :adjustments

    def initialize
		  @services    = []
		  @adjustments = []
    end

    def process_hippo_object(l2100)
      self.payment_amount               = l2100.CLP.CLP04
      self.claim_status_code            = l2100.CLP.CLP02
      self.tracking_number              = l2100.CLP.CLP07
      self.policy_number                = l2100.NM1.NM109
      self.patient_number               = l2100.CLP.CLP01
      self.patient_reponsibility_amount = l2100.CLP.CLP05

      #Claim CAS - MIA - MOA
      [5,20,21].each do |index|
        adjustment = Adjustment.new
        adjustment.type   = "MIA"
        adjustment.code   = l2100.MIA.send(:"MIA#{index.to_s.ljust(2,'0')}")
        @adjustments << adjustment if adjustment.code
      end

      [3,4,5].each do |index|
        adjustment = Adjustment.new
        adjustment.type   = "MOA"
        adjustment.code   = l2100.MOA.send(:"MOA#{index.to_s.ljust(2,'0')}")
        @adjustments << adjustment if adjustment.code
      end


      #Adjustmets on the claim
      l2100.CAS.each do |cas|
        [2,5,8,11,14,17].each do |index|
          adjustment = Adjustment.new
          adjustment.type   = cas.CAS01
          adjustment.code   = cas.send(:"CAS#{index.to_s.rjust(2,'0')}")
          adjustment.amount = cas.send(:"CAS#{index.to_s.rjust(2,'0')+1}")

          @adjustments << adjustment
        end
      end

      l2100.L2110.each do |l2110|
        service = Service.new
        service.process_hippo_object(l2110)
        @services << service
      end
    end
  end
end
