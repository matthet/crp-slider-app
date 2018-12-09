require "google/cloud/firestore"
require 'simple_stats'
require 'terminal-table'
require 'csv'

firestore = Google::Cloud::Firestore.new(project_id: 'crp-slider-app')

donations = firestore.col "donations"
slider_donations = donations.get.select { |donation| donation.data[:page_type] == 'slider' }
checkmark_donations = donations.get.select { |donation| donation.data[:page_type] == 'checkmarks' }
# slider_donations.each { |donation| puts donation.data }
# checkmark_donations.each { |donation| puts donation.data }

class Stat
  attr_accessor :rows, :data, :raw_data

  def initialize
    @rows = [table_header]
    @raw_data = []
  end

  def add(data)
    rows << [
      data.first[:page_type],
      data.length,
      data.mean { |d| d[:amount] },
      data.median { |d| d[:amount] },
      data.sum { |d| d[:amount] },
    ]
    data.each do |d|
      raw_data << d
    end
    # raw_data += data
  end

  def show_table
    puts Terminal::Table.new(:rows => rows)
  end

  def save_csv
    CSV.open("crp-slider-app.csv", "wb") do |csv|
      csv << csv_header
      raw_data.each do |d|
        csv << [d[:page_type], d[:amount], d[:timestamp]]
      end
    end
    puts "CSV file saved at crp-slider-app.csv"
  end

  def csv_header
    ['page_type', 'amount', 'timestamp']
  end

  def table_header
    ['Type', '# of samples', 'Mean', 'Median', 'Total']
  end
end

stat = Stat.new
stat.add(slider_donations)
stat.add(checkmark_donations)

stat.show_table
stat.save_csv
