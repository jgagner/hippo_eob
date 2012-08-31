module HippoEob
  class ContactBase
	attr_accessor :name,  :contact_number,  :address_line_1,   :address_line_2,  :city, :state,
                :zip_code, :zip_code_4, :telephone_number_1, :telephone_label_1,
                :telephone_number_2, :telephone_label_2, :email_address
  end
end
