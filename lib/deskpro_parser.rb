require 'date'
require 'time'

class DeskproParser
  attr_reader :row

  class Collection
    attr_reader :parsed

    def initialize(file)
      deskpro_data = CSV.read(file, headers: true)

      @parsed = deskpro_data.map do |row|
        parsed = DeskproParser.new(row)
      end
    end

    def find_matches(datetime, user)
      parsed.select do |ticket|
        ticket.close_to?(datetime) && ticket.for_user?(user)
      end
    end

    def consume_nearest(datetime, user)
      matches = find_matches(datetime, user)
      if matches.any?
        matches.first.consume!(user)
      else
        raise "Can't find ticket for #{user} on #{datetime}"
      end
    end

    def totals
      t = {}
      parsed.select {|t| t.in_date_range? }.each do |ticket|
        ticket.sudos_by_user.each do |user, count|
          t[user] ||= 0
          t[user] += count
        end
      end
      t
    end
  end

  def self.parse_file(file)
    Collection.new(file)
  end

  def initialize(row)
    @row = row
    @consumed_by = {}
  end

  def sudos_by_user
    @sudos_by_user ||= calculate_sudos_by_user
  end

  def calculate_sudos_by_user
    sudos = {}
    table[1..-1].each do |row|
      user = row[4]
      counter = row[1].to_i
      sudos[user] ||= 0
      sudos[user] += counter
    end
    sudos
  rescue
    {}    
  end

  def consume!(user)
    @consumed_by[user] ||= 0
    @consumed_by[user] += 1
  end

  def consumed_by(user)
    @consumed_by.fetch(user, 0)
  end

  def table
    @table ||= table_node.css("tr").map do |row_node|
      row_node.css("td").map do |td_node|
        td_node.inner_text.strip
      end
    end
  end

  def message_html
    row.field("Message")
  end

  def table_node
    parsed_message.css("table table")[2]
  end

  def parsed_message
    Nokogiri::HTML(message_html) do |config|
      config.noblanks
    end
  end

  def datetime
    @datetime ||= DateTime.parse(row.field("Date Created"))
  end

  def close_to?(reference_time)
    interval_in_minutes = (datetime - reference_time) * 24 * 60
    interval_in_minutes < 90
  end

  def for_user?(user)
    count = sudos_by_user.fetch(user, 0)
    count - consumed_by(user) > -1  ## this allows for the possibility that a log line might be repeated, eg. log re-ingestion
  end

  def in_date_range?
    datetime > ACTUAL_START && datetime < ACTUAL_END
  end
end