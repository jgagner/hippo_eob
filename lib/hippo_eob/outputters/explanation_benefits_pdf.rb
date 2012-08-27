require 'prawn'
module HippoEob
	module Outputters
		class ExplantionBenefitsPDF
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
				#Add the page count
			string = "Page <page> of <total>"
			top_options = { :at => [30, 635],
			:width => 35,
			:align => :left,
			:page_filter => (1..7),
			:start_count_at => 1
				}
			@pdf.number_pages string, top_options
       
			end
     
			def print_header
				initial_y = @pdf.cursor
				initialmove_y = 5

				@pdf.move_down initialmove_y

			  @pdf.font_size 16
			  @pdf.text_box  @eob.variable_here, :at =>[@left_boundary, @pdf.cursor]
			  last_measured_y = @pdf.cursor
			  @pdf.move_down @line_height + 4

			  @pdf.font_size 8		
			end

			def print_footer
            	
			end


			def start_doc_new_page

				print_footer
				@pdf.start_new_page

				print_header
				print_addresses
				
				@pdf.move_cursor_to ???
			end


			def print_details
				detail_items = 18
				@pdf.move_cursor_to 508.0        
			end
   		end
	end
end