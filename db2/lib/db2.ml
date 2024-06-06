module DbCaml = struct
  module Connection : sig
    type t

    val make : unit -> t
  end = struct
    type t = unit

    let make () = ()
  end

  module Driver = struct
    module type Intf = sig
      type config

      val connect : config -> Connection.t
    end
  end
end

module FakeDB = struct
  type config = { port : int }

  let connect _config = DbCaml.Connection.make ()
end

module Silo = struct
  type 'config t = {
    driver : (module DbCaml.Driver.Intf with type config = 'config);
    config : 'config;
  }

  let connect ~driver ~config = { driver; config }
end

module MyApp = struct
  let run () =
    let db = Silo.connect ~driver:(module FakeDB) ~config:{ port = 2112 } in
    ()
end
