require 'sinatra'
require 'gibbon'
require 'json'
require 'yaml'

require 'mysql'
require 'active_record'

CONFIG = YAML.load_file('config.yml')
EMAIL_ADDRESS = CONFIG[:email_address]
LIST = CONFIG[:list_id]
MAILCHIMP_API_KEY = CONFIG[:api_key]
ANNOUNCEMENT_TEMPLATE = 42153

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


get '/sync' do # dummy get endpoint to keep mailchimp happy
end

post '/sync' do # endpoint for mailchimp to post to (keeping databases in sync)
	p = params["data"]["merges"]
	if params["type"] == "unsubscribe"
		# unset opt_in flag
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

post '/announcement/schedule' do # schedule email blast
	# check whether subscriber is member to insert correct price information
	recipients = {
  		list_id: LIST,
    		segment_opts: {
        		saved_segment_id: segment_id
		}
	}
	settings = {
		subject_line: "Event announcement",
		title: "Event announcement",
		from_name: "LV AITP",
		reply_to: "noreply@lv-aitp.org"
	}

	begin
		gibbon.campaigns.create(body: {type: "regular", recipients: recipients, settings: settings})
	rescue Gibbon::MailChimpError => e
		puts "Houston, we have a problem: #{e.message} - #{e.raw_body}"
	end

	# Then send

	# send email to speaker
end

post '/announcement/blast' do # send an email blast
	recipients = {
		list_id: LIST,
	}

	begin
		req = JSON.parse(request.body.read)
	rescue
		return 400
	end

	subj = req["subject"]
	content = req["content"]

	return 400 if (subj.nil? or subj.empty?) or (content.nil? or content.empty?)

	settings = {
		subject_line: "LV AITP Announcement: #{subj}",
		title: "#{subj}",
		from_name: "LV AITP",
		reply_to: EMAIL_ADDRESS
	}

	body = {
		type: "regular",
		recipients: recipients,
		settings: settings
	}

	campaign = gibbon.campaigns.create(body: body)

	body = {
		template: {
			id: ANNOUNCEMENT_TEMPLATE,
			sections: {
				"body_content": content,
			}
		}
	}

	gibbon.campaigns(campaign.body["id"]).content.upsert(body: body)
	gibbon.campaigns(campaign.body["id"]).actions.send.create
end

post '/subscribers' do # add a new subscriber (for csv imports of members)
	# TODO: look in database to determine what level member
	list_id = 0
	gibbon.lists(list_id).members.create(body: {email_address: params[:email], status: "subscribed", merge_fields: {FNAME: "First Name", LNAME: "Last Name"}})
end

patch '/subscriber/:email' do # update subscriber's membership status
end
