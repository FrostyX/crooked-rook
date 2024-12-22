import bummer
import gleam/erlang
import gleam/erlang/atom
import gleam/erlang/port.{type Port}
import gleam/erlang/process.{sleep}
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

fn scan_with_spinner(socket: bummer.Connection, miliseconds: Int) {
  fn() { bummer.scan(socket, miliseconds) }
  |> with_spinner("Connecting to a vibrating device")
}

fn vibrate(socket: bummer.Connection, morse: List(morsey.Char)) -> Nil {
  // International Morse Code
  // 1. The length of a dot is one unit.
  // 2. A dash is three units.
  // 3. The space between parts of the same letter is one unit.
  // 4. The space between letters is three units.
  // 5. The space between words is seven units.
  let interval = 200
  case morse {
    [] -> Nil
    [first, ..rest] -> {
      case first {
        morsey.Dot -> bummer.vibrate(socket, interval)
        morsey.Comma -> bummer.vibrate(socket, interval * 3)
        morsey.Space -> sleep(interval * 3)
        morsey.Break -> sleep(interval * 7)
        morsey.Invalid(_) -> Nil
      }
      vibrate(socket, rest)
    }
  }
}

fn play_user(game: Game, socket: bummer.Connection) -> Game {
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
  case morsey.encode(best) {
    Ok(symbols) -> vibrate(socket, symbols)
    Error(morsey.InvalidCharacter(_)) -> Nil
  }

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

fn repl(game: Game, socket: bummer.Connection) {
  case game.white {
    Friend -> {
      game
      |> play_user(socket)
      |> play_opponent
      |> repl(socket)
    }
    Opponent -> {
      game
      |> play_opponent
      |> play_user(socket)
      |> repl(socket)
    }
  }
}

pub fn main() {
  bummer.set_log_level(atom.create_from_string("info"))
  case bummer.connect("ws://127.0.0.1:12345/") {
    Ok(socket) -> {
      scan_with_spinner(socket, 5000)

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
      repl(game, socket)
    }
    Error(_) ->
      "Cannot connect to intiface-engine websocket. Is it running?"
      |> io.println_error
  }
}
