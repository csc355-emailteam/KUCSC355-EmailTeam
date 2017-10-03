require 'sinatra'
require 'gibbon'
require 'json'

require 'mysql'
require 'active_record'

MAILCHIMP_API_KEY = '18e43d0ddae2a324c534b86401a9cd8b-us16'
EMAIL_ADDRESS = "no-reply@lv-aitp.org"
gibbon = Gibbon::Request.new(api_key: MAILCHIMP_API_KEY)

def connect_to_database
	ActiveRecord::Base.establish_connection(
		:adapter  => 'mysql2',
		:host     => 'devdbinstance.cczy5zayfult.us-east-2.rds.amazonaws.com',
		:username => 'master',
		:password => 'Goldenbears4lyfe!',
		:database => 'dbEnvironment',
		:port	  => 3306,
		:encoding => 'utf8'
	)
end

connect_to_database

class Users < ActiveRecord::Base
end

set :port, 80
set :bind, '0.0.0.0'

get '/' do # home screen
	"<pre>" + File.readlines(__FILE__).grep(/^(get|post|patch|update|delete)/).join.gsub(' do ', ' ') + "</pre>"
end

post '/sync' do
	p = params["data"]["merges"]
	if params["type"] == "unsubscribe"
		Users.find_by_email(p["EMAIL"]).delete
		return
	end

	u = Users.find_by_email(p["EMAIL"])
	if u.nil?
		u = Users.create(fName: p["FNAME"], lName: p["LNAME"], email: p["EMAIL"], membershipType: 2)
	else
		u.update(fName: p["FNAME"], lName: p["LNAME"], membershipType: 2)
	end
	u.save!
end

post '/announcement/event' do # send an event announcment
	# check whether subscriber is member to insert correct price information

	student_aitp_members_id = 0
	aitp_members_id = 0
	non_members_id = 0
	officers_id = 0

	# send email to speaker
end

post '/announcement/blast' do # send an email blast
	blast_campaign_id = 0
	body = { template: { id: template_id, sections: { "name-of-mc-edit-area": "Message content" } } }
	gibbon.campaigns(blast_campaign_id).content.upsert(body: body)
end

post '/subscribers' do # add a new subscriber (for csv imports of members)
	# TODO: look in database to determine what level member
	list_id = 0
	gibbon.lists(list_id).members.create(body: {email_address: params[:email], status: "subscribed", merge_fields: {FNAME: "First Name", LNAME: "Last Name"}})
end

patch '/subscriber/:email' do # update subscriber's membership status
end

get '/subscribers/:email' do # get subscriber by their email
end

get '/subscribers' do # dump all subscribers
end
