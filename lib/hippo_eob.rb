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
require_relative "hippo_eob/adjustments"

require_relative "hippo_eob/outputters/general_eob_pdf"

module HippoEob; end

if __FILE__ == $0
  eob = Eob::Eob.new

  
  stat.to_pdf.render_file('output.pdf')
  #`evince output.pdf &`
end