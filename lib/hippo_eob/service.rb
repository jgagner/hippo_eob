module HippoEob
  class Service
    attr_accessor  :service_number, :procedure_code, :date_of_service, :place_of_service, :modifier_1, :modifier_2, :modifier_3, :modifier_4,
                   :charge_amount, :payment_amount, :allowed_amount,  :deductible_amount,  :co_insurance_amount, :adjustments

    def initialize
      @adjustments  = []
    end

    def populate_hippo_object(l2110)
      @service_number    = l2110.REF_02.ReferenceIdentification
      @date_of_service   = l2110.DTM.DTM02
      @procedure_code    = l2110.SVC.ProductServiceId
      @modifier_1        = l2110.SVC.SVC01_03
      @modifier_2        = l2110.SVC.SVC01_04
      @charge_amount     = 0
      @payment_amount    = l2110.svc.SVC01_03
      @allowed_amount    = 0
      @deductible_amount = 0
      @co_insurance      = 0

      l2110.CAS.each do |cas|
        [2,5,8,11,14,17].each do |index|
          adjustment = Adjustment.new
          adjustment.type   = cas.CAS01
          adjustment.code   = cas.send(:"CAS#{index.to_s.rjust(2,'0')}")
          adjustment.amount = cas.send(:"CAS#{index.to_s.rjust(2,'0')+1}")

          @adjustments << adjustment
        end
      end
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
