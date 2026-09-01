# frozen_string_literal: true

require 'websocket-client-simple'
require 'json'
require 'securerandom'

CLIENTS = 10
CHANNEL_ID = '9d66fc96-dd74-49a6-913d-917bef237414'
URL = 'ws://localhost:3000/cable'

connections = []

CLIENTS.times do |i|
  ws = WebSocket::Client::Simple.connect(
    URL,
    headers: {
      'Origin' => 'http://localhost:3000',
    },
  )

  ws.on :open do
    puts "Client #{i} connected"

    ws.send(
      JSON.generate(
        command: 'subscribe',
        identifier: JSON.generate(
          channel: 'ScoreListChannel',
          score_list_id: CHANNEL_ID,
          editable: 'false',
        ),
      ),
    )
  end

  ws.on :message do |msg|
    # puts msg.data
    puts "Client #{i} received #{msg.data.bytesize} bytes"
  end

  ws.on :error do |e|
    puts "Client #{i} ERROR: #{e}"
  end

  ws.on :close do
    puts "Client #{i} CLOSED"
  end

  connections << ws
end

puts "#{CLIENTS} connections opened. Press Ctrl+C to stop."

loop do
  sleep 1
end
