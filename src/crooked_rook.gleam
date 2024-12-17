import gleam/erlang
import gleam/erlang/port.{type Port}
import gleam/io
import gleam/list
import gleam/string
import gleam_community/ansi
import morsey
import spinner

const icon = "\u{2656}"

type Player {
  Friend
  Opponent
}

type History =
  List(String)

type Game {
  Game(port: Port, history: History, white: Player)
}

@external(erlang, "Elixir.Stockfish", "new_game")
fn new_game() -> Port

@external(erlang, "Elixir.Stockfish", "move")
fn move(game: Port, position: String, history: List(String)) -> Nil

@external(erlang, "Elixir.Stockfish", "best_move")
fn best_move(game: Port) -> String

@external(erlang, "Elixir.Owl.IO", "select")
fn ask_color(choices: List(String)) -> String

fn ask_move(prompt) -> String {
  case erlang.get_line(prompt) {
    Ok("\n") -> ask_move(prompt)
    Ok(move) -> string.trim(move)
    Error(_) -> panic
  }
}

fn print_morse(move: String) -> Nil {
  case morsey.encode(move) {
    Ok(symbols) ->
      symbols
      |> morsey.to_string
      |> ansi.blue
      |> string.append("  ")
      |> io.println

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

fn play_user(game: Game) -> Game {
  let best = best_move_with_spinner(game.port)
  let color = case game.white {
    Friend -> ansi.white
    Opponent -> ansi.gray
  }

  icon
  |> color
  |> string.append(" You should play: ")
  |> string.append(ansi.magenta(best))
  |> io.println

  print_morse(best)
  io.println("")
  move(game.port, best, game.history)
  Game(..game, history: list.append(game.history, [best]))
}

fn play_opponent(game: Game) -> Game {
  let color = case game.white {
    Opponent -> ansi.white
    Friend -> ansi.gray
  }

  let position =
    icon
    |> color
    |> string.append(" What move your opponent did?: ")
    |> ask_move

  move(game.port, position, game.history)
  Game(..game, history: list.append(game.history, [position]))
}

fn repl(game: Game) {
  case game.white {
    Friend -> {
      game
      |> play_user
      |> play_opponent
      |> repl
    }
    Opponent -> {
      game
      |> play_opponent
      |> play_user
      |> repl
    }
  }
}

pub fn main() {
  io.println("What pieces are you playing?")
  let white = case ask_color(["White", "Black"]) {
    "White" -> Friend
    _ -> Opponent
  }

  icon
  |> ansi.white
  |> string.append({
    case white {
      Friend -> " You are playing white"
      Opponent -> " Your opponent is playing white"
    }
  })
  |> io.println

  icon
  |> ansi.gray
  |> string.append({
    case white {
      Opponent -> " You are playing black\n"
      Friend -> " Your opponent is playing black\n"
    }
  })
  |> io.println

  let game = Game(new_game(), [], white)
  repl(game)
}
