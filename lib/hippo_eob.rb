require 'bigdecimal'
require 'bigdecimal/util'
require 'fileutils'
require 'hippo'
require 'time'
require 'date'
require 'pry'
require 'pp'

require 'prawn'
require 'prawn/flexible-table/cell'
require 'prawn/flexible-table'
require 'prawn/errors'

require_relative "hippo_eob/version"
require_relative "hippo_eob/contact_base"
require_relative "hippo_eob/payer"
require_relative "hippo_eob/payee"
require_relative "hippo_eob/claim_payment"
require_relative "hippo_eob/service"
require_relative "hippo_eob/payment"
require_relative "hippo_eob/adjustment"

require_relative "hippo_eob/outputters/easy_print_pdf"

module HippoEob; end

if __FILE__ == $0
  payments = HippoEob::Payment.process_hipaa_file('some/path/here.era')
  payments.each_with_index do |payment|
    payment.to_pdf.render_file("output_#{i}.pdf")
    #`open output.pdf`
  end
end
