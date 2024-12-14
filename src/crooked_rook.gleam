import gleam/erlang
import gleam/io
import gleam_community/ansi
import morsey
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

  io.println("Opponent is playing white")
  io.println("You are playing black")
  let game = new_game()

  let position = "e2e4"
  io.println("First move by the opponent: " <> position)
  first_move(game, position)

  let spinner =
    spinner.new("Calculating best move")
    |> spinner.with_colour(ansi.magenta)
    |> spinner.start
  let best = best_move(game)
  spinner.stop(spinner)

  io.println("You should play: " <> best)
  move(game, best)
  case morsey.encode(best) {
    Ok(symbols) -> io.println("Morse code: " <> morsey.to_string(symbols))
    Error(morsey.InvalidCharacter(char)) ->
      io.println_error("Invalid character: " <> char)
  }

  let position = ask_move()
  move(game, position)

  let best = best_move(game)
  io.println("You should play: " <> best)
  move(game, best)
  case morsey.encode(best) {
    Ok(symbols) -> io.println("Morse code: " <> morsey.to_string(symbols))
    Error(morsey.InvalidCharacter(char)) ->
      io.println_error("Invalid character: " <> char)
  }
}
