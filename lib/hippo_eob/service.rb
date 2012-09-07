module HippoEob
  class Service
    attr_accessor  :service_number, :procedure_code, :date_of_service, :place_of_service,
                   :modifier_1, :modifier_2, :modifier_3, :modifier_4,
                   :charge_amount, :payment_amount, :allowed_amount, :deductible_amount, :co_insurance,
                   :adjustments, :original_units_svc_count, :units_svc_paid_count, :total_allowed_amount,
                   :remark_codes

    def initialize
      @adjustments  = []
      @remark_codes = []
    end

    def populate_hippo_object(l2110)
      @service_number    = l2110.REF_02.ReferenceIdentification
      @date_of_service   = l2110.DTM.DTM02
      @procedure_code    = l2110.SVC.ProductServiceId
      @modifier_1        = l2110.SVC.SVC01_03
      @modifier_2        = l2110.SVC.SVC01_04
      @modifier_3        = l2110.SVC.SVC01_05
      @charge_amount     = l2110.SVC.SVC02
      @payment_amount    = l2110.SVC.SVC03
      @units_svc_paid_count = l2110.SVC.SVC05
      @original_units_svc_count = l2110.SVC.SVC07
      location_number    = l2110.find_by_name('Service Identification').detect{|ref| ref.REF01 == 'LU'}
      @place_of_service  = location_number.REF02 if location_number

      l2110.CAS.each do |cas|
        [2,5,8,11,14,17].each do |index|

          adjustment          = Adjustment.new
          adjustment.type     = cas.CAS01
          adjustment.code     = cas.send(:"CAS#{index.to_s.rjust(2,'0')}")
          adjustment.amount   = cas.send(:"CAS#{(index+1).to_s.rjust(2,'0')}")

          @adjustments << adjustment if adjustment.code
        end
      end

      l2110.LQ.each do |lq|
        next if lq.LQ01 != 'HE'

        @remark_codes << lq.LQ02
      end

      @allowed_amount    = l2110.AMT.AMT02.nil? ? 0 : l2110.AMT.AMT02
      @deductible_amount = deductible_amount
      @co_insurance      = coinsurance_amount
    end

    def patient_responsibility_amount
      adjustments.find_all{|a| a.type == 'PR'}.inject(0){|memo, adj| memo += adj.amount}
    end

    def total_carc_amount
       adjustments.find_all{|a| a.code a.type != 'PR' && a.code != '23'}.inject(0) {|memo, adj| memo += adj.amount}
    end

    def deductible_amount
      adjustments.find_all{|a| a.type == 'PR' && a.code == '1'}.inject(0){|memo, adj| memo += adj.amount}
    end

    def coinsurance_amount
      adjustments.find_all{|a| a.type == 'PR' && a.code == '2'}.inject(0){|memo, adj| memo += adj.amount}
    end

    def prior_payment_amount
      adjustments.find_all{|a| a.code == '23'}.inject(0){|memo, adj| memo += adj.amount}
    end
  end
end
