module HippoEob
  class Payment
	attr_accessor :payer, :payee, :check_number,  :date_of_check,  :trace_number, :method_type,  :amount, :claim_payments

    def self.process_hipaa_file(filename)
      contents = File.read(filename)
      process_hipaa_string(contents)
    end

    def self.process_hipaa_string(contents)
      raise ArgumentError.new, 'Not a valid HIPAA 835 file.' unless contents =~ /005010X221A1/

      transaction_sets = Hippo::Parser.new.parse_string(contents)
      transaction_sets.collect do |transaction_set|
        payment = Payment.new
        payment.process_hippo_object(transaction_set)
        payment
      end
    end

    def intialize
      @payer     = Payer.new
      @payee     = Payee.new

      @claim_payments = []
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
      @payer.telephone_1     = ts.L1000A.PER.PER03 +
                               ts.L1000A.PER.PER04

      @payee.name            = ts.L1000B.N1.N102
      @payee.contact_number  = ts.L1000B.N1.N103

      @payment.check_number  = ts.TRN.TRN02.to_s.gsub(/\A[a-zA-Z0]+/,'')
      @payment.date_of_check = ts.BPR.BPR16
      @payment.method_type   = ts.BPR.BPR04
      @payment.amount        = ts.BPR.BPR02

      ts.L2000.each do |l2000|
        l2000.L2100.each do |l2100|
          claim_payment = ClaimPayment.new
          claim_payment.process_hippo_object(l2100)
          @claim_payments << claim_payment
        end
      end
    end

    def to_pdf(outputter_klass = Outputters::ExplanationBenefitsPDF)
      outputter = outputter_klass.new(self)
      outputter.generate
    end
  end
end
