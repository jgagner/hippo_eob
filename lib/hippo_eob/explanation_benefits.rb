module HippoEob
  class ExplanationBenefits
    attr_accessor :payer, :payee, :payment, :glossary

    def initialize()
      @payer     = Payer.new
      @payee     = Payee.new
      @payment   = Payment.new
      @glosary   = Glossary.new
    end


    def file_hippo_valid?(file_contents)
      return file_contents =~ /005010X221A1/
    end

    def parse_hippo_object(file_name)
      file_contents = File.read(file)
      parse_string(file_contents)
    end
    #####
    def parse_string(file_contents)
      if file_hippo_valid?(file_contents)
        begin
          transaction_sets = Hippo::Parser.new.parse_string(file_contents)
          transaction_sets.each do |ts|
          begin
            @payer.name            = ts.L1000A.N1.N102 || ''
            @payer.contact_number  = ''
  					@payer.address_line_1  = ts.L1000A.N3.N301
  					@payer.address_line_2  = ts.L1000A.N3.N302
  					@payer.city            = ts.L1000A.N4.N401
  					@payer.state           = ts.L1000A.N4.N402
  					@payer.zip_code        = ts.L1000A.N4.N403
  					@payer.zip_code_4      = ts.L1000A.N4.N404
  					@payer.telephone_1     = ts.L1000A.PER.PER03 +
              											 ts.L1000A.PER.PER04

  					@payee.name            = ts.L1000B.N1.N102
  					@payee.contact_number  = ts.L1000B.N1.N103

  					@payment.check_number  = ts.TRN.TRN02.to_s.gsub(/\A[a-zA-Z0]+/,'')
  					@payment.date_of_check = ts.BPR.BPR16
  					@payment.method_type   = ts.BPR.BPR04
  					@payment.amount        = ts.BPR.BPR02

  					#Claim payments 1:m array
					  ts.L2000.each do |l2000|

              l2000.L2100.each do |l2100|
                claimpayment = ClaimPayment.new
                claimpayment.parse(l2100)

                claimpayment.payment_amount    = l2100.CLP.CLP04
                claimpayment.claim_status_code = l2100.CLP.CLP02
                claimpayment.tracking_number   = l2100.CLP.CLP07
                claimpayment.policy_number     = l2100.NM1.NM109
                claimpayment.patient_number    = l2100.CLP.CLP01
                claimpayment.patient_reponsibility_amount = l2100.CLP.CLP05 unless l2100.CLP.CLP05.nil?

                #Claim CAS - MIA - MOA
                [5,20,21].each do |index|
                  adjustment = Adjustment.new
                  adjustment.type   = "MIA"
                  adjustment.code   = l2100.MIA.MIA#{index}
                end

                [3,4,5].each do |index|
                  adjustment = Adjustment.new
                  adjustment.type   = "MOA"
                  adjustment.code   = l2100.MOA.MOA#{index}
                end


                #Adjustmets on the claim
                l2100.CAS.each do |ocas|
                  [2,5,8,11,14,17].each do |index|
                    adjustment.adjustments << set_adjustments(cas, index)
                  end
                end

                if l2100.L2110.count > 0 then
                  #Service Level
                  l2100.L2110.each do |l2110|
                    svc = Service.new
                	  svc.service_number  = l2110.REF_02.ReferenceIdentification
                    svc.date_of_service = l2110.DTM.DTM02
                    svc.procedure_code  = l2110.SVC.ProductServiceId
                    svc.modifier_1      = l2110.SVC.SVC01_03
                    svc.modifier_2      = l2110.SVC.SVC01_04
                    svc.charge_amount   = 0
                    svc.payment_amount  = l2110.svc.SVC01_03
                    svc.allowed_amount  = 0
                    svc.deductible_amount = 0
                    svc.co_insurance      = 0

                    l2110.CAS.each do |cas|
                      [2,5,8,11,14,17].each do |index|
                        svc.adjustments << set_adjustments(cas, index)
                      end
                    end

                    claimpayment.services << svc
                  end
                end
						  end
						  @payment.claim_payments << claimpayment
  					end

          end
        end
      end
    end
    #####
    def set_adjustments (cas, index)
      adjustment = Adjustment.new
      adjustment.type   = cas.CAS01
      adjustment.code   = "cas.CAS#{index}".to_sym
      adjustment.amount = "cas.CAS#{index}+1".to_sym
      return adjustment
    end

    def populate_objects
    end


    def to_pdf(outputter_klass = Outputters::ExplanationBenefitsPDF)
      outputter = outputter_klass.new(self)
      outputter.generate
    end

  end
end
