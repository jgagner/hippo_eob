module HippoEob
  module Outputters
    class EasyPrintPDF
      attr_accessor :eob, :pdf, :left_boundary, :line_height, :right_boundary

      def initialize(eob)
        @eob = eob
        @pdf = Prawn::Document.new
        @left_boundary    = 30
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

        @pdf.font_size 8
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
        @pdf.table(t, :position =>@left_boundary) do
          style(row(0..-1), :borders => [], :padding => [1, 5])
        end
        @pdf.move_down @line_height
        #todo:put line in here

        @pdf.font_size 8
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

      def get_adjustments(cas)

        return '' unless cas.length > 0
        cas_string = ''
        cas.each do |c|

          cas_string += c.type + ' '  unless c.type.nil?
          cas_string += c.code + ' '  unless c.code.nil?

          cas_string += c.amount.to_f.to_s + ' ' unless c.amount.nil?

        end
        return cas_string
      end

      def get_services(svc)
        svc_info = ''
        svc.each do |s|
          svc_info += s.service_number + ' '
          svc_info += s.date_of_service.strftime("%m%d") + ' ' + s.date_of_service.strftime("%m%d%Y")
          svc_info += s.modifier_1.to_s + ' ' + s.modifier_2.to_s
          svc_info += s.procedure_code + ' '
          svc_info += get_adjustments(s.adjustments)
        end

        return svc_info
      end

      def print_detail_eob
        #detail_items = 18
        table_data = []
        @eob.claim_payments.each do |c|
          table_data << [
                            'NAME:' + c.patient_name ,
                            'HIC: ' + c.policy_number.to_s,
                            'ACNT:'   + c.patient_number.to_s,
                            'ICN:'   + c.tracking_number.to_s, 'ASG: ' ,
                            get_adjustments(c.adjustments)
                        ]

          table_data << [
                            'Service Info: ' + get_services(c.services),
                            'Payment Amt ' + c.payment_amount.to_s,
                            'Claim Status Code: ' + c.claim_status_code.to_s,
                            '',
                            ''
                        ]
         # [ '', '', '' ]
        end

        @pdf.table(table_data) do
        end
      end

    end

  end
end
