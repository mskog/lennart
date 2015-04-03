require 'net/http'
require 'json'
require 'aws-sdk'
require 'dotenv'

Dotenv.load if File.exists?('.env')

AWS_ID = ENV['AWS_ID']
AWS_SECRET = ENV['AWS_SECRET']
AWS_REGION = ENV['AWS_REGION']
AWS_SQS_QUEUE_URL = ENV['AWS_SQS_QUEUE_URL']
SUBREDDIT = ENV['SUBREDDIT']
SLEEP_TIME = ENV['SLEEP_TIME'].to_i
DATA_KEYS = ['domain', 'selftext', 'id', 'author', 'over_18', 'thumbnail', 'subreddit_id' ,'permalink', 'name' ,'created_utc' ,'url', 'title']

credentials = Aws::Credentials.new(AWS_ID, AWS_SECRET)
sqs = Aws::SQS::Client.new(region: AWS_REGION, credentials: credentials)

last_item_id = ''

while true do
  uri = URI("http://www.reddit.com/r/#{SUBREDDIT}/new.json")
  params = {limit: 100, before: last_item_id}
  uri.query = URI.encode_www_form(params)

  res = Net::HTTP.get_response(uri)

  if res.is_a?(Net::HTTPSuccess)
    data = JSON.parse(res.body)

    unless data['data']['children'].empty?
      last_item_id = data['data']['children'].first['data']['name']

      entries = data['data']['children'].map do |item|
        item_data = item['data']
        wanted_item_data = item_data.keep_if{|key, value| DATA_KEYS.include?(key)}
        {message_body: wanted_item_data.to_json, id: wanted_item_data['id']}
      end

      puts entries.count

      entries.each_slice(10) do |payload|
        sqs.send_message_batch queue_url: AWS_SQS_QUEUE_URL, entries: payload
      end
    end
  end

  sleep SLEEP_TIME
end