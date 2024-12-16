import gleam/erlang
import gleam/erlang/port.{type Port}
import gleam/io
import gleam/list
import gleam/string
import gleam_community/ansi
import morsey
import spinner

@external(erlang, "Elixir.Stockfish", "new_game")
pub fn new_game() -> Port

@external(erlang, "Elixir.Stockfish", "move")
pub fn move(game: Port, position: String, history: List(String)) -> Nil

@external(erlang, "Elixir.Stockfish", "best_move")
pub fn best_move(game: Port) -> String

const icon = "\u{2656}"

fn ask_move(prompt) -> String {
  case erlang.get_line(prompt) {
    Ok("\n") -> ask_move(prompt)
    Ok(move) -> string.trim(move)
    Error(_) -> panic
  }
}

fn print_morse(move: String) -> Nil {
  case morsey.encode(move) {
    Ok(symbols) -> io.println("  " <> morsey.to_string(symbols))
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
  let prompt =
    icon
    |> ansi.white
    |> string.append(" What move oponent did?: ")

  let position = ask_move(prompt)
  move(game, position, history)
  let history = list.append(history, [position])

  let best = best_move_with_spinner(game)
  icon
  |> ansi.gray
  |> string.append(" You should play: ")
  |> string.append(ansi.magenta(best))
  |> io.println

  print_morse(best)
  io.println("")
  move(game, best, history)
  let history = list.append(history, [best])

  repl(game, history)
}

pub fn main() {
  icon
  |> ansi.white
  |> string.append(" Opponent is playing white")
  |> io.println

  icon
  |> ansi.gray
  |> string.append(" You are playing black\n")
  |> io.println

  let game = new_game()
  repl(game, [])
}
