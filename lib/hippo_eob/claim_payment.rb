module HippoEob
  class ClaimPayment
    attr_accessor :patient_number, :insurance_number, :policy_number, :claim_number, :claim_status_code,  :charge_amount,
                  :payment_amount, :patient_reponsibility_amount,  :tracking_number, :cross_over_carrier_name,
                  :cross_over_carrier_code,
                  :services,  :adjustments, :patient_name, :provider_npi, :rendering_provider_information, :total_submitted,
                  :interest_amount, :late_filing_amount, :claim_identifiers, :provider_identifiers,
                  :hippo_object

    def initialize
      @services             = []
      @adjustments          = []
      @claim_identifiers    = []
      @provider_identifiers = []
    end

    def process_hippo_object(l2100)
      @hippo_object = l2100

      self.payment_amount                   = l2100.CLP.CLP04
      self.claim_status_code                = l2100.CLP.CLP02
      self.tracking_number                  = l2100.CLP.CLP07
      self.patient_name                     = l2100.NM1.NM103 + ', ' + l2100.NM1.NM104
      self.policy_number                    = l2100.NM1.NM109
      self.patient_number                   = l2100.CLP.CLP01
      self.patient_reponsibility_amount     = l2100.CLP.CLP05
      self.provider_npi                     = l2100.find_by_name('Service Provider Name').NM109
      self.rendering_provider_information   = l2100.find_by_name('Rendering Provider Identification').REF02
      self.cross_over_carrier_name          = l2100.find_by_name('Crossover Carrier Name').NM103
      self.cross_over_carrier_code          = l2100.find_by_name('Crossover Carrier Name').NM109
      self.total_submitted                  = l2100.CLP.CLP03
      self.interest_amount                  = l2100.AMT.find_all{|amt| amt.AMT01 == 'I'}.inject(0.0.to_d) { |mem, amt| mem + amt.AMT02 }
      self.late_filing_amount               = l2100.AMT.find_all{|amt| amt.AMT01 == 'D8'}.inject(0.0.to_d) { |mem, amt| mem + amt.AMT02 }

      if nm1 = l2100.find_by_name('Corrected Patient/Insured Name')
        self.policy_number = nm1.NM109 unless nm1.NM109.nil?
        self.patient_name  = nm1.NM103.to_s + ', ' + nm1.NM104.to_s if [:NM103,:NM104].all?{|sym| nm1.send(sym)}
      end

      #Claim CAS - MIA - MOA
      [5,20,21].each do |index|

        adjustment          = Adjustment.new
        adjustment.type     = "MIA"
        adjustment.code     = l2100.MIA.send(:"MIA#{index.to_s.rjust(2,'0')}")

        if code_list = Hippo::CodeLists::RemittanceAdviceRemarkCodes[adjustment.code]
          adjustment.description = code_list[:description]
        end

        @adjustments << adjustment if adjustment.code
      end

      [3,4,5].each do |index|
        adjustment          = Adjustment.new
        adjustment.type     = "MOA"
        adjustment.code     = l2100.MOA.send(:"MOA#{index.to_s.rjust(2,'0')}")
        adjustment.amount   = l2100.MOA.send(:"MOA#{(index+1).to_s.rjust(2,'0')}")

        if code_list = Hippo::CodeLists::RemittanceAdviceRemarkCodes[adjustment.code]
          adjustment.description = code_list[:description]
        end

        @adjustments << adjustment if adjustment.code
      end

      #Adjustments on the claim
      l2100.CAS.each do |cas|
        [2,5,8,11,14,17].each do |index|

          adjustment        = Adjustment.new
          adjustment.type   = cas.CAS01
          adjustment.code   = cas.send(:"CAS#{index.to_s.rjust(2,'0')}")
          adjustment.amount = cas.send(:"CAS#{(index+1).to_s.rjust(2,'0')}")

          if code_list = Hippo::CodeLists::ClaimAdjustmentReasonCodes[adjustment.code]
            adjustment.description = code_list[:description]
          end

          @adjustments << adjustment
        end
      end

      l2100.find_by_name('Other Claim Related Identification').each do |ref|
        @claim_identifiers << "(#{ref.REF01}) #{ref.REF02}" if ref.REF02.to_s.length > 0
      end

      l2100.find_by_name('Rendering Provider Identification').each do |ref|
        @provider_identifiers << "(#{ref.REF01}) #{ref.REF02}" if ref.REF02.to_s.length > 0
      end

      l2100.L2110.each do |l2110|
        service = Service.new
        service.populate_hippo_object(l2110)
        @services << service
      end

      self
    end

    def deductible_amount
      if services.length > 0
        services.inject(0.to_d){|memo, service| memo += service.deductible_amount || 0}
      else
        adjustments.find_all{|a| a.type == 'PR' && a.code == '2'}.inject(0){|memo, adj| memo += adj.amount}
      end
    end

    def coinsurance_amount
      if services.length > 0
        services.inject(0.to_d){|memo, service| memo += service.coinsurance_amount || 0}
      else
        adjustments.find_all{|a| a.type == 'PR' && a.code == '1'}.inject(0){|memo, adj| memo += adj.amount}
      end
    end

    def prior_payment_amount
      if services.length > 0
        services.inject(0.to_d){|memo, service| memo += service.prior_payment_amount || 0}
      else
        adjustments.find_all{|a| a.code == '23'}.inject(0){|memo, adj| memo += adj.amount}
      end
    end

    def total_carc_amount
      if services.length > 0
        @services.inject(0){|memo, svc| memo += svc.total_carc_amount}
      else
        @adjustments.find_all{|a| ['CO','CR','OA','PI', 'PR'].include?(a.type)}.inject(BigDecimal.new('0')) {|memo, adj| memo += (adj.amount || 0)}
      end
    end

    def total_allowed_amount
      allowed_amount = 0
      @services.each do |svc|
        allowed_amount += svc.allowed_amount.to_f
      end

      return allowed_amount.to_d.to_f
    end

    def code_glossary
      output = {}

      adjustments.each do |adjustment|
        output[adjustment.code] = adjustment.description
      end

      services.each do |service|
        output.merge!(service.code_glossary)
      end

      output
    end
  end
end
