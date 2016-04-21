use "net"
use "options"
use "collections"

actor Main
  let _env: Env
  var _is_worker: Bool = true

  new create(env: Env) =>
    _env = env
    var worker_count: USize = 0
    var node_id: I32 = 0
    var phone_home: String = ""
    var options = Options(env)

    options
      .add("leader", "l", None)
      .add("worker_count", "w", I64Argument)
      .add("phone_home", "p", StringArgument)
      .add("id", "i", I64Argument)

    for option in options do
      match option
      | ("leader", None) => _is_worker = false
      | ("worker_count", let arg: I64) => worker_count = arg.usize()
      | ("phone_home", let arg: String) => phone_home = arg
      | ("id", let arg: I64) => node_id = arg.i32()
      end
    end

    var args = options.remaining()

    try
      // Id must be specified and nonzero
      if node_id == 0 then error end

      let leader_addr: Array[String] = args(1).split(":")
      let leader_host = leader_addr(0)
      let leader_service = leader_addr(1)

      let auth = env.root as AmbientAuth
      if _is_worker then
        let notifier = recover WorkerNotifier(env,
                                              auth,
                                              node_id,
                                              leader_host,
                                              leader_service) end
        TCPListener(auth, consume notifier)
      else
        let notifier = recover LeaderNotifier(env,
                                              auth,
                                              node_id,
                                              leader_host,
                                              leader_service,
                                              worker_count,
                                              phone_home) end
        TCPListener(auth, consume notifier, leader_host, leader_service)
      end

      if _is_worker then
        _env.out.print("**Buffy Worker**")
      else
        _env.out.print("**Buffy Leader at " + leader_host + ":"
          + leader_service + "**")
        _env.out.print("** -- Looking for " + worker_count.string()
          + " workers --**")
      end
    else
      TestMain(env)
      _env.out.print("Parameters: leader_address [-l -w <worker_count>"
        + "-p <phone_home_address> --id <nonzero node_id>]")
    end
