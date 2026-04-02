class HomeController < ApplicationController
  def index
  end

  def chat
    message = params[:message]
    response = OllamaService.chat(message)
    render json: { response: response }
  end
end