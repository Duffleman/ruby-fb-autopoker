require 'rubygems'
require 'mechanize'
require 'json'

email = 'george@duffleman.co.uk'
password = '********'
totalpokes = 0
puts email

file = File.open('history.json', 'r')
json_str = file.read
file.close
history = JSON.parse(json_str)

agent = Mechanize.new()
agent.user_agent_alias = "Mac Firefox"
#agent.cookie_jar.clear!
page = agent.get "http://m.facebook.com"

lf = page.forms.first
lf.field_with(:name => 'email').value = email
lf.field_with(:name => 'pass').value = password

result = lf.submit(lf.button_with(:name => 'login'))
while(result.title != 'Facebook') do
	if  result.title == 'Remember Browser'
		lf = result.forms.first
		result = lf.submit(lf.button_with(:name => 'submit[Continue]'))
		puts "Dealing with the Remember Browser Page..."
	elsif result.title == "Review Recent Login"
		lf = result.forms.first
		result = lf.submit(lf.button_with(:name => "submit[Continue]"))
		lf = result.forms.first
		result = lf.submit(lf.button_with(:name => 'submit[This is Okay]'))
		puts "Dealing with the Recent Logins Page..."
	end
end

puts "==--+ BEGIN +--=="

loop do
	puts "Scanning for Pokes: "
	result = agent.get "http://m.facebook.com/pokes"
	names = Array.new
	result.search('#root ._55wr').children().each do |a|
		name = a.search('._5hn8').text;
		names.push name
	end
	names.reject! { |n| n.empty? or !n.include? "poked" }
	names.map! do |n|
		pos = n.index "poked"
		pos = pos -2
		n[0..pos]
	end
	if names.count >= 1 
		puts "Found %i new pokes " % [names.count]
		newhistory = Array.new
		names.map do |name|
			find = history.detect{ |poke| poke['name'] == name }
			if find.nil?
				poker = { "name" => name, "pokes" => 1 }
				puts "Poking back %s for the first time." % [name]
			else
				poker = { "name" => name, "pokes" => (find['pokes'] + 1)}
				puts "Poking back %s for the %i time!" % [name, (find['pokes'] + 1)]
			end
			newhistory.push poker
		end
		history = newhistory # Dont reload from file, just override history
		## Actually do the poking
		result.links_with(:text => 'Poke back').each do |link|
			link.click
		end
		file = File.new('history.json', 'w+')
		file.write(history.to_json)
		file.close
		puts "Writing to File"
	else
		puts "No new pokes found."
	end
	puts "Sleeping for 30 seconds."
	puts "==--++--=="
	sleep(30)
end