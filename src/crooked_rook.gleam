import gleam/erlang
import gleam/io
import gleam_community/ansi
import spinner

import gleam/erlang/port.{type Port}

@external(erlang, "Elixir.Stockfish", "new_game")
pub fn new_game() -> Port

@external(erlang, "Elixir.Stockfish", "first_move")
pub fn first_move(game: Port, position: String) -> Nil

@external(erlang, "Elixir.Stockfish", "move")
pub fn move(game: Port, position: String) -> Nil

@external(erlang, "Elixir.Stockfish", "best_move")
pub fn best_move(game: Port) -> String

fn ask_move() -> String {
  let prompt = "What move oponent did?: "
  case erlang.get_line(prompt) {
    Ok("\n") -> ask_move()
    Ok(move) -> move
    Error(_) -> panic
  }
}

pub fn main() {
  "\u{2656} Hello from Crooked Rook!"
  |> ansi.bg_white
  |> ansi.black
  |> io.println

  let spinner =
    spinner.new("Reticulating 3-Dimensional Splines")
    |> spinner.with_colour(ansi.yellow)
    |> spinner.start

  spinner.stop(spinner)
  io.println("Done!")

  io.println("Opponent is playing white")
  io.println("You are playing black")

  let game = new_game()

  let position = "e2e4"
  io.println("First move by the opponent: " <> position)
  first_move(game, position)

  let best = best_move(game)
  io.println("You should play: " <> best)
  move(game, best)

  let position = ask_move()
  move(game, position)

  let best = best_move(game)
  io.println("You should play: " <> best)
  move(game, best)
}
