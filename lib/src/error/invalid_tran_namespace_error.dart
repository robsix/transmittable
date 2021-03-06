/**
 * Author:  Daniel Robinson http://github.com/0xor1
 */

part of transmittable;

/// Thrown if a call to [generateRegistrar] is made with a namespace containing the : character.
class InvalidTranNamespaceError extends Error{
  String get message => 'Namespace "$shortNamespace" is invalid. Tran namespaces must not contain a "$_TSD" character.';
  final String shortNamespace;
  InvalidTranNamespaceError(this.shortNamespace);
}