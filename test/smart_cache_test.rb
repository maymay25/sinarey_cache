
$:.unshift File.expand_path("../lib", __dir__)

require 'sinarey_cache'
require 'minitest/autorun'

ObjectCache = Sinarey::SmartCache.new(100,100)

# MARK 实例方法 []= , store , [], fetch , getset , delete , count , clear

class SmartCacheTest < MiniTest::Unit::TestCase

  def setup
    @object = {id:1, msg:'this is the object for test', name:'object'}
    @object1 = {id:2, msg:'I need some more object for test', name:'object1'}
    @object2 = {id:3, msg:'hahahahaha', name:'object2'}
  end

  #基本测试 [] , []= , store , fetch, count , delete , clear
  def test_basic

    obj_id = @object[:id]

    #第一次不会缓存，只在FIFO队列里留下标记
    ObjectCache[obj_id] = @object
    assert_equal ObjectCache[obj_id], nil
    assert_equal ObjectCache.fetch(obj_id), nil
    assert_equal ObjectCache.count, 0

    #fetch方法，获取不到内容的时候会取后面block返回值
    #这个方法不会缓存block返回值，另一个getset方法会,并且遵循缓存规则。
    assert_equal ObjectCache.fetch(obj_id), nil
    assert_equal ObjectCache.fetch(obj_id){123}, 123
    assert_equal ObjectCache.count, 0

    #第二次会缓存，因为FIFO队列里已经有标记
    ObjectCache[obj_id] = @object
    assert_equal ObjectCache[obj_id], @object
    assert_equal ObjectCache.fetch(obj_id), @object
    assert_equal ObjectCache.count, 1

    #fetch方法，有缓存的情况下返回缓存内容
    assert_equal ObjectCache.fetch(obj_id), @object
    assert_equal ObjectCache.fetch(obj_id){123}, @object
    assert_equal ObjectCache.count, 1

    #delete方法 同时清除FIFO队列里的标记
    ObjectCache.delete(obj_id)
    assert_equal ObjectCache[obj_id], nil
    assert_equal ObjectCache.fetch(obj_id), nil

    #按照缓存规则 这一次缓存不会真正建立
    ObjectCache[obj_id] = @object
    assert_equal ObjectCache[obj_id], nil
    assert_equal ObjectCache.fetch(obj_id), nil

    #第二次缓存顺利建立
    ObjectCache[obj_id] = @object
    assert_equal ObjectCache[obj_id], @object
    assert_equal ObjectCache.fetch(obj_id), @object

    #store方法等价于[]=方法
    ObjectCache.store @object1[:id], @object1
    #按照规则，需要连写两遍，才能成功缓存
    ObjectCache.store @object1[:id], @object1

    #调用store方法,可以添加force选项，绕过规则，强制缓存
    ObjectCache.store @object2[:id], @object2, force:true

    #现在应该有3个缓存
    assert_equal ObjectCache.count, 3

    #测试clear方法,清空所有缓存和FIFO标记
    ObjectCache.clear
    assert_equal ObjectCache.count, 0    

  end

  #测试getset方法 这个方法类似于fetch方法，不同的是，会缓存block的返回值,遵循缓存规则
  def test_getset_method
    obj_id = @object[:id]

    assert_equal ObjectCache.count, 0

    ObjectCache.getset(obj_id){ @object }
    #按照规则这一次缓存也不会建立
    assert_equal ObjectCache[obj_id], nil

    ObjectCache.getset(obj_id){ @object }
    #这一次建立成功
    assert_equal ObjectCache[obj_id], @object

    #同样可以通过force绕过规则强制缓存
    ObjectCache.getset(@object1[:id],force:true){ @object1 }
    assert_equal ObjectCache[@object1[:id]], @object1

    ObjectCache.getset(@object2[:id],force:true){ @object2 }
    assert_equal ObjectCache[@object2[:id]], @object2


  end


  #同一个用户不可以创建缓存
  def test_uuid_options

  end

  #可以绕过规则强制建立缓存
  def test_force_options

  end

end


