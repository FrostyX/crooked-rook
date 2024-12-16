import gleam/erlang
import gleam/io
import gleam/list
import gleam/string
import gleam_community/ansi
import morsey
import spinner

import gleam/erlang/port.{type Port}

@external(erlang, "Elixir.Stockfish", "new_game")
pub fn new_game() -> Port

@external(erlang, "Elixir.Stockfish", "move")
pub fn move(game: Port, position: String, history: List(String)) -> Nil

@external(erlang, "Elixir.Stockfish", "best_move")
pub fn best_move(game: Port) -> String

fn ask_move() -> String {
  let prompt = "What move oponent did?: "
  case erlang.get_line(prompt) {
    Ok("\n") -> ask_move()
    Ok(move) -> string.trim(move)
    Error(_) -> panic
  }
}

fn print_morse(move: String) -> Nil {
  case morsey.encode(move) {
    Ok(symbols) -> io.println("Morse code: " <> morsey.to_string(symbols))
    Error(morsey.InvalidCharacter(_)) -> Nil
  }
}

fn with_spinner(function, text) {
  let spinner =
    spinner.new(text)
    |> spinner.with_colour(ansi.magenta)
    |> spinner.start
  let result = function()
  spinner.stop(spinner)
  result
}

fn best_move_with_spinner(game) {
  fn() { best_move(game) }
  |> with_spinner("Calculating best move")
}

fn repl(game, history) {
  let position = ask_move()
  move(game, position, history)
  let history = list.append(history, [position])

  let best = best_move_with_spinner(game)
  io.println("You should play: " <> best)
  print_morse(best)
  move(game, best, history)
  let history = list.append(history, [best])

  repl(game, history)
}

pub fn main() {
  "\u{2656} Hello from Crooked Rook!"
  |> ansi.bg_white
  |> ansi.black
  |> io.println

  io.println("Opponent is playing white")
  io.println("You are playing black")
  let game = new_game()
  repl(game, [])
}
