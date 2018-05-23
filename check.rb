#!/usr/bin/env ruby

require 'pp'
require 'csv'
require 'nokogiri'
require 'date'
require 'time'

$LOAD_PATH << File.dirname(__FILE__) + "/lib/"
require 'deskpro_parser'

# actuals_start: '2018-02-01T00:00:00+00Z'
# actuals_end: '2018-06-02T00:00:00+00Z'
# deskpro: all time
ACTUAL_START = DateTime.parse('2018-02-01T00:00:00+00Z').freeze
ACTUAL_END = DateTime.parse('2018-03-19T00:00:00+00Z').freeze

puts "DESKPRO"
deskpro = DeskproParser.parse_file("data/pay-support-tickets--sudo-human.csv.csv")
pp deskpro.totals

puts "ACTUALS"

error_count = 0
table = CSV.read("data/actual-sudo-human.csv", headers: true).map do |r| 
  datetime = DateTime.parse(r.field("_messagetime"))
  next unless datetime > ACTUAL_START && datetime < ACTUAL_END
  user = r.field("src_user")

  begin
    deskpro.consume_nearest(datetime, user)
  rescue => e
    puts e.message
    error_count += 1
  end
end

puts "There were #{error_count} sudo loglines which could not be accounted for by deskpro tickets between #{ACTUAL_START} and #{ACTUAL_END}"

# comparison = (deskpro.keys+actuals.keys).uniq.map do |user|
#   [user, deskpro[user], actuals[user]]
# end

# comparison.unshift(["user", "deskpro", "actual"])
# comparison.each {|r| puts r.to_csv}


# ID
# Subject
# Agent Team
# Agent Team ID
# Message
# Date Created
# Date Resolved
