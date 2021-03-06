/**
 * Author:  Daniel Robinson http://github.com/0xor1
 */

part of transmittable;

final Map<String, String> _namespaces = new Map<String, String>();
String _currentNamespace = null;
int _currentNamespaceKeyCount = 0;

/// Returns a [Registrar] function that will register the codecs in [registrations]
/// upon being called.
Registrar generateRegistrar(String fullNamespace, String shortNamespace, List<TranRegistration> registrations){
  _initTranRegistrations();
  if(shortNamespace.contains(_TSD)){
    throw new InvalidTranNamespaceError(shortNamespace);
  }
  if(_namespaces.keys.contains(shortNamespace)){
    throw new DuplicateTranNamespaceError(shortNamespace, fullNamespace);
  }
  _namespaces[shortNamespace] = fullNamespace;
  return (){
    _currentNamespace = shortNamespace;
    try{
      registrations.forEach((r) => _registerTranCodec(r.type, r.isTranSubtype, r.encode, r.decode));
      registrations.clear();
    }finally{
      _currentNamespace = null;
      _currentNamespaceKeyCount = 0;
    }
  };
}

void _registerTranCodec(Type type, bool isTranSubtype, TranEncode encode, TranDecode decode){
  if(_tranCodecsByType.containsKey(type)){
    throw new DuplicateTranTypeError(type);
  }
  String key = '$_currentNamespace${_GetNextKeyForCurrentNamespace()}';
  if(_tranCodecsByKey.containsKey(key)){
    //this should be impossible to hit, but leaving in in case of a bug in the algorithm as it could be tricky to debug otherwise
    throw new DuplicateTranKeyError(key);
  }
  _tranCodecsByKey[key] = _tranCodecsByType[type] = new _TranCodec(key, type, isTranSubtype, encode, decode);

}

String _GetNextKeyForCurrentNamespace(){
  StringBuffer keyBuff = new StringBuffer();
  int base = _KEY_PIECES.length;
  int tempCount = _currentNamespaceKeyCount;
  do{
    int division = tempCount ~/ base;
    int remainder = tempCount - (division * base);
    keyBuff.write(_KEY_PIECES[remainder]);
    if(division == 0){
      break;
    }
    tempCount = division;
  }while(true);
  _currentNamespaceKeyCount++;
  return keyBuff.toString();
}

/// A function which takes an object of type [T] and returns
/// a [String] representation of that object.
typedef String TranEncode<T>(T obj);


///  A function which takes a string representation of an
///  object of type [T] and returns an instance of that object.
typedef T TranDecode<T>(String str);

/// A function which returns a new empty Transmittable type.
typedef T TranConstructor<T extends Transmittable>();

/// An object containing all the required information to successfully register a
/// transmittable codec.
class TranRegistration{
  final Type type;
  final bool isTranSubtype;
  final TranEncode encode;
  final TranDecode decode;

  TranRegistration._internal(this.type, this.isTranSubtype, this.encode, this.decode);

  /// Creates a new TranRegistration for the [type] with the specified [encode] and [decode] functions.
  factory TranRegistration.codec(Type type, TranEncode encode, TranDecode decode){
    return new TranRegistration._internal(type, false, encode, decode);
  }

  /// Creates a new TranRegistration for the transmittable [subtype] with the specified [constructor] function.
  factory TranRegistration.subtype(Type subtype,  TranConstructor constructor){
    return new TranRegistration._internal(subtype, true, _processTranToString, (String s) => _processStringBackToTran(constructor(), s));
  }
}

// this bool variable is only needed in the Transmittable library because of the recursive call
// to _registerTranTranTypes inside generateRegistrar, no other libraries will need to use this wrapper
// function and bool variable pattern.
bool _tranTranTypesRegistered = false;
void _registerTranTranTypes(){
  if(_tranTranTypesRegistered) return;
  _tranTranTypesRegistered = true;
  generateRegistrar(
    'transmittable/transmittable',
    '',
    [
      new TranRegistration.codec(null, (o)=> '', (s) => null),
      new TranRegistration.codec(_InternalPointer, (_InternalPointer ip) => ip._uniqueValueIndex.toString(), (String s) => new _InternalPointer(int.parse(s))),
      new TranRegistration.codec(num, (num n) => n.toString(), (String s) => num.parse(s)),
      new TranRegistration.codec(int, (int i) => i.toString(), (String s) => int.parse(s)),
      new TranRegistration.codec(double, (double f) => f.toString(), (String s) => double.parse(s)),
      new TranRegistration.codec(String, (String s) => s, (String s) => s),
      new TranRegistration.codec(bool, (bool b) => b ? 't' : '', (String s) => s == 't' ? true : false),
      new TranRegistration.codec(List, _processIterableToString, (String s) => _processStringBackToListOrSet(new List(), s)),
      new TranRegistration.codec(Set, _processIterableToString, (String s) => _processStringBackToListOrSet(new Set(), s)),
      new TranRegistration.codec(Map, _processMapToString, _processStringBackToMap),
      new TranRegistration.codec(RegExp, _processRegExpToString, _processStringBackToRegExp),
      new TranRegistration.codec(Type, (Type t) => _processTypeToString(t),(String s) => _tranCodecsByKey[s]._type),
      new TranRegistration.codec(DateTime, (DateTime d) => d.toString(), (String s) => DateTime.parse(s)),
      new TranRegistration.codec(Duration, (Duration dur) => dur.inMilliseconds.toString(), (String s) => new Duration(milliseconds: num.parse(s))),
      new TranRegistration.codec(Symbol, (Symbol sy) => MirrorSystem.getName(sy), (String s) => MirrorSystem.getSymbol(s)),
      new TranRegistration.subtype(Transmittable, () => new Transmittable())
    ])();
}