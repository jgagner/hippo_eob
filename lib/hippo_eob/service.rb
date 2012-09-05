module HippoEob
  class Service
    attr_accessor  :service_number, :procedure_code, :date_of_service, :place_of_service,
                   :modifier_1, :modifier_2, :modifier_3, :modifier_4,
                   :charge_amount, :payment_amount, :allowed_amount, :deductible_amount, :co_insurance,
                   :adjustments, :original_units_svc_count, :units_svc_paid_count, :total_allowed_amount

    def initialize
      @adjustments  = []
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

          adjustment = Adjustment.new
          adjustment.type   = cas.CAS01
          adjustment.code   = cas.send(:"CAS#{index.to_s.rjust(2,'0')}")
          adjustment.amount = cas.send(:"CAS#{(index+1).to_s.rjust(2,'0')}")

          @adjustments << adjustment if adjustment.code
        end
      end

      @allowed_amount    = l2110.AMT.AMT02.nil? ? 0 : l2110.AMT.AMT02
      @deductible_amount = deductible_amount
      @co_insurance      = coinsurance_amount
    end

    def patient_responsibility_amount
      adj = adjustments.detect{|a| a.type == 'PR'}
      adj.amount if adj
    end

    def deductible_amount
      adj = adjustments.detect{|a| a.type == 'PR' && a.code == '1'}
      adj.amount if adj
    end

    def coinsurance_amount
      adj = adjustments.detect{|a| a.type == 'PR' && a.code == '2'}
      adj.amount if adj
    end

  end
end
