require 'gibbon'
require 'json'
require 'yaml'

config = YAML.load_file('config.yml')
MAILCHIMP_API_KEY = config[:api_key]
EMAIL_ADDRESS = config[:email_address]
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

config[:list_id] = list
File.write('config.yml', config.to_yaml)

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
		},
=begin TODO: make this work
		{
			method: "POST",
			path: "lists/#{list}/segments",
			body: {name: "Students", options: {
				conditions: [
					{condition_type: "SelectMerge", field: "ISSTUDENT", op: "is", value: "Yes"}
				]
			}}.to_json
		}
=end
	]
})
