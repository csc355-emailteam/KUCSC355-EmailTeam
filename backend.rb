require 'sinatra'
require 'gibbon'
require 'json'
require 'yaml'

require 'mysql'
require 'active_record'

# TODO: do conversion from est -> utc

CONFIG = YAML.load_file('config.yml')
EMAIL_ADDRESS = CONFIG[:email_address]
LIST = CONFIG[:list_id]
MAILCHIMP_API_KEY = CONFIG[:api_key]
ANNOUNCEMENT_TEMPLATE = CONFIG[:email_template_id]

gibbon = Gibbon::Request.new(api_key: MAILCHIMP_API_KEY)

def any_empty?(arr)
	arr.map{|e| e.nil? or e.empty?}.any?
end

def parse_blast_request(body, parse_date = false)
	begin
		req = JSON.parse(body)
	rescue
		return "Malformed post body JSON", nil, nil, nil
	end

	a = []
	a << req["subject"]
	a << req["content"]
	a << req["date"] if parse_date

	return "Need subject, content #{", date" if parse_date} fields in request", nil, nil, nil if any_empty? a

	a << nil

	return nil, a[0], a[1], a[2]
end

def generate_campaign(gibbon, subj, content, segment=nil)
	settings = {
		subject_line: "LV AITP Announcement: #{subj}",
		title: "#{subj}",
		from_name: "LV AITP",
		reply_to: EMAIL_ADDRESS
	}

	r = {list_id: LIST}
	unless segment.nil?
		r[:segment_opts] = {saved_segment_id: segment}
	end

	body = {
		type: "regular",
		recipients: r,
		settings: settings
	}

	campaign = gibbon.campaigns.create(body: body)
	campaign_id = campaign.body["id"]

	body = {
		template: {
			id: ANNOUNCEMENT_TEMPLATE,
			sections: {
				"body_content": content,
			}
		}
	}

	gibbon.campaigns(campaign_id).content.upsert(body: body)
	campaign_id
end

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

set :port, CONFIG[:port]
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
	err, subj, content, date = parse_blast_request(request.body.read, true)
	error 400, err if err != nil

	campaign_id = generate_campaign(gibbon, subj, content)
	gibbon.campaigns(campaign_id).actions.schedule.create(body: {schedule_time: date})
end

post '/announcement/blast' do # send an email blast
	err, subj, content, date = parse_blast_request(request.body.read)
	error 400, err if err != nil

	campaign_id = generate_campaign(gibbon, subj, content)
	gibbon.campaigns(campaign_id).actions.send.create
end

post '/subscribers' do # add a new subscriber (for csv imports of members)
	b = JSON.parse(request.body.read)
	error 400, "Need email, fname and lname" if any_empty?([b['email'], b['fname'], b['lname']])
	gibbon.lists(LIST).members.create(body: {email_address: b['email'], status: "subscribed", merge_fields: {FNAME: b['fname'], LNAME: b['lname']}})
end

VALID_SEGMENTS = CONFIG.keys.grep(/segment/).map{|s| s.to_s.split("_").first}
patch '/subscriber/:list/:email' do # update subscriber's membership status
	error 400, "Illegal list #{params[:list]} - should be one of #{VALID_SEGMENTS}" unless VALID_SEGMENTS.include?(params[:list])
	gibbon.lists(LIST).segments(CONFIG[(params[:list] + "_segment").to_sym]).create(body: {members_to_add: [params[:email]]})
end
