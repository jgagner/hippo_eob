module HippoEob
  module Outputters
    class EasyPrintPDF
      attr_accessor :eob, :pdf, :left_boundary, :line_height, :right_boundary

      def initialize(eob)
        @eob = eob
        @pdf = Prawn::Document.new
        @left_boundary    = 10
        @line_height      = 12
        @right_boundary   = 400
      end

      def generate
        print_eob_header
        print_page_header
        print_detail
        print_eob_footer
        print_page_count
        return @pdf
      end

      def print_page_count
        string = "PAGE #: <page> of <total>"
        page_options = { :at => [@right_boundary, 500],
                       :width => 80,
                       :align => :left,
                       :page_filter => (1),
                       :start_count_at => 1
                      }
        @pdf.number_pages string, page_options

        page_options = { :at => [@right_boundary, 698],
                       :width => 80,
                       :align => :left,
                       :page_filter => (2..10),
                       :start_count_at => 2
                      }
        @pdf.number_pages string, page_options

      end

      def print_eob_header
        #initial_y = @pdf.cursor
        initialmove_y = 5

        @pdf.move_down initialmove_y

        @pdf.font_size 6
        @pdf.text_box  @eob.payer.name, :at =>[@left_boundary, @pdf.cursor]
        @pdf.text_box  @eob.payer.name, :align=>:right, :at =>[@right_boundary, @pdf.cursor]
        @pdf.move_down @line_height

        @pdf.text_box  @eob.payer.address_line_1.to_s,:at =>[@left_boundary, @pdf.cursor]
        @pdf.text_box  "REMITTANCE", :align=>:right, :at=>[@right_boundary, @pdf.cursor]
        @pdf.move_down @line_height

        @pdf.text_box  @eob.payer.address_line_2.to_s, :at =>[@left_boundary, @pdf.cursor]
        @pdf.text_box  "ADVICE", :align=>:right, :at=>[@right_boundary, @pdf.cursor]
        @pdf.move_down @line_height

        @pdf.text_box  @eob.payer.city + ', ' + @eob.payer.state + ' ' + @eob.payer.zip_code,
                       :at=>[@left_boundary, @pdf.cursor]
        @pdf.move_down @line_height + 15

        @pdf.text_box 'PAYER BUSINESS CONTACT INFORMATION:', :at =>[@left_boundary, @pdf.cursor]
        @pdf.move_down @line_height
        @pdf.text_box @eob.payer.telephone_number_1, :at =>[@left_boundary, @pdf.cursor]
        @pdf.move_down @line_height + 15
        @pdf.text_box 'PAYER TECHNICAL CONTACT INFORMATION:', :at =>[@left_boundary, @pdf.cursor]
        @pdf.move_down @line_height
        @pdf.text_box @eob.payer.telephone_label_2, :at =>[@left_boundary, @pdf.cursor]
        @pdf.move_down @line_height
        @pdf.text_box @eob.payer.telephone_number_2, :at =>[@left_boundary, @pdf.cursor]
        @pdf.move_down @line_height + 15

        @pdf.font_size 6
      end

      def print_page_header
        @pdf.text_box @eob.payee.name, :at =>[@left_boundary, @pdf.cursor]
        @pdf.text_box 'NPI #: ' + @eob.payee.contact_number, :at=>[@right_boundary, @pdf.cursor]
        @pdf.move_down @line_height
        @pdf.text_box @eob.payee.address_line_1, :at =>[@left_boundary, @pdf.cursor]
        @pdf.text_box 'DATE: '  + @eob.date_of_check.to_s, :at=>[@right_boundary, @pdf.cursor]
        @pdf.move_down @line_height

        @pdf.text_box @eob.payee.city + ', ' + @eob.payee.state + ' ' + @eob.payee.zip_code,
                      :at=>[@left_boundary, @pdf.cursor]


        @pdf.move_down @line_height + 8
        @pdf.text_box 'CHECK/EFT #:' + @eob.check_number, :at=>[@left_boundary, @pdf.cursor]


        @pdf.move_down @line_height +  3
        t=[['REND-PROV','SERV-DATE','POS','PD-PROC/MODS','PD-NOS','BILLED','ALLOWED','DEDUCT','COINS','       PROV-PD' ],
           ['RARC', '','','','SUB-NOS','SUB-PROC','GRP/CARC','CARC-AMT','ADJ-QTY','']
           ]
        @pdf.table(t, :position =>@left_boundary-5) do
          style(row(0..-1), :borders => [], :padding => [0, 5])
          style(column(0..1), :width => 60)
          style(column(4..8), :width => 60)
          style(column(5), :width => 50, :align => :center)
          style(row(0).columns(6), :width => 30, :align => :left)
          style(row(1).columns(6), :width => 50)
          style(row(0..1).columns(4), :align => :right)
          style(row(0).columns(6..8), :align => :left)
          style(row(0).column(9), :align => :right)
          style(row(1).columns(6..8), :align => :right)

        end
        @pdf.move_down @line_height-10
      end

      def start_doc_new_page
        @pdf.start_new_page
        print_page_header
        #@pdf.move_cursor_to 67
      end

      def get_adjustments(cas, cas_type)

        return '' unless cas.length > 0
        cas_string = ''
        schar = '-'
        cas.each do |c|
          schar = cas_type == 'CLAIM' ? ':' : '-'

          if c.type != 'PR'
            if cas_string.include? c.type
              c.type = ''
              schar  = ''
            end
            cas_string += c.type + schar  unless c.type.nil?
            cas_string += c.code + ' '    unless c.code.nil?

            if cas_type == 'SERVICE'
              cas_string += '             ' +  c.amount.to_f.to_s + ' ' unless c.amount.nil?
            end
          end
        end
        return cas_string
      end

      def get_services(svc, provider_npi)
        svc_info = []
        svc.each do |s|

          svc_info << [ provider_npi + '  ' + s.date_of_service.strftime("%m%d") + ' ' + s.date_of_service.strftime("%m%d%Y") + ' ' + s.place_of_service,
                       s.procedure_code + ' ' + s.modifier_1.to_s + ' ' + s.modifier_2.to_s + ' ' + s.modifier_3.to_s,
                       s.units_svc_paid_count.to_s.to_f ,
                       s.charge_amount.to_s.to_f,
                       s.allowed_amount.to_s.to_f,
                       s.deductible_amount.to_s.to_f,
                       s.co_insurance.to_s.to_f,
                       s.payment_amount.to_d.to_s('$%.2F')
                     ]

          svc_info << [ '','',s.original_units_svc_count.to_s.to_f,'',
                      get_adjustments(s.adjustments, 'SERVICE'),'','','']

          svc_info << ['CNTL #:' + s.service_number, '','','','','','','']
          svc_info << [ ' ']

        end
        return svc_info
      end



      def claim_payment_data
        claim_payment_data = Hash.new { |hash, key| hash[key] = Array.new }

        @eob.claim_payments.sort_by{|cp| cp.patient_name}.each_with_index do |c, index|
          claim_payment_data[index] << [
                            'NAME:' + c.patient_name ,
                            'HIC: ' + c.policy_number.to_s,
                            'ACNT:'   + c.patient_number.to_s, '',
                            'ICN:'   + c.tracking_number.to_s, 'ASG: ' ,
                            get_adjustments(c.adjustments, 'CLAIM'),''
                        ]

          get_services(c.services, c.provider_npi).each do |service|
            claim_payment_data[index] <<  service
          end

          claim_payment_data[index] <<  ['','','','','','','','']
          claim_payment_data[index] <<  ['PT RESP      ' + c.patient_reponsibility_amount.to_f.to_s, '',
                         'CLAIM TOTALS' , c.total_submitted.to_s.to_f,
                         c.total_allowed_amount,'',
                         c.patient_reponsibility_amount.to_d.to_f,
                         c.payment_amount.to_s('F')
                        ]
          claim_payment_data[index] <<  ['ADJ TO TOTALS:', 'PREV PD',
                         'INTEREST','',
                         'LATE FILING CHARGE', '',
                         'NET', c.payment_amount.to_s('F')
                        ]
          claim_payment_data[index] <<  [
                          'CLAIM INFORMATON', ' FORWARDED TO: ',
                          c.cross_over_carrier_name, '','','','',''
                        ]
          claim_payment_data[index] <<  ['','',c.cross_over_carrier_code,'','','']
        end
        return claim_payment_data
      end

      def claim_payment_pages
        pages = [ {:rows => [], :begin_claim_payment_index => []}  ]
        claim_payment_length = 0
        claim_payment_data.each do |claim_index, claim_payment|

          page_length   = pages.last[:rows].length
          maximum_lines = pages.length == 1 ? 50 : 75

          if claim_payment_data.length == claim_index + 1
             claim_payment_length = claim_payment.length + 8
          else
            claim_payment_length =  claim_payment.length
          end

          if page_length + claim_payment_length > maximum_lines
            pages << {:rows => [], :begin_claim_payment_index => []}
          end

          pages.last[:begin_claim_payment_index] << pages.last[:rows].length
          pages.last[:rows] += claim_payment

        end

        pages
      end

      def print_detail
        claim_payment_pages.each_with_index do |page_hash, index|

          if index > 0
            start_doc_new_page
          end

          @pdf.table(page_hash[:rows]) do
            style(row(0..-1), :borders => [], :padding => [1, 5], :size => 6)

            page_hash[:begin_claim_payment_index].each do |claim_payment_header_index|
              style(row(claim_payment_header_index), :borders => [:top])
            end

            style(column(0), :width => 105)
            style(column(1..2), :width => 80)
            style(column(2), :align => :right)
            style(column(3), :width => 40, :align => :right)
            style(column(4), :width => 80)
            style(column(5), :width => 30, :align => :right)
            style(column(6), :width => 80)
            style(column(7), :width => 40, :align => :right)
          end
        end
      end

      def print_eob_footer

        footer = [['TOTALS:', '# OF','BILLED', 'ALLOWED', 'DEDUCT', 'COINS','TOTAL', 'PROV-PD', 'PROV', 'CHECK'],
                  ['',  'CLAIMS', 'AMT', 'AMT', 'AMT', 'AMT', 'CARC-AMT','AMT', 'ADJ-AMT', 'AMT'],
                  ['', @eob.total_claims, @eob.total_billed,
                       @eob.total_allowed_amount,
                       '',
                       @eob.patient_responsibility,'',@eob.total_payment_amount,'',@eob.amount.to_f
                  ]
                 ]
        @pdf.table(footer) do
          style(row(0..-1), :borders => [], :padding => [0, 5], :align => :right)
          style(row(0), :borders => [:top])
          style(column(0..-1), :width => 50)
          style(column(4..8), :width => 50)
          style(column(-1), :width => 80)
        end
      end

    end

  end
end
