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

        if @eob.payer.telephone_number_1
          @pdf.text_box 'PAYER BUSINESS CONTACT INFORMATION:', :at =>[@left_boundary, @pdf.cursor]
          @pdf.move_down @line_height
          @pdf.text_box @eob.payer.telephone_number_1, :at =>[@left_boundary, @pdf.cursor]
          @pdf.move_down @line_height + 15
        end

        if @eob.payer.telephone_label_2 && @eob.payer.telephone_number_2
          @pdf.text_box 'PAYER TECHNICAL CONTACT INFORMATION:', :at =>[@left_boundary, @pdf.cursor]
          @pdf.move_down @line_height
          @pdf.text_box @eob.payer.telephone_label_2, :at =>[@left_boundary, @pdf.cursor]
          @pdf.move_down @line_height
          @pdf.text_box @eob.payer.telephone_number_2, :at =>[@left_boundary, @pdf.cursor]
          @pdf.move_down @line_height + 15
        end

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


        return [] unless cas.length > 0
        cas_data = []
        schar = '-'
        cas.each do |c|
          schar = cas_type == 'CLAIM' ? ':' : '-'

          add_array = (c.type == 'PR' && (c.code == '1' || c.code == '2')) ? false : true

          if add_array
            if cas_data.length > 0 and cas_data.last.include?(c.type)
              cas_data.last.replace  cas_data.last +  c.code + ' '   unless c.code.nil?
            else
              cas_data << c.type + schar  + c.code unless c.type.nil?
            end

            if cas_type == 'SERVICE'
              cas_data.last.replace cas_data.last + (' '*12) +  format_currency(c.amount.to_d) + ' ' unless c.amount.nil?
            end
          end
        end

        return cas_data

      end

      def get_services(svc, provider_npi)
        svc_info = []
        svc.each do |s|

          svc_info << [ provider_npi + '  ' + s.date_of_service.strftime("%m%d%Y") + ' ' + s.place_of_service.to_s,
                       s.procedure_code + ' ' + [s.modifier_1, s.modifier_2, s.modifier_3].compact.join(' '),
                       s.units_svc_paid_count.to_f.to_s,
                       format_currency(s.charge_amount.to_d),
                       format_currency(s.allowed_amount.to_d),
                       format_currency(s.deductible_amount),
                       format_currency(s.co_insurance),
                       format_currency(s.payment_amount.to_d)
                     ]

          get_adjustments(s.adjustments, 'SERVICE').each_with_index do |adj,index|
            svc_info << [ s.remark_codes.join(' '),'',s.original_units_svc_count.to_s.to_f,'', adj] unless index == 0
            svc_info << ['','','','', adj] unless index > 0
          end

          if s.service_number.to_s != '' then
            svc_info << ['CNTL #:' + s.service_number.to_s, '','','','','','','']
          end
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
                            'ICN:'   + c.tracking_number.to_s, 'ASG: ' + c.claim_status_code.to_s,
                            get_adjustments(c.adjustments, 'CLAIM').flatten.join( ' ' ),''
                        ]

          get_services(c.services, c.provider_npi).each do |service|
            claim_payment_data[index] <<  service
          end

          claim_payment_data[index] <<  ['','','','','','','','']
          claim_payment_data[index] <<  ['PT RESP      ' + format_currency(c.patient_reponsibility_amount), '',
                         'CLAIM TOTALS' , format_currency(c.total_submitted),
                         format_currency(c.total_allowed_amount),
                         format_currency(c.deductible_amount),
                         format_currency(c.coinsurance_amount),
                         format_currency(c.payment_amount)
                        ]
          claim_payment_data[index] <<  ['ADJ TO TOTALS:', 'PREV PD      ' + format_currency(c.prior_payment_amount),
                         'INTEREST',format_currency(c.interest_amount),
                         'LATE FILING CHARGE', format_currency(c.late_filing_amount),
                         'NET', format_currency(c.payment_amount)
                        ]

          if c.reference_identifications.length > 0
            c.reference_identifications.each do |ref|
              claim_payment_data[index] << ['','', ref.to_s]
            end
          end

          if  c.cross_over_carrier_name != '' && c.cross_over_carrier_name != nil
            claim_payment_data[index] <<  [
                          'CLAIM INFORMATON', ' FORWARDED TO: ',
                          c.cross_over_carrier_name, '','','','',''
                        ]
          end

          claim_payment_data[index] <<  ['','',c.cross_over_carrier_code,'','','']
        end
        return claim_payment_data
      end

      def claim_payment_pages
        pages = [ {:rows => [], :styles => [] } ]
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
            pages << {:rows => [], :styles => []}
          end

          pages.last[:styles] << lambda do |table|
            binding.pry
            table.style(table.row(pages.last[:rows].length).column(0..-1), :borders => [:top])
          end

          pages.last[:rows] += claim_payment

        end

        pages
      end

      def print_detail
        claim_payment_pages.each_with_index do |page_hash, index|

          if index > 0
            start_doc_new_page
          end

          @pdf.table(page_hash[:rows]) do |table|
            table.style(table.row(0..-1), :borders => [], :padding => [1, 5], :size => 6)

            page_hash[:styles].each do |style_block|
              style_block.call(table)
            end

            table.style(table.column(0), :width => 105)
            table.style(table.column(1..2), :width => 80)
            table.style(table.column(2), :align => :right)
            table.style(table.column(3), :width => 40, :align => :right)
            table.style(table.column(4), :width => 80)
            table.style(table.column(5), :width => 30, :align => :right)
            table.style(table.column(6), :width => 80)
            table.style(table.column(7), :width => 40, :align => :right)
          end
        end
      end

      def print_eob_footer

        footer = [['TOTALS:', '# OF','BILLED', 'ALLOWED', 'DEDUCT', 'COINS','TOTAL', 'PROV-PD', 'PROV', 'CHECK'],
                  ['',  'CLAIMS', 'AMT', 'AMT', 'AMT', 'AMT', 'CARC-AMT','AMT', 'ADJ-AMT', 'AMT'],
                  ['', @eob.total_claims, format_currency(@eob.total_billed),
                       format_currency(@eob.total_allowed_amount),
                       format_currency(@eob.total_deductible_amount),
                       format_currency(@eob.total_coinsurance_amount),
                       format_currency(@eob.total_carc_amount),
                       format_currency(@eob.total_payment_amount),
                       '',
                       format_currency(@eob.amount.to_d)
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

      def format_currency(input, options = {:currency_symbol => '$', :delimiter => ',', :separator => '.', :precision => 2})
        input ||= 0
        number  = "%01.#{options[:precision]}f" % input.to_d.round(options[:precision]).to_s("F")
        parts   = number.to_s.to_str.split('.')
        parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")
        options[:currency_symbol] + parts.join(options[:separator])
      end
    end
  end
end
