/**
 * author: Daniel Robinson http://github.com/0xor1
 */

part of Transmittable;

class UnresolvableNestedReferenceLoopError{
  String get message => 'transmittable.toTranString() method called in an illegal nested location';
  final Transmittable transmittable;
  const UnresolvableNestedReferenceLoopError(Transmittable this.transmittable);
}