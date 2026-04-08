require 'net/http'
require 'json'

class OllamaService
  def self.chat(message)
    uri = URI('http://localhost:11434/api/chat')

    body = {
      model: 'gemma3:1b',
      messages: [{ role: 'user', content: message }],
      stream: true
    }

    res = Net::HTTP.post(uri, body.to_json, 'Content-Type' => 'application/json')
    JSON.parse(res.body).dig('message', 'content')
  end
end