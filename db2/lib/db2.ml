

(* TODO: move all the Connection.t contents (driver,config) back out into Silo.t *)
(* this is the wrong abstraction because FakeDB can't reference itself *)
(* so FakeDB cannot create a connection that holds a reference to the FakeDB module *)

module rec DbCaml : sig
  module Connection : sig
    type 'config t = {
      driver : (module DbCaml.Driver.Intf with type config = 'config);
      config : 'config;
    }

    val make :
      driver:(module DbCaml.Driver.Intf with type config = 'config) ->
      config:'config ->
      'config t

    val execute : 'config t -> string -> bytes
  end

  module Driver : sig
    module type Intf = sig
      type config

      val connect : config -> config DbCaml.Connection.t
    end
  end
end = struct
  module Connection = struct
    type 'config t = {
      driver : (module DbCaml.Driver.Intf with type config = 'config);
      config : 'config;
    }

    let make ~driver ~config = { config; driver }
    let execute _t _query = Bytes.of_string "hello world"
  end

  module Driver = struct
    module type Intf = sig
      type config

      val connect : config -> config DbCaml.Connection.t
    end
  end
end

module FakeDB = struct
  type config = { port : int }

  let connect _config = DbCaml.Connection.make ()
end

module Silo = struct
  type 'config t = { connection : 'config DbCaml.Connection.t }

  let connect :
      type config.
      driver:(module DbCaml.Driver.Intf with type config = config) ->
      config:config ->
      config t =
   fun ~driver:(module D) ~config ->
    let connection = D.connect config in
    { connection }

  let query t query = DbCaml.Connection.execute t.connection query
end

module MyApp = struct
  let run () =
    let db = Silo.connect ~driver:(module FakeDB) ~config:{ port = 2112 } in
    Silo.query db "select * from users"
end
