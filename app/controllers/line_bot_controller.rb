class LineBotController < ApplicationController
  require "line/bot"

  protect_from_forgery with: :null_session

  def callback
    # LINEで送られてきたメッセージのデータを取得
    body = request.body.read

    # LINE以外からリクエストが来た場合 Error を返す
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      head :bad_request and return
    end

    # LINEで送られてきたメッセージを適切な形式に変形
    events = client.parse_events_from(body)

    events.each do |event|
      user_id = event["source"]["userId"]
      user = User.find_by(uid: user_id) || User.create(uid: user_id)

      user = User.find_by(uid: "share") if user.uid = ENV["UID_PAPA"] || ENV["UID_MAMA"]
      # LINE からテキストが送信された場合
      if (event.type === Line::Bot::Event::MessageType::Text)
        message = event["message"]["text"]

        text =
          case message
          when "ぜんぶ"
            tasks = user.tasks
            list(tasks)
          when "おわり"
            user.tasks.destroy_all
            destroy_all_message
          when /削除[\s|　]*\d+/
            index = message.gsub(/削除[\s|　]*/, "").strip.to_i
            tasks = user.tasks.to_a
            if task = tasks.find.with_index(1) { |_task, _index| index == _index }
              task.destroy
              task_count = user.tasks.count
              delete_message(task, index, task_count)
            else
              "#{index}番の商品が見つからなかったよ。"
            end
          else
            user.tasks.create!(body: message)
            task_count = user.tasks.count
            create_message(message, task_count)
          end

        reply_message = {
          type: "text",
          text: text
        }
        client.reply_message(event["replyToken"], reply_message)
      end
    end

    # LINE の webhook API との連携をするために status code 200 を返す
    render json: { status: :ok }
  end

  private

    def client
      @client ||= Line::Bot::Client.new do |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      end
    end

    def list(items)
      title =
        if items.count.zero?
          "いま登録されているお買物リストはないよ！"
        else
          "お買物リストの一覧だよ！\n買い忘れのないようにね！\n\n"
        end
      title + items.map.with_index(1) { |item, index| "#{index}: #{item.body}" }.join("\n")
    end

    def delete_message(item, index, count)
      count_message =
        if count.zero?
          "残りのお買い物リストはないよ！帰ってご飯にしよー！"
        else
          "残りのお買物リストは#{count}個だよ。頑張ろー！"
        end
      "お買物リスト #{index}: 「#{item.body}」 を削除したよ！\n" + count_message
    end

    def create_message(message, count)
      "お買い物リスト: 「#{message}」 を登録したよ！\nいま登録されている商品は#{count}個だよ！"
    end

    def destroy_all_message
      "お買物リストをぜんぶ削除したよ。早く帰ってご飯にしよー！"
    end
end
