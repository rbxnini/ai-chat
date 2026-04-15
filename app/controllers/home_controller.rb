class HomeController < ApplicationController
  def index
    @conversations = Conversation.all
    @current_conversation = Conversation.find_by(id: params[:conversation_id]) || Conversation.last
    @messages = @current_conversation&.messages || []
  end

  def new_conversation
    conversation = Conversation.create(title: "Chat #{Conversation.count + 1}")
    redirect_to root_path(conversation_id: conversation.id)
  end

  def chat
    message = params[:message]
    conversation_id = params[:conversation_id]

    conversation = Conversation.find_by(id: conversation_id)

    # 🔥 garante que SEMPRE exista uma conversa
    if conversation.nil?
      conversation = Conversation.create(title: message.truncate(30))
    end

    # salva mensagem do usuário
    Message.create(role: "user", content: message, conversation: conversation)

    # histórico
    messages = conversation.messages.order(:created_at).map do |msg|
      {
        role: msg.role == "bot" ? "assistant" : "user",
        content: msg.content
      }
    end

    # chama IA
    response = OllamaService.chat(messages)

    # salva resposta
    Message.create(role: "bot", content: response, conversation: conversation)

    render json: { response: response }
  end
end
