class Redis::Local < Redis::Common
  def initialize
    @redis = $REDIS_L
  end

  def ping(*args)
    return nil if @redis.nil?

    super
  end

  def set(*args)
    return nil if @redis.nil?

    super
  end

  def get(*args)
    return nil if @redis.nil?

    super
  end

  def del(*args)
    return nil if @redis.nil?

    super
  end

  def sort(*args)
    return nil if @redis.nil?

    super
  end

  def hmset(*args)
    return nil if @redis.nil?

    super
  end

  def hmget(*args)
    return nil if @redis.nil?

    super
  end

  def hgetall(*args)
    return nil if @redis.nil?

    super
  end

  def xadd(*args)
    return nil if @redis.nil?

    super
  end

  def xdel(*args)
    return nil if @redis.nil?

    super
  end

  def hincrby(*args)
    return nil if @redis.nil?

    super
  end

  def rpush(*args)
    return nil if @redis.nil?

    super
  end

  def lrange(*args)
    return nil if @redis.nil?

    super
  end

  def lrem(*args)
    return nil if @redis.nil?

    super
  end

  def zadd(*args)
    return nil if @redis.nil?

    super
  end

  def zrem(*args)
    return nil if @redis.nil?

    super
  end

  def expireat(*args)
    return nil if @redis.nil?

    super
  end
end
