module DbCaml = struct
  module Connection = struct
    type t = { socket : unit }

    let make () = { socket = () }
    let execute _t query = Format.sprintf "query: %s; result: hello world" query
  end

  module Driver = struct
    module type Intf = sig
      type config

      val connect : config -> Connection.t

      val deserialize :
        'state 'value.
        ('value, 'state) Serde.De.t -> string -> ('value, Serde.error) result
    end

    type 'config t = (module Intf with type config = 'config)

    let connect (type config) (module D : Intf with type config = config) config
        =
      D.connect config

    let deserialize (type config) (module D : Intf with type config = config)
        raw de_fn =
      D.deserialize raw de_fn
  end

  module Pool = struct
    type t =
      | Pool : {
          driver : 'config Driver.t;
          config : 'config;
          connections : Connection.t list;
        }
          -> t

    let make ?(max_connections = 10) ~driver ~config () =
      let connections =
        List.init max_connections (fun _id -> Driver.connect driver config)
      in

      Pool { driver; config; connections }

    let check_out_connection (Pool pool) =
      (* use some logic to figure out what connection to check out *)
      List.hd pool.connections

    let query (Pool pool as t) query de =
      let connection = check_out_connection t in
      let bytes = Connection.execute connection query in
      Driver.deserialize pool.driver de bytes
  end
end

module FakeDB = struct
  type config = { port : int }

  let connect _config = DbCaml.Connection.make ()

  module Deserializer = Serde_json.Deserializer

  type state = Deserializer.state

  let deserialize de raw =
    let state =
      Deserializer.
        { reader = Serde_json.Json.Parser.of_string raw; kind = First }
    in
    Serde.deserialize (module Deserializer) state de
end

module Silo = struct
  type t = { pool : DbCaml.Pool.t }

  let connect ~pool = { pool }
  let query t query = DbCaml.Pool.query t.pool query
end

module MyApp = struct
  let run () =
    (* create a pool of connections for a specific database with some config *)
    let pool =
      DbCaml.Pool.make ~driver:(module FakeDB) ~config:{ port = 2112 } ()
    in
    (* wrap the pool in an instance of Silo *)
    let db = Silo.connect ~pool in
    Silo.query db "select * from users"
end
