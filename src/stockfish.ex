defmodule Stockfish do
  def receive_all do
    receive do
      {_, {:data, msg}} ->
        lines = String.split(msg, "\n")
        Enum.concat(lines, receive_all())
    after
      1000 -> [""]
    end
  end

  def new_game do
    port = Port.open({:spawn, "stockfish"}, [:binary])
    Port.command(port, "uci\n")
    Port.command(port, "isready\n")
    Port.command(port, "ucinewgame\n")
    port
  end

  def move(game, position) do
    Port.command(game, "position moves #{position}\n")
  end

  def first_move(game, position) do
    Port.command(game, "position startpos moves #{position}\n")
  end

  def best_move(game) do
    Port.command(game, "go depth 15\n")

    line =
      receive_all()
      |> Enum.filter(fn x -> x != "" end)
      |> Enum.take(-1)
      |> List.first()

    case line do
      "bestmove " <> rest -> rest |> String.split() |> List.first()
      _ -> IO.puts("ERROR unexpected response from stockfish")
    end
  end
end
