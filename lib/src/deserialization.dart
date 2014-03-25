/**
 * author: Daniel Robinson  http://github.com/0xor1
 */

part of Transmittable;

List<dynamic> _deserializedCollections = new List<dynamic>();
int _nestedFromTranStringCount = -1;


dynamic _getValueFromTranSection(String s){
  var idx1 = s.indexOf(TD);
  var idx2 = s.indexOf(TD, idx1 + 1);
  var key = s.substring(0, idx1);
  var tranCodec = _tranCodecsByKey[key];
  var type = tranCodec._type;
  var collectionPlaceholder = new Object();
  int collectionPlaceholderIdx;
  if(tranCodec._isTranSubtype || type == List || type == Set || type == Map){
    collectionPlaceholder = new Object();
    collectionPlaceholderIdx = _uniqueValues.length;
    _uniqueValues.add(collectionPlaceholder);
  }
  var v = tranCodec._decode(s.substring(idx2 + 1));
  if(v is _InternalPointer){ return v; }
  if(tranCodec._isTranSubtype || v is List || v is Set || v is Map){
    _deserializedCollections.add(v);
    _uniqueValues.insert(collectionPlaceholderIdx, v);
    _uniqueValues.remove(collectionPlaceholder);
  }else{
    _uniqueValues.add(v);
  }
  v = _valueProcessor(v);
  return v;
}

void _addNestedfromTranString(ValueProcessor postProcessor){
  _valueProcessors.add(postProcessor);
}

void _removeNestedfromTranString(){
  _valueProcessors.removeLast();
  if(_valueProcessors.isEmpty){
    _resolveInternalPointers();
    _deserializedCollections.clear();
    _uniqueValues.clear();
  }
}

void _resolveInternalPointers(){
  _deserializedCollections.forEach((col){
    if(col is Transmittable){
      _resolveInternalPointersInMap(col._internal);
    }else if(col is Map){
      _resolveInternalPointersInMap(col);
    }else if(col is List){
      for(var i = 0; i < col.length; i++){
        if(col[i] is _InternalPointer){
          col[i] = col[i].resolve();
        }
      }
    }else if(col is Set){
      var internalPointers = new List<_InternalPointer>();
      col.forEach((dynamic o){
        if(o is _InternalPointer){
          internalPointers.add(o);
        }
      });
      internalPointers.forEach((_InternalPointer ip){
        col.remove(ip);
        col.add(ip.resolve());
      });
    }
  });
}

void _resolveInternalPointersInMap(Map m){
  var keysToReplace = new Set<_InternalPointer>();
  var keysToReplaceValuesFor = new Set<dynamic>();
  m.forEach((k, v){
    if(k is _InternalPointer){
      keysToReplace.add(k);
    }
    if(v is _InternalPointer){
      keysToReplaceValuesFor.add(k);
    }
  });
  keysToReplaceValuesFor.forEach((k){
    m[k] = (m[k] as _InternalPointer).resolve();
  });
  keysToReplace.forEach((k){
    m[k.resolve()] = m.remove(k);
  });
}

dynamic _processStringBackToListOrSet(dynamic col, String s){
  if(!(col is Set) && !(col is List)){ throw 'Expecting either List or Set only'; }
  int start = 0;
  while(start < s.length){
    var dataLengthStartIdx = s.indexOf(TD, start) + 1;
    var dataLengthEndIdx = s.indexOf(TD, dataLengthStartIdx);
    var dataEndIdx = dataLengthEndIdx + int.parse(s.substring(dataLengthStartIdx, dataLengthEndIdx)) + 1;
    col.add(_getValueFromTranSection(s.substring(start, dataEndIdx)));
    start = dataEndIdx;
  }
  return col;
}

Map<dynamic, dynamic> _processStringBackToMap(String s){
  Map<dynamic, dynamic> map = new Map();
  int start = 0;
  while(start < s.length){
    var key;
    for(var i = 0; i < 2; i++){
      var dataLengthStartIdx = s.indexOf(TD, start) + 1;
      var dataLengthEndIdx = s.indexOf(TD, dataLengthStartIdx);
      var dataEndIdx = dataLengthEndIdx + int.parse(s.substring(dataLengthStartIdx, dataLengthEndIdx)) + 1;
      if(i == 0){
        key = _getValueFromTranSection(s.substring(start, dataEndIdx));
      }else{
        map[key] = _getValueFromTranSection(s.substring(start, dataEndIdx));
      }
      start = dataEndIdx;
    }
  }
  return map;
}

Transmittable _processStringBackToTran(Transmittable t, String s){
  return t.._internal = _processStringBackToMap(s);
}

RegExp _processStringBackToRegExp(String s){
  var start = s.indexOf(TD) + 1;
  var end = start + num.parse(s.substring(0, start - 1));
  var p = s.substring(start, end);
  var c = s.substring(end, end + 1) == 't';
  var m = s.substring(end + 1, end + 2) == 't';
  return new RegExp(p, caseSensitive: c, multiLine: m);
}