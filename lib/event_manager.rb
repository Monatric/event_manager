require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(homephone)
  if homephone.length < 10
    homephone = "BAD NUMBER"
  elsif homephone.length == 11 && homephone[0] == "1"
    homephone.slice!(0)
    homephone
  elsif homephone.length == 11 && homephone[0] != "1"
    homephone = "BAD NUMBER"
  elsif homephone.length > 11
    homephone = "BAD NUMBER"
  else
    homephone
  end
end

def count_hour(hour)
  if HOUR_COUNTER.key?(hour)
    HOUR_COUNTER[hour] += 1
  else
    HOUR_COUNTER[hour] = 1
  end
end

def find_peak_hours(hour_counter)
  #get the max value or hours with most appearances
  max = hour_counter.values.max
  peak_hours = Hash[hour_counter.select { |k, v| v == max}]
  peak_hours.keys
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
HOUR_COUNTER = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  homephone = clean_phone_number(row[:homephone].delete("^0-9"))
  hour = DateTime.strptime(row[:regdate], '%m/%d/%Y %H:%M').hour
  count_hour(hour)
  
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)

  puts "#{name} #{zipcode} #{homephone}"
end

peak_hours = find_peak_hours(HOUR_COUNTER)

puts "The peak hours are #{peak_hours}"