require 'gibbon'
require 'json'
require 'yaml'

config = YAML.load_file('config.yml')
MAILCHIMP_API_KEY = config[:api_key]
EMAIL_ADDRESS = config[:email_address]
gibbon = Gibbon::Request.new(api_key: MAILCHIMP_API_KEY)

puts "Are you sure you want to clobber the previous MailChimp configuration?"
abort "bailing" if gets.chomp![0] != "y"

r = gibbon.lists.create(body: {
	name: "Users", 
	contact: {company: "Kutztown", address1: "", address2: "", city: "Kutztown", state: "PA", zip: "18049", country: "US"},
	permission_reminder: "You signed up for the AITP mailing list",
	campaign_defaults: {
		from_name: "LV AITP",
		from_email: "no-reply@lv-aitp.org",
		subject: "LV AITP Announcement",
		language: "English"
	},
	email_type_option: true
})
list = r.body["id"]

config[:list_id] = list
config[:students_segment] = gibbon.lists(list).segments.create(body: {name: "Students", static_segment: []}).body["id"]
config[:members_segment] = gibbon.lists(list).segments.create(body: {name: "Members",  static_segment: []}).body["id"]
config[:speakers_segment] = gibbon.lists(list).segments.create(body: {name: "Speakers", static_segment: []}).body["id"]

File.write('config.yml', config.to_yaml)
