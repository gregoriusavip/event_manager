# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_numbers(phone_numbers)
  phone_number_digits = phone_numbers.gsub(/\D/, '')
  phone_number_digits[0] = '' if phone_number_digits.length.eql?(11) && phone_number_digits[0].eql?('1')
  phone_number_digits.length.eql?(10) ? phone_number_digits : nil
end

def find_hour(reg_dates)
  hours_freq = reg_dates.each_with_object(Hash.new(0)) do |date, hours|
    hours[Time.strptime(date, '%m/%d/%y %H:%M').strftime('%I%p')] += 1
  end
  hours_freq.max_by { |_, v| v }[0]
end

def legislators_by_zipcode(zip) # rubocop:disable Metrics/MethodLength
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

# contents.each do |row|
#  p "Name: #{row[:first_name]}, Phone Number: #{clean_phone_numbers(row[:homephone])}"
# end

p "Peak registration hours: #{find_hour(contents.read[:regdate])}"

# template_letter = File.read('form_letter.erb')
# erb_template = ERB.new template_letter
#
# contents.each do |row|
#   id = row[0]
#   name = row[:first_name]
#   zipcode = clean_zipcode(row[:zipcode])
#   legislators = legislators_by_zipcode(zipcode)
#
#   form_letter = erb_template.result(binding)
#
#   save_thank_you_letter(id, form_letter)
# end
