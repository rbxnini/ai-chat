import "@hotwired/turbo-rails"
import "controllers"

const input = document.getElementById('input')
const btn   = document.getElementById('send')
const box   = document.getElementById('chat-box')

function getConversationId() {
  return document.getElementById('conversation-id')?.value
}

function addMessage(text, type) {
  const div = document.createElement('div')
  div.classList.add('message', type)
  div.textContent = text
  box.appendChild(div)
  box.scrollTop = box.scrollHeight
  return div
}

function newConversation() {
  fetch('/new_conversation', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      'Accept': 'application/json'
    }
  })
    .then((res) => res.json())
    .then((data) => {
      if (data.id) {
        window.location.href = '/?conversation_id=' + data.id
      }
    })
}

if (input && btn && box) {

  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') btn.click()
  })

  btn.addEventListener('click', async () => {
    const text = input.value.trim()
    if (!text) return

    addMessage(text, 'user')
    input.value = ''
    btn.disabled = true
    input.disabled = true

    const thinkingMessage = addMessage('Thinking...', 'bot')

    try {
      const res = await fetch('/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          message: text,
          conversation_id: getConversationId()
        })
      })

      const data = await res.json()
      thinkingMessage.textContent = data.response

    } catch (err) {
      thinkingMessage.textContent = "Erro ao responder 😢"
      console.error(err)
    }

    btn.disabled = false
    input.disabled = false
    input.focus()
  })

  document.addEventListener('DOMContentLoaded', () => {
    box.scrollTop = box.scrollHeight
  })
}