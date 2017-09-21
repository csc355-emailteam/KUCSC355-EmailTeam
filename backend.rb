require 'sinatra'
require 'gibbon'
require 'json'
require 'active_record'

MAILCHIMP_API_KEY = '18e43d0ddae2a324c534b86401a9cd8b-us16'
EMAIL_ADDRESS = "no-reply@lv-aitp.org"
gibbon = Gibbon::Request.new(api_key: MAILCHIMP_API_KEY)

set :port, 80
set :bind, '0.0.0.0'

get '/' do # home screen
	"<pre>" + File.readlines(__FILE__).grep(/^(get|post|patch|update|delete)/).join + "</pre>"
end

post '/announcement' do # send an announcement
	gibbon.lists(list_id).members.create(body: {email_address: EMAIL_ADDRESS, status: "subscribed", merge_fields: {FNAME: "First Name", LNAME: "Last Name"}})
end

post '/subscribers' do # add a new subscriber
end

get '/subscribers/:email' do # get subscriber by their email
end

delete '/subscribers/:email' do # delete a subscriber by their email
end

get '/subscribers' do # dump all subscribers
end
