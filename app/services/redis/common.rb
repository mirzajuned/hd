class Redis::Common
  def initialize
    raise NoMethodError, 'Use Redis::LocalHelper or Redis::MasterHelper'
  end

  def ping(*args)
    @redis.ping(*args)
  rescue StandardError => e
    e.message
  end

  def set(*args)
    @redis.set(*args)
  rescue StandardError => e
    e.message
  end

  def get(*args)
    @redis.get(*args)
  rescue StandardError => e
    e.message
  end

  def del(*args)
    @redis.del(*args)
  rescue StandardError => e
    e.message
  end

  def sort(*args)
    @redis.sort(*args)
  rescue StandardError => e
    e.message
  end

  def hmset(*args)
    @redis.hmset(*args)
  rescue StandardError => e
    e.message
  end

  def hmget(*args)
    @redis.hmget(*args)
  rescue StandardError => e
    e.message
  end

  def hgetall(*args)
    @redis.hgetall(*args)
  rescue StandardError => e
    e.message
  end

  def xadd(*args)
    @redis.xadd(*args)
  rescue StandardError => e
    e.message
  end

  def xdel(*args)
    @redis.xdel(*args)
  rescue StandardError => e
    e.message
  end

  def hincrby(*args)
    @redis.hincrby(*args)
  rescue StandardError => e
    e.message
  end

  def rpush(*args)
    @redis.rpush(*args)
  rescue StandardError => e
    e.message
  end

  def lrange(*args)
    @redis.lrange(*args)
  rescue StandardError => e
    e.message
  end

  def lrem(*args)
    @redis.lrem(*args)
  rescue StandardError => e
    e.message
  end

  def zadd(*args)
    @redis.zadd(*args)
  rescue StandardError => e
    e.message
  end

  def zrem(*args)
    @redis.zrem(*args)
  rescue StandardError => e
    e.message
  end

  def expireat(*args)
    @redis.expireat(*args)
  rescue StandardError => e
    e.message
  end
end
