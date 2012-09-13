#! /usr/bin/env ruby
require 'bigdecimal'
require 'bigdecimal/util'
require 'fileutils'
require 'hippo'
require 'time'
require 'date'
require 'pry'
require 'pp'

require 'prawn'
#require 'prawn/flexible-table/cell'
#require 'prawn/flexible-table'
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
  payments = HippoEob::Payment.process_hipaa_file('xdoc/FLTEST2.EDI')
  payment = payments.detect{|p| p.check_number == '889636676'}
  payments = HippoEob::Payment.process_hipaa_file('xdoc/BLUE1.EDI')
  payment = payments.detect{|p| p.check_number == '201740004'}

  payments = HippoEob::Payment.process_hipaa_file('xdoc/20120911/835BLU_20120911070229.edi')
  payments = HippoEob::Payment.process_hipaa_file('xdoc/20120911/835CAR_20120911070229.edi')
  payments = HippoEob::Payment.process_hipaa_file('xdoc/20120911/835CIG_20120911070229.edi')
  payments = HippoEob::Payment.process_hipaa_file('xdoc/20120911/835HUM_20120911070229.edi')
  payments = HippoEob::Payment.process_hipaa_file('xdoc/20120911/835RRC_20120911070229.edi')

  #payment = payments.detect{|p| p.check_number =~ /1883886/}

  payment.to_pdf.render_file("output.pdf")
  `open output.pdf`

  # payments.each_with_index do |payment, i|
  #   payment.to_pdf.render_file("output_#{i}.pdf")
  # end
end
