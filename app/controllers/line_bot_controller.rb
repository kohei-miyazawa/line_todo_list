class LineBotController < ApplicationController
  # CSRF対策を外すために以下の記述を追記するのを忘れずに
  protect_from_forgery with: :null_session

  def callback
    # binding.pry
  end
end
