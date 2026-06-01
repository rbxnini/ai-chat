class HomeController < ApplicationController
  def index
    @conversations = Conversation.order(updated_at: :desc)
    @current_conversation = Conversation.find_by(id: params[:conversation_id]) || Conversation.last || Conversation.create(title: "Chat 1")
    @messages = @current_conversation.messages.order(:created_at)
  end

  def new_conversation
    conversation = Conversation.create(title: "Chat #{Conversation.count + 1}")

    respond_to do |format|
      format.html { redirect_to root_path(conversation_id: conversation.id) }
      format.json { render json: { id: conversation.id } }
    end
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
