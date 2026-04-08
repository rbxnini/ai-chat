class HomeController < ApplicationController
  def index
    @messages = Message.all
  end

  def chat
    message = params[:message]
    Message.create(role: "user", content: message)
    response = OllamaService.chat(message)
    Message.create(role: "bot", content: response)
    render json: { response: response }
  end
end
