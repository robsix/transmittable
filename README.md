#Transmittable [![Build Status](https://drone.io/github.com/0xor1/transmittable/status.png)](https://drone.io/github.com/0xor1/transmittable/latest)

An attempt to make a simple way of transferring **named** and **typed** properties across Http
connections using shallow transmittable objects.

##How To Use:

Extend off of **Transmittable** to make an object transmittable accross a http 
connection, then explicitly implement an interface for this object, but do not 
implement any of the interfaces getters/setters which you would like to transmit.
It is a requirement that classes extending off **Transmittable** implement a 
default constructor, meaning one which takes no arguments.

```
class Cat extends Transmittable implements ICat{}
abstract class ICat{
  String name;
  int age;
}

void main(){
  Cat c1 = new Cat()
  ..name = 'felix'
  ..age = 3;
  var tranStr = c1.toTranString(); // turn this cat into a transmittable string
  
  // send down http connection and then deserialise back into the cat object
  
  Cat c2 = new Transmittable.fromTranString(tranStr);
  print(c2 is Cat) // true
  print(c2.name); // felix
  print(c2.age); // 3
}
```

##Registered Types

Transmittable can handle, int, bool, string, datetime, duration, regexp, list,
set and map out of the box without any need for further effort on the users part.

If you would like to add additional types to be transmittable simply register them
using the top level function:

```
registerTranCodec(String key, Type type, TranEncode encode, TranDecode decode)
//where
typedef String TranEncode<T>(T obj);
typedef T TranDecode<T>(String str);
```
Remember this method call must be made on both the client side and the server
side with the same arguments. This is usually bes achieved by both server and
client side libraries referencing a common interface library which contains a
method wrapping all your required calls to **registerTranCodec**.

Additionally for **Transmittable** to be able to recreate an actual instance of
your extended type you must register that type too with **registerTranCodec**
but you can pass in null for both function arguments.

##Issues to be aware of

If there are any circular references, for example:

```
var tran = Transmittable();
tran.tran = tran; // tran has a property which points back at itself!
tran.toTranString(); // will throw a stackoverflow error
```

Transmittable currently has no way of detecting if an object has previously been
serialized, so it will attempt to serialize it again, which
means there is the potential for infinte loops when a Transmittable attempts to
serialize objects which form a reference loop. **Transmittable** is best used 
for simple objects for the time being to prevent this issue occuring, however
handling of circular references is intended to be implemented in the next version. 