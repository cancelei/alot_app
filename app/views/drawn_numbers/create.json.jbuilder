if @drawn_number.persisted?
  json.success true
  json.drawn_number do
    json.id @drawn_number.id
    json.number @drawn_number.number
    json.created_at @drawn_number.created_at
    json.cost @drawn_number.lottery.cost_per_number
  end
  json.bet do
    json.id @drawn_number.bet.id
    json.amount @drawn_number.bet.amount
  end
else
  json.success false
  json.errors @drawn_number.errors.full_messages
end
