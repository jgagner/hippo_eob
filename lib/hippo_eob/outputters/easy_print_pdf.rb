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
        print_header_eob


        print_detail_eob
        print_footer
        print_page_count
        return @pdf
      end

      def print_page_count
        string = "PAGE #: <page> of <total>"
        top_options = { :at => [@right_boundary, 572],
                       :width => 80,
                       :align => :left,
                       :page_filter => (1..7),
                       :start_count_at => 1
                      }
         @pdf.number_pages string, top_options
      end

      def print_header_eob
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
        t=[['REND-PROV','SERV-DATE','POS','PD-PROC/MODS','PD-NOS','BILLED','ALLOWED','DEDUCT','COINS','PROV-PD' ],
           ['RARC', '','','','SUB-NOS','SUB-PROC','GRP/CARC','CARC-AMT','ADJ-QTY','']
           ]
        @pdf.table(t, :position =>@left_boundary-5) do
          style(row(0..-1), :borders => [], :padding => [0, 5])
          style(column(0), :width => 50)
          style(column(1), :width => 50)
          style(column(2), :width => 30)
          style(column(3), :width => 60)
          style(column(4..-1), :width => 50)
          style(row(0..1).columns(4..5), :align => :right)
          style(row(0).columns(6..8), :align => :left)
          style(row(1).columns(6..8), :align => :right)

          style(column(-1), :width => 60, :align => :right)


        end
        @pdf.move_down @line_height-10

        #Line
        @pdf.stroke do
          @pdf.horizontal_rule
        end
        @pdf.font_size 6
      end

      def print_header_page
      end

      def print_footer
        #Any footer
      end


      def start_doc_new_page

        print_footer
        @pdf.start_new_page

        print_header
        @pdf.move_cursor_to 67
      end

      def get_adjustments(cas, cas_type)

        return '' unless cas.length > 0
        cas_string = ''
        schar = '-'
        cas.each do |c|
          if cas_type == 'CLAIM'
            schar = ':'
          end
          cas_string += c.type + schar  unless c.type.nil?
          cas_string += c.code + ' '    unless c.code.nil?

          if cas_type == 'SERVICE'
            cas_string += c.amount.to_f.to_s + ' ' unless c.amount.nil?
          end

        end
        return cas_string
      end

      def get_services(svc, provider_npi)
        svc_info = []
        svc.each do |s|

          svc_info << [ provider_npi + '  ' + s.date_of_service.strftime("%m%d") + ' ' + s.date_of_service.strftime("%m%d%Y") + ' ' + s.place_of_service,
                       s.procedure_code + ' ' + s.modifier_1.to_s + ' ' + s.modifier_2.to_s + '  ',
                       s.units_svc_paid_count.to_s.to_f ,
                       s.charge_amount.to_s.to_f,
                       s.allowed_amount.to_s.to_f,
                       s.deductible_amount.to_s.to_f,
                       s.co_insurance.to_s.to_f,
                       s.payment_amount.to_s.to_f]

          svc_info << [ '','',s.original_units_svc_count.to_s.to_f,'',
                      get_adjustments(s.adjustments, 'SERVICE'),'','','']

          svc_info << ['CNTL #:' + s.service_number, '','','','','','','']

        end

        return svc_info
      end

      def print_detail_eob
        #detail_items = 18
        table_data = []
        @eob.claim_payments.sort_by{|cp| cp.patient_name}.each do |c|
          table_data << [
                            'NAME:' + c.patient_name ,
                            'HIC: ' + c.policy_number.to_s,
                            'ACNT:'   + c.patient_number.to_s, '',
                            'ICN:'   + c.tracking_number.to_s, 'ASG: ' ,
                            get_adjustments(c.adjustments, 'CLAIM'),''
                        ]


          get_services(c.services, c.provider_npi).each do |service|
            table_data << service
          end

          table_data << ['PT RESP' + c.patient_reponsibility_amount.to_s, '',
                         'CLAIM TOTALS' , c.total_submitted.to_s.to_f,
                         '','',
                         c.patient_reponsibility_amount.to_s.to_f,
                         c.payment_amount.to_s('F')
                        ]
          table_data << ['ADJ TO TOTALS:', 'PREV PD', '',
                         'INTEREST', '',
                         'LATE FILLING CHARGE',
                         'NET', c.payment_amount.to_s('F')
                        ]
          table_data << [
                          'CLAIM INFORMATON', ' FORWARDED TO: ',
                          c.cross_over_carrier_name, '','','','',''
                        ]
          table_data << ['',c.cross_over_carrier_code, '','','','','']


         end

        @pdf.table(table_data) do
          style(row(0..-1), :borders => [], :padding => [1, 5], :size => 6)
          style(column(0), :width => 105)
          style(column(1), :width => 80)
          style(column(2), :width => 80)
          style(column(3), :width => 80)
        end
      end

    end

  end
end
