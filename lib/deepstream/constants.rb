module Deepstream
  MESSAGE_SEPARATOR = 30.chr
  MESSAGE_PART_SEPARATOR = 31.chr

  module LOG_LEVEL
    DEBUG = 0
    INFO = 1
    WARN = 2
    ERROR = 3
    OFF = 100
  end

  module CONNECTION_STATE
    CLOSED = :closed
    AWAITING_CONNECTION = :awaiting_connection
    CHALLENGING = :challenging
    AWAITING_AUTHENTICATION = :awaiting_authentication
    AUTHENTICATING = :authenticating
    OPEN = :open
    ERROR = :error
    RECONNECTING = :reconnecting
  end

  module TOPIC
    CONNECTION = :C
    AUTH = :A
    ERROR = :X
    EVENT = :E
    RECORD = :R
    RPC = :P
  end

  module ACTION
    ACK = :A
    READ = :R
    REDIRECT = :RED
    CHALLENGE = :CH
    CHALLENGE_RESPONSE = :CHR
    CREATE = :C
    UPDATE = :U
    PATCH = :P
    DELETE = :D
    SUBSCRIBE = :S
    UNSUBSCRIBE = :US
    HAS = :H
    SNAPSHOT = :SN
    LISTEN = :L
    UNLISTEN = :UL
    LISTEN_ACCEPT = :LA
    LISTEN_REJET = :LR
    SUBSCRIPTION_HAS_PROVIDER = :SH
    SUBSCRIPTION_FOR_PATTERN_FOUND = :SP
    SUBSCRIPTION_FOR_PATTERN_REMOVED = :SR
    PROVIDER_UPDATE = :PU
    QUERY = :Q
    CREATEORREAD = :CR
    EVENT = :EVT
    ERROR = :E
    REQUEST = :REQ
    RESPONSE = :RES
    REJECTION = :REJ
    PING = :PI
    PONG = :PO
  end

  module TYPE
    STRING = :S
    OBJECT = :O
    NUMBER = :N
    NULL = :L
    TRUE = :T
    FALSE = :F
    UNDEFINED = :U
  end
end
