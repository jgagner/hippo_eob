module HippoEob
  class Payment
	attr_accessor :payer, :payee, :check_number,  :date_of_check,  :trace_number, :method_type,  :amount, :claim_payments,
                :payment_totals

    def self.process_hipaa_file(filename)

      contents = File.read(filename)
      process_hipaa_string(contents)
    end

    def self.process_hipaa_string(contents)
      raise ArgumentError.new, 'Not a valid HIPAA 835 file.' unless contents =~ /005010X221A1/

      transaction_sets = Hippo::Parser.new.parse_string(contents)

      transaction_sets.collect do |transaction_set|
        payment = self.new
        payment.process_hippo_object(transaction_set)
        payment
      end
    end

    def initialize
      @payer     = HippoEob::Payer.new
      @payee     = HippoEob::Payee.new
      @claim_payments = []
      @payment_totals = [ {:number_claims => 0, :total_billed => 0 , :total_payment => 0, :patient_resp => 0 , :allowed => 0} ]
    end

    def process_hippo_object(ts)
      @payer.name            = ts.L1000A.N1.N102 || ''
      @payer.contact_number  = ''
      @payer.address_line_1  = ts.L1000A.N3.N301
      @payer.address_line_2  = ts.L1000A.N3.N302
      @payer.city            = ts.L1000A.N4.N401
      @payer.state           = ts.L1000A.N4.N402
      @payer.zip_code        = ts.L1000A.N4.N403
      @payer.zip_code_4      = ts.L1000A.N4.N404
      @payer.telephone_number_1     = ts.L1000A.PER.PER04
      @payer.telephone_number_2     = ts.L1000A.PER_02.PER04

      @payer.telephone_label_2 = ts.L1000A.PER_02.PER02
      @payee.name            = ts.L1000B.N1.N102
      @payee.contact_number  = ts.L1000B.N1.N104
      @payee.address_line_1  = ts.L1000B.N3.N301
      @payee.address_line_2  = ts.L1000B.N3.N302
      @payee.city            = ts.L1000B.N4.N401
      @payee.state           = ts.L1000B.N4.N402
      @payee.zip_code        = ts.L1000B.N4.N403
      @payee.zip_code_4      = ts.L1000B.N4.N404

      @check_number  = ts.TRN.TRN02.to_s.gsub(/\A[a-zA-Z0]+/,'')
      @date_of_check = ts.BPR.BPR16
      @method_type   = ts.BPR.BPR04
      @amount        = ts.BPR.BPR02

      ts.L2000.each do |l2000|
        l2000.L2100.each do |l2100|
          claim_payment = ClaimPayment.new
          claim_payment.process_hippo_object(l2100)
          @claim_payments << claim_payment

          @payment_totals.last[:total_billed] += claim_payment.total_submitted.to_f
          @payment_totals.last[:total_payment] += claim_payment.payment_amount.to_f
          @payment_totals.last[:patient_resp] += claim_payment.patient_reponsibility_amount.to_f unless claim_payment.patient_reponsibility_amount.nil?
          #deduct amt
          #total carc_amt
          #prov pd
          #prov adj

          claim_payments.last.services.each do |svc|
            @payment_totals.last[:allowed] += svc.allowed_amount.to_f unless svc.allowed_amount.nil?
          end

        end

        @payment_totals.last[:number_claims] += @claim_payments.length

      end
    end

    def to_pdf(outputter_klass = Outputters::EasyPrintPDF)
      outputter = outputter_klass.new(self)

      outputter.generate
    end
  end
end
