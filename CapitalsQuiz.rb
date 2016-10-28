require 'json'
require 'csv'
require 'rest-client'
require 'levenshtein'
require 'pry'
require 'pp'

class Quiz

  # load world bank api data into array
  def load_data()
    country_count = 300
    @URL = "http://api.worldbank.org/countries/all/?format=json&per_page=#{country_count}"
    response = RestClient.get @URL
    json_response = JSON.parse(response)[1]
    country_data = []
    json_response.each do |country|
      country_data << country
    end
  end

  def load_populations()
    binding.pry
    file = File.read('populations_to_countries.json')
    data_hash = JSON.parse(file)
    #go through the list of countries, get the populationIO name, call the api, and add to an array
      population_data = []
      (1..10).each do |n|
     country = data_hash[n].fetch("populationIoName").gsub(/ /, '%20')
     iso = data_hash[n].fetch("iso2Code")
    @pop_url = "http://api.population.io:80/1.0/population/#{country}/2015-12-24/"
    begin
     response = RestClient.get @pop_url
    rescue => e
      e.response
     end
    json_response = JSON.parse(response)
    json_response.merge!("iso2Code"=> iso)
      population_data << json_response
    end

    pp population_data.zip(country_data).collect { |array| array.inject(&:merge) }

    country_info_and_stats = population_data + country_data
country_info_and_stats.group_by {|x| x[:iso2Code]}.map do |k,v|
  v.inject(:merge)
     end

  p population_data.zip(country_data).map{|h1,h2| h1["iso2Code"] == h2["iso2Code"] ? h1.merge(h2) : [h1 ,h2]}.flatten
end
  end

  def load_both_data_sets()
   load_populations()
  end

  # display question based on data
  def answer_question(data)
    binding.pry
    country = data["name"]
    capital = data["capitalCity"]
    unless capital == ""
      puts "What is the capital of #{country}?\n"
      guess = gets.chomp

      # abort program if "EXIT"
      if guess == "EXIT"
        abort("Bye!")
      end

      # handle blank answers
      if guess == ""
        puts "Incorrect! The capital of #{country} is #{capital}\n"
        return false
      end

      # allows up to 2 incorrect letters in answer
      # lower each string, and remove non-alphanumerics
			leven_distance = Levenshtein.distance(guess.downcase.gsub(/[^A-Za-z0-9\s]/i,''), capital.downcase.gsub(/[^A-Za-z0-9\s]/i,''))
      if leven_distance < 3 && leven_distance > 0
				puts "Your answer was off but we'll accept it! The capital of #{country} is #{capital}\n"
        return true
			elsif leven_distance == 0
				  puts "Correct!\n"
					return true
      else
        puts "Incorrect! The capital of #{country} is #{capital}\n"
        return false
      end
  else
    # do nothing
  end
end

  def start_quiz()
    puts "Welcome!...type EXIT to end quiz"
    questions_asked = 0
    questions_right = 0
    counter = 0
    full_data_set = load_both_data_sets()
    #country_data = load_data()
    # go forever
    while 1==1
      rand_index = rand(country_data.length-1)
      if_correct = answer_question(country_data[rand_index])
      #country_data[rand_index]
      #remove the country that was just asked
      to_delete = country_data[rand_index]
      id_to_remove = to_delete['id'.to_sym]
      country_data = country_data.delete_if { |h| h["id"] == id_to_remove }

      # controls for situations when no capital exists
      unless if_correct.nil?
        questions_asked += 1
        counter += 1
        if if_correct
          questions_right += 1
        end
        # performance tracking
        amt_right = questions_right.fdiv(questions_asked)*100
        puts "So far you have #{amt_right}% right!" if questions_asked % 5 == 0
      end
    end
  end
end

puts "Start quiz? y/n"
yn = gets.chomp
if yn == 'y' || yn == 'Y'
  Quiz.new.start_quiz
else
  abort("Bye!")
end
