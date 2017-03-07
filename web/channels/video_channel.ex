defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  def join("videos:" <> video_id, _params, socket) do
    {:ok, assign(socket, :video_id, String.to_integer(video_id))}
  end

  # クライアント側から なんらかの イベントが送信されてきた時
  def handle_in(event, params, socket) do
    # socket に紐づいたユーザ情報を取得する（毎回）
    user = Repo.get(Rumbl.User, socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end
  # クライアント側から new_annotation イベントが送信されてきた時
  def handle_in("new_annotation", params, user, socket) do
    # アノテーションを永続化
    changeset =
      user
      |> build_assoc(:annotations, video_id: socket.assigns.video_id)
      |> Rumbl.Annotation.changeset(params)

    case Repo.insert(changeset) do
      {:ok, annotation} ->
        broadcast! socket, "new_annotation", %{
          id: annotation.id,
          user: Rumbl.UserView.render("user.json", %{user: user}),
          body: annotation.body,
          at: annotation.at
        }
        {:reply, :ok, socket}
      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  # handle_info = OTPメッセージの受信
  # これは基本的にループ
  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1

    # サーバからクライアントにメッセージをpushしている
    push socket, "ping", %{count: count}

    # :noreply はクライントに返信しない。countをインクリメントしているだけ
    {:noreply, assign(socket, :count, count + 1)}
  end
end
