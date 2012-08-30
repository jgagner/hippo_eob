
module HippoEob
	module Outputters
		class EasyPrintPDF
		  attr_accessor :eob, :pdf, :left_boundary, :line_height

			def initialize(eob)
				@eob = eob
				@pdf = Prawn::Document.new
				@left_boundary = 30
				@line_height = 12

			end

			def generate
        print_header
				print_detail_eob
				print_footer
				print_page_count
				return @pdf
			end

      def print_page_count
        string = "Page <page> of <total>"
			  top_options = { :at => [400, 635],
              			   :width => 45,
              			   :align => :left,
              			   :page_filter => (1..7),
              			   :start_count_at => 1
              				}
			   @pdf.number_pages string, top_options
      end

			def print_header
				#initial_y = @pdf.cursor
				initialmove_y = 5

				@pdf.move_down initialmove_y

			  @pdf.font_size 8
			  @pdf.text_box  @eob.payer.name, :at =>[@left_boundary, @pdf.cursor]
        @pdf.move_down @line_height + 4
        @pdf.text_box  @eob.payer.address_line_1.to_s,:at =>[@left_boundary, @pdf.cursor]
        @pdf.move_down @line_height + 4
        @pdf.text_box  @eob.payer.address_line_2.to_s, :at =>[@left_boundary, @pdf.cursor]
        @pdf.move_down @line_height + 4
        @pdf.text_box  @eob.payer.city + ', ' + @eob.payer.state + ' ' + @eob.payer.zip_code,
                       :at=>[@left_boundary, @pdf.cursor]
			  #last_measured_y = @pdf.cursor
        @pdf.move_down @line_height + 6
        @pdf.text_box @eob.payee.name, :at =>[@left_boundary, @pdf.cursor]
        @pdf.move_down @line_height + 4
        @pdf.text_box @eob.payee.address_line_1, :at =>[@left_boundary, @pdf.cursor]
        @pdf.move_down @line_height + 4
        # @pdf.text_box @eob.payee.address_line_2, :at =>[@left_boundary, @pdf.cursor]
        # @pdf.move_down @line_height + 4
       # @pdf.text_box @eob.payee.city + ', ' + @eob.payee.state + ' ' + @eob.payee.zip_code,
       #                :at=>[@left_boundary, @pdf.cursor]




			  @pdf.font_size 8
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


			def print_detail_eob
				#detail_items = 18
				@pdf.move_cursor_to 508.0
			end

    end

  end
end
