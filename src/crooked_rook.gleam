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

fn play_user(game, history, player_white) {
  let best = best_move_with_spinner(game)
  let color = case player_white {
    True -> ansi.white
    False -> ansi.gray
  }

  icon
  |> color
  |> string.append(" You should play: ")
  |> string.append(ansi.magenta(best))
  |> io.println

  print_morse(best)
  io.println("")
  move(game, best, history)
  list.append(history, [best])
}

fn play_opponent(game, history, player_white) {
  let color = case player_white {
    True -> ansi.gray
    False -> ansi.white
  }

  let position =
    icon
    |> color
    |> string.append(" What move your opponent did?: ")
    |> ask_move

  move(game, position, history)
  list.append(history, [position])
}

fn repl(game, history, player_white: Bool) {
  case player_white {
    True -> {
      history
      |> play_user(game, _, player_white)
      |> play_opponent(game, _, player_white)
      |> repl(game, _, player_white)
    }
    False -> {
      history
      |> play_opponent(game, _, player_white)
      |> play_user(game, _, player_white)
      |> repl(game, _, player_white)
    }
  }
}

pub fn main() {
  let player_white = False

  icon
  |> ansi.white
  |> string.append({
    case player_white {
      True -> " You are playing white"
      False -> " Your opponent is playing white"
    }
  })
  |> io.println

  icon
  |> ansi.gray
  |> string.append({
    case player_white {
      False -> " You are playing black\n"
      True -> " Your opponent is playing black\n"
    }
  })
  |> io.println

  let game = new_game()
  repl(game, [], player_white)
}
