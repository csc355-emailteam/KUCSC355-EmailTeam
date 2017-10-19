require 'gibbon'
require 'json'
require 'yaml'

MAILCHIMP_API_KEY = '18e43d0ddae2a324c534b86401a9cd8b-us16'
EMAIL_ADDRESS = "no-reply@lv-aitp.org"
gibbon = Gibbon::Request.new(api_key: MAILCHIMP_API_KEY)

puts "Are you sure you want to clobber the previous list?"
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

File.write('config.yml', {list_id: list}.to_yaml)

gibbon.batches.create(body: {
	operations: [
		{
			method: "POST",
			path: "lists/#{list}/merge-fields",
			body: {tag: "Student", name: "ISSTUDENT", type: "radio", required: true, options: {choices: ["Yes", "No"]}}.to_json
		},
		{
			method: "POST",
			path: "lists/#{list}/merge-fields",
			body: {tag: "Member", name: "ISMEMBER", type: "radio", required: true, options: {choices: ["Yes", "No"]}}.to_json
		},
		{
			method: "POST",
			path: "lists/#{list}/merge-fields",
			body: {tag: "Speaker", name: "ISSPEAKER", type: "radio", required: true, options: {choices: ["Yes", "No"]}}.to_json
		}
	]
})
